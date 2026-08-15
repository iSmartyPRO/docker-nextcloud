<?php

declare(strict_types=1);

namespace OCA\FilesCad\AppInfo;

use OCA\Files\Event\LoadAdditionalScriptsEvent;
use OCA\FilesCad\Listener\LoadFilesScriptsListener;
use OCA\FilesCad\Preview\CADPreview;
use OCA\Viewer\Event\LoadViewer;
use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;

class Application extends App implements IBootstrap {
	public const APP_ID = 'files_cad';

	public const MIMES = [
		'image/vnd.dwg',
		'image/vnd.dxf',
		'application/acad',
		'application/x-acad',
		'application/autocad_dwg',
		'application/dwg',
		'application/x-dwg',
		'application/x-autocad',
		'application/dxf',
		'application/x-dxf',
		'image/x-dwg',
		'image/x-dxf',
		'model/vnd.dwf',
		'model/vnd.dwfx+xps',
	];

	public function __construct() {
		parent::__construct(self::APP_ID);
	}

	public function register(IRegistrationContext $context): void {
		$context->registerPreviewProvider(CADPreview::class, CADPreview::MIME_REGEX);
		if (class_exists(LoadAdditionalScriptsEvent::class)) {
			$context->registerEventListener(LoadAdditionalScriptsEvent::class, LoadFilesScriptsListener::class);
		}
		if (class_exists(LoadViewer::class)) {
			$context->registerEventListener(LoadViewer::class, LoadFilesScriptsListener::class);
		}
	}

	public function boot(IBootContext $context): void {
		\OCP\Util::addInitScript(self::APP_ID, 'viewer');
		\OCP\Util::addStyle(self::APP_ID, 'viewer');
	}
}
