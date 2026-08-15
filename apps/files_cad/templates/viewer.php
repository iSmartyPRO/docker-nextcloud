<?php
/** @var array $_ */
$filename = $_['filename'] ?? 'DWG';
$svgUrl = $_['svgUrl'] ?? '';
$downloadUrl = $_['downloadUrl'] ?? '';
$error = $_['error'] ?? '';
$converter = !empty($_['converter']);
?>
<div class="cad-app">
	<header class="cad-toolbar">
		<div class="cad-toolbar__title"><?php p($filename); ?></div>
		<span id="cad-zoom-label">100%</span>
		<button type="button" data-cad-action="zoom-out" title="-">−</button>
		<button type="button" data-cad-action="zoom-in" title="+">+</button>
		<button type="button" data-cad-action="fit"><?php p($_['labelFit'] ?? 'Fit'); ?></button>
		<button type="button" data-cad-action="print"><?php p($_['labelPrint'] ?? 'Print'); ?></button>
		<?php if ($downloadUrl !== ''): ?>
			<a href="<?php p($downloadUrl); ?>"><?php p($_['labelDownload'] ?? 'Download'); ?></a>
		<?php endif; ?>
	</header>
	<?php if ($error !== ''): ?>
		<div class="cad-note"><?php p($error); ?></div>
	<?php elseif (!$converter): ?>
		<div class="cad-note"><?php p($_['labelNoConverter'] ?? ''); ?></div>
	<?php else: ?>
		<div id="cad-stage" class="cad-stage">
			<object id="cad-svg" class="cad-svg" type="image/svg+xml" data="<?php p($svgUrl); ?>"><?php p($_['labelLoading'] ?? ''); ?></object>
		</div>
	<?php endif; ?>
</div>
