<?php

declare(strict_types=1);

return [
	'routes' => [
		['name' => 'view#index', 'url' => '/view', 'verb' => 'GET'],
		['name' => 'view#svg', 'url' => '/svg', 'verb' => 'GET'],
		['name' => 'view#download', 'url' => '/download', 'verb' => 'GET'],
	],
];
