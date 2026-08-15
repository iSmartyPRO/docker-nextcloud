<?php

declare(strict_types=1);

namespace OCA\FilesCad\Service;

use OCP\Files\File;
use OCP\ITempManager;
use Psr\Log\LoggerInterface;

class ConversionService {
	public const PREVIEW_MAX_BYTES = 16 * 1024 * 1024;
	public const VIEW_MAX_BYTES = 64 * 1024 * 1024;

	public function __construct(
		private ITempManager $tempManager,
		private LoggerInterface $logger,
	) {
	}

	public function isAvailable(): bool {
		return $this->findBinary(['dwg2SVG', 'dwg2svg']) !== null;
	}

	public function converterName(): ?string {
		return $this->findBinary(['dwg2SVG', 'dwg2svg']);
	}

	public function toSvg(File $file, int $maxBytes = self::VIEW_MAX_BYTES): string {
		$size = $file->getSize();
		if ($size <= 0 || $size > $maxBytes) {
			throw new \RuntimeException('Drawing is empty or larger than the conversion limit.');
		}

		$cache = $this->cachePath($file, 'svg');
		if (is_file($cache) && filesize($cache) > 0) {
			$cached = file_get_contents($cache);
			if ($cached !== false) {
				return $cached;
			}
		}

		$workDir = $this->tempManager->getTemporaryFolder('files_cad_');
		$ext = strtolower($file->getExtension());
		$source = $workDir . 'source.' . ($ext !== '' ? $ext : 'dwg');
		file_put_contents($source, $file->getContent());

		$dwg = $source;
		if ($ext === 'dxf') {
			$dxf2dwg = $this->findBinary(['dxf2dwg']);
			if ($dxf2dwg === null) {
				throw new \RuntimeException('dxf2dwg is not installed.');
			}
			$dwg = $workDir . 'source.dwg';
			try {
				$this->run([$dxf2dwg, '-o', $dwg, $source], 45);
			} catch (\RuntimeException $e) {
				$this->run([$dxf2dwg, $source, $dwg], 45);
			}
			if (!is_file($dwg)) {
				throw new \RuntimeException('DXF could not be converted to DWG.');
			}
		}

		$dwg2svg = $this->findBinary(['dwg2SVG', 'dwg2svg']);
		if ($dwg2svg === null) {
			throw new \RuntimeException('dwg2SVG is not installed. Rebuild the Nextcloud image.');
		}

		try {
			$svg = $this->run([$dwg2svg, '--mspace', $dwg], 45);
		} catch (\RuntimeException $e) {
			$svg = $this->run([$dwg2svg, $dwg], 45);
		}
		$svg = $this->sanitizeSvg($svg);
		if (!str_contains($svg, '<svg')) {
			throw new \RuntimeException('LibreDWG did not produce an SVG for this drawing.');
		}

		@file_put_contents($cache, $svg);
		return $svg;
	}

	public function toPng(File $file, int $maxX, int $maxY): string {
		$svg = $this->toSvg($file, self::PREVIEW_MAX_BYTES);
		$rsvg = $this->findBinary(['rsvg-convert']);
		if ($rsvg === null) {
			throw new \RuntimeException('rsvg-convert is not installed.');
		}

		$workDir = $this->tempManager->getTemporaryFolder('files_cad_png_');
		$svgFile = $workDir . 'drawing.svg';
		$pngFile = $workDir . 'drawing.png';
		file_put_contents($svgFile, $svg);

		$width = max(32, min(4096, $maxX));
		$height = max(32, min(4096, $maxY));
		$this->run([
			$rsvg,
			'-w', (string)$width,
			'-h', (string)$height,
			'--keep-aspect-ratio',
			'-f', 'png',
			'-o', $pngFile,
			$svgFile,
		], 20);

		$png = file_get_contents($pngFile);
		if ($png === false || $png === '') {
			throw new \RuntimeException('PNG preview is empty.');
		}
		return $png;
	}

	private function cachePath(File $file, string $suffix): string {
		$key = implode('_', [
			'files_cad',
			(string)$file->getId(),
			(string)$file->getMTime(),
			(string)$file->getSize(),
			$suffix,
		]);
		return rtrim($this->tempManager->getTempBaseDir(), '/') . '/' . $key;
	}

	private function sanitizeSvg(string $svg): string {
		$svg = preg_replace('#<script\b[^>]*>.*?</script>#is', '', $svg) ?? $svg;
		$svg = preg_replace('#\son[a-z]+\s*=#i', ' data-removed=', $svg) ?? $svg;
		$svg = preg_replace('#javascript\s*:#i', '', $svg) ?? $svg;
		return $svg;
	}

	/**
	 * @param list<string> $command
	 */
	private function run(array $command, int $timeout): string {
		$descriptors = [
			0 => ['pipe', 'r'],
			1 => ['pipe', 'w'],
			2 => ['pipe', 'w'],
		];
		$process = proc_open($command, $descriptors, $pipes, null, null);
		if (!is_resource($process)) {
			throw new \RuntimeException('Could not start CAD converter.');
		}

		fclose($pipes[0]);
		stream_set_blocking($pipes[1], false);
		stream_set_blocking($pipes[2], false);

		$stdout = '';
		$stderr = '';
		$deadline = time() + $timeout;
		while (true) {
			$status = proc_get_status($process);
			$stdout .= (string)stream_get_contents($pipes[1]);
			$stderr .= (string)stream_get_contents($pipes[2]);
			if (!$status['running']) {
				break;
			}
			if (time() > $deadline) {
				proc_terminate($process, 9);
				fclose($pipes[1]);
				fclose($pipes[2]);
				proc_close($process);
				throw new \RuntimeException('CAD conversion timed out.');
			}
			usleep(50000);
		}

		fclose($pipes[1]);
		fclose($pipes[2]);
		$code = proc_close($process);
		if ($code !== 0 && $stdout === '') {
			$this->logger->warning('CAD converter failed', [
				'app' => 'files_cad',
				'cmd' => $command[0],
				'code' => $code,
				'stderr' => mb_substr($stderr, 0, 500),
			]);
			throw new \RuntimeException(trim($stderr) !== '' ? trim($stderr) : 'CAD converter failed.');
		}
		return $stdout;
	}

	/**
	 * @param list<string> $names
	 */
	private function findBinary(array $names): ?string {
		foreach ($names as $name) {
			$path = trim((string)shell_exec('command -v ' . escapeshellarg($name) . ' 2>/dev/null'));
			if ($path !== '') {
				return $path;
			}
		}
		return null;
	}
}
