<?php

declare(strict_types=1);

namespace OCA\FilesCad\Command;

use OC\Core\Command\Base;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class ConfigureFileViewer extends Base {
	protected function configure(): void {
		$this->setName('files_cad:configure-fileviewer')
			->setDescription('Limit Universal File Viewer to CAD/BIM drawings so Collabora keeps office files');
	}

	protected function execute(InputInterface $input, OutputInterface $output): int {
		$class = 'OCA\\FileViewer\\Service\\FormatSettings';
		if (!class_exists($class)) {
			$output->writeln('<comment>fileviewer is not installed; skip CAD-only filter.</comment>');
			return 0;
		}

		$settings = \OCP\Server::get($class);
		$current = $settings->getSettings();
		$keep = [
			'format:dwg' => true,
			'format:dxf' => true,
			'format:dwf' => true,
			'format:dwfx' => true,
			'format:ifc' => true,
		];

		$disabled = [];
		foreach ($current['formatGroups'] as $group) {
			$category = $group['category'] ?? '';
			foreach ($group['formatIds'] as $formatId) {
				if (isset($keep[$formatId]) || $category === 'cad') {
					continue;
				}
				$disabled[] = $formatId;
			}
		}

		$settings->saveSettings(['disabledFormatIds' => array_values(array_unique($disabled))]);
		$output->writeln('fileviewer will open DWG, DXF, DWF, DWFX and IFC. Office files stay with Collabora.');
		return 0;
	}
}
