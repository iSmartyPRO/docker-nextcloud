<?php

declare(strict_types=1);

namespace OCA\FilesCad\Controller;

use OCA\FilesCad\AppInfo\Application;
use OCA\FilesCad\Service\ConversionService;
use OCA\FilesCad\Service\FileResolver;
use OCP\AppFramework\Controller;
use OCP\AppFramework\Http;
use OCP\AppFramework\Http\Attribute\NoAdminRequired;
use OCP\AppFramework\Http\Attribute\NoCSRFRequired;
use OCP\AppFramework\Http\DataDownloadResponse;
use OCP\AppFramework\Http\TemplateResponse;
use OCP\AppFramework\Http\ContentSecurityPolicy;
use OCP\Files\NotFoundException;
use OCP\IL10N;
use OCP\IRequest;
use OCP\IURLGenerator;
use OCP\Util;

class ViewController extends Controller {
	public function __construct(
		IRequest $request,
		private FileResolver $files,
		private ConversionService $converter,
		private IURLGenerator $urlGenerator,
		private IL10N $l10n,
	) {
		parent::__construct(Application::APP_ID, $request);
	}

	#[NoAdminRequired]
	#[NoCSRFRequired]
	public function index(): TemplateResponse {
		Util::addStyle(Application::APP_ID, 'page');
		Util::addScript(Application::APP_ID, 'page');

		$fileId = $this->intParam('fileid', 'id');
		$path = $this->stringParam('file', 'path');

		$params = [
			'fileid' => $fileId,
			'path' => $path,
			'svgUrl' => $this->urlGenerator->linkToRoute('files_cad.view.svg', [
				'fileid' => $fileId,
				'file' => $path,
			]),
			'downloadUrl' => '',
			'filename' => $this->l10n->t('Drawing'),
			'error' => '',
			'converter' => $this->converter->isAvailable(),
			'labelFit' => $this->l10n->t('Fit'),
			'labelPrint' => $this->l10n->t('Print'),
			'labelDownload' => $this->l10n->t('Download DWG'),
			'labelLoading' => $this->l10n->t('Loading drawing…'),
			'labelNoConverter' => $this->l10n->t('The drawing converter is not in the Nextcloud image. Rebuild the image and open the file again, or download it for AutoCAD / nanoCAD.'),
		];

		try {
			$file = $this->files->getFile($fileId, $path);
			$params['filename'] = $file->getName();
			$params['downloadUrl'] = $this->urlGenerator->linkToRoute('files_cad.view.download', [
				'fileid' => $file->getId(),
			]);
		} catch (NotFoundException $e) {
			$params['error'] = $this->l10n->t('Drawing not found or access denied.');
		}

		$response = new TemplateResponse(Application::APP_ID, 'viewer', $params, 'blank');
		$csp = new ContentSecurityPolicy();
		$csp->addAllowedFrameAncestorDomain("'self'");
		$response->setContentSecurityPolicy($csp);
		return $response;
	}

	#[NoAdminRequired]
	#[NoCSRFRequired]
	public function download(): DataDownloadResponse {
		$fileId = $this->intParam('fileid', 'id');
		$path = $this->stringParam('file', 'path');
		$file = $this->files->getFile($fileId, $path);
		return new DataDownloadResponse($file->getContent(), $file->getName(), $file->getMimeType());
	}

	#[NoAdminRequired]
	#[NoCSRFRequired]
	public function svg(): DataDownloadResponse {
		$fileId = $this->intParam('fileid', 'id');
		$path = $this->stringParam('file', 'path');

		try {
			$file = $this->files->getFile($fileId, $path);
			$svg = $this->converter->toSvg($file);
			$response = new DataDownloadResponse($svg, $file->getName() . '.svg', 'image/svg+xml');
			$response->setStatus(Http::STATUS_OK);
			return $response;
		} catch (NotFoundException $e) {
			return new DataDownloadResponse(
				$this->errorSvg($this->l10n->t('Drawing not found or access denied.')),
				'error.svg',
				'image/svg+xml'
			);
		} catch (\Throwable $e) {
			return new DataDownloadResponse(
				$this->errorSvg($this->l10n->t('Could not render this drawing. Download it and open in a CAD program.')),
				'error.svg',
				'image/svg+xml'
			);
		}
	}

	private function intParam(string ...$names): ?int {
		foreach ($names as $name) {
			$value = $this->request->getParam($name);
			if ($value !== null && $value !== '' && is_numeric($value)) {
				return (int)$value;
			}
		}
		return null;
	}

	private function stringParam(string ...$names): ?string {
		foreach ($names as $name) {
			$value = $this->request->getParam($name);
			if (is_string($value) && $value !== '') {
				return $value;
			}
		}
		return null;
	}

	private function errorSvg(string $message): string {
		$text = htmlspecialchars($message, ENT_QUOTES | ENT_XML1);
		return <<<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="800" height="200" viewBox="0 0 800 200">
  <rect width="100%" height="100%" fill="#1e1e1e"/>
  <text x="400" y="100" fill="#e6e6e6" font-size="18" text-anchor="middle" font-family="sans-serif">{$text}</text>
</svg>
SVG;
	}
}
