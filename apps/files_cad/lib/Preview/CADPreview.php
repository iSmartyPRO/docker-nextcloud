<?php

declare(strict_types=1);

namespace OCA\FilesCad\Preview;

use OCA\FilesCad\Service\ConversionService;
use OCP\Files\File;
use OCP\Files\FileInfo;
use OCP\IImage;
use OCP\Preview\IProviderV2;
use Psr\Log\LoggerInterface;

class CADPreview implements IProviderV2 {
	public const MIME_REGEX = '/^(image\/vnd\.(dwg|dxf)|application\/(acad|x-acad|autocad_dwg|dwg|x-dwg|x-autocad|dxf|x-dxf)|image\/x-(dwg|dxf))$/';

	private function converter(): ConversionService {
		return \OCP\Server::get(ConversionService::class);
	}

	private function logger(): LoggerInterface {
		return \OCP\Server::get(LoggerInterface::class);
	}

	public function getMimeType(): string {
		return self::MIME_REGEX;
	}

	public function isAvailable(FileInfo $file): bool {
		try {
			if (!$this->converter()->isAvailable()) {
				return false;
			}
		} catch (\Throwable $e) {
			return false;
		}
		$ext = strtolower($file->getExtension());
		if (!in_array($ext, ['dwg', 'dxf'], true)) {
			return false;
		}
		$size = $file->getSize();
		return $size > 0 && $size <= ConversionService::PREVIEW_MAX_BYTES;
	}

	public function getThumbnail(File $file, int $maxX, int $maxY): ?IImage {
		if (!$this->isAvailable($file)) {
			return null;
		}
		try {
			$png = $this->converter()->toPng($file, $maxX, $maxY);
			$image = class_exists(\OCP\Image::class) ? new \OCP\Image() : new \OC_Image();
			if ($image->loadFromData($png) && $image->valid()) {
				return $image;
			}
		} catch (\Throwable $e) {
			$this->logger()->info('CAD preview failed: ' . $e->getMessage(), [
				'app' => 'files_cad',
				'fileId' => $file->getId(),
			]);
		}
		return null;
	}
}
