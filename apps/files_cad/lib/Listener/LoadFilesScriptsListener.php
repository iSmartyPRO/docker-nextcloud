<?php

declare(strict_types=1);

namespace OCA\FilesCad\Listener;

use OCA\Files\Event\LoadAdditionalScriptsEvent;
use OCA\Viewer\Event\LoadViewer;
use OCP\EventDispatcher\Event;
use OCP\EventDispatcher\IEventListener;
use OCP\Util;

class LoadFilesScriptsListener implements IEventListener {
	public function handle(Event $event): void {
		$isFiles = class_exists(LoadAdditionalScriptsEvent::class)
			&& $event instanceof LoadAdditionalScriptsEvent;
		$isViewer = class_exists(LoadViewer::class)
			&& $event instanceof LoadViewer;
		if (!$isFiles && !$isViewer) {
			return;
		}
		Util::addInitScript('files_cad', 'viewer');
		Util::addStyle('files_cad', 'viewer');
	}
}
