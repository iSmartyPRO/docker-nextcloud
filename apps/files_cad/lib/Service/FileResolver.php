<?php

declare(strict_types=1);

namespace OCA\FilesCad\Service;

use OCP\Files\File;
use OCP\Files\IRootFolder;
use OCP\Files\NotFoundException;
use OCP\IUserSession;

class FileResolver {
	public function __construct(
		private IRootFolder $rootFolder,
		private IUserSession $userSession,
	) {
	}

	public function getFile(?int $fileId, ?string $path): File {
		$user = $this->userSession->getUser();
		if ($user === null) {
			throw new NotFoundException('Not logged in');
		}

		$folder = $this->rootFolder->getUserFolder($user->getUID());
		if ($fileId !== null && $fileId > 0) {
			$nodes = $folder->getById($fileId);
			foreach ($nodes as $node) {
				if ($node instanceof File) {
					return $node;
				}
			}
		}

		if ($path !== null && $path !== '') {
			$node = $folder->get(ltrim($path, '/'));
			if ($node instanceof File) {
				return $node;
			}
		}

		throw new NotFoundException('Drawing not found');
	}
}
