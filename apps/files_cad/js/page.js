(function () {
	'use strict'

	var stage = document.getElementById('cad-stage')
	var frame = document.getElementById('cad-svg')
	var zoomLabel = document.getElementById('cad-zoom-label')
	if (!stage || !frame) {
		return
	}

	var scale = 1
	var minScale = 0.1
	var maxScale = 20
	var originX = 0
	var originY = 0
	var dragging = false
	var lastX = 0
	var lastY = 0

	function apply() {
		frame.style.transform = 'translate(' + originX + 'px,' + originY + 'px) scale(' + scale + ')'
		if (zoomLabel) {
			zoomLabel.textContent = Math.round(scale * 100) + '%'
		}
	}

	function fit() {
		scale = 1
		originX = 0
		originY = 0
		apply()
	}

	function zoomBy(factor, cx, cy) {
		var next = Math.min(maxScale, Math.max(minScale, scale * factor))
		if (typeof cx === 'number' && typeof cy === 'number') {
			var rect = stage.getBoundingClientRect()
			var x = cx - rect.left
			var y = cy - rect.top
			originX = x - ((x - originX) * next) / scale
			originY = y - ((y - originY) * next) / scale
		}
		scale = next
		apply()
	}

	stage.addEventListener('wheel', function (event) {
		event.preventDefault()
		zoomBy(event.deltaY < 0 ? 1.15 : 1 / 1.15, event.clientX, event.clientY)
	}, { passive: false })

	stage.addEventListener('pointerdown', function (event) {
		if (event.button !== 0) {
			return
		}
		dragging = true
		lastX = event.clientX
		lastY = event.clientY
		stage.classList.add('is-panning')
		stage.setPointerCapture(event.pointerId)
	})

	stage.addEventListener('pointermove', function (event) {
		if (!dragging) {
			return
		}
		originX += event.clientX - lastX
		originY += event.clientY - lastY
		lastX = event.clientX
		lastY = event.clientY
		apply()
	})

	function stopPan(event) {
		dragging = false
		stage.classList.remove('is-panning')
		if (event && stage.hasPointerCapture(event.pointerId)) {
			stage.releasePointerCapture(event.pointerId)
		}
	}

	stage.addEventListener('pointerup', stopPan)
	stage.addEventListener('pointercancel', stopPan)

	document.querySelectorAll('[data-cad-action]').forEach(function (button) {
		button.addEventListener('click', function () {
			var action = button.getAttribute('data-cad-action')
			if (action === 'zoom-in') {
				zoomBy(1.25)
			} else if (action === 'zoom-out') {
				zoomBy(1 / 1.25)
			} else if (action === 'fit') {
				fit()
			} else if (action === 'print') {
				window.print()
			}
		})
	})

	document.addEventListener('keydown', function (event) {
		if (event.key === '+' || event.key === '=') {
			zoomBy(1.15)
		} else if (event.key === '-') {
			zoomBy(1 / 1.15)
		} else if (event.key === '0') {
			fit()
		}
	})

	apply()
})()
