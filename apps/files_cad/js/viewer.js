(function () {
	'use strict'

	var MIMES = [
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
	]

	function viewerUrl(props) {
		var params = new URLSearchParams()
		var fileId = props.fileid || props.fileId || props.id
		var path = props.path || props.filename || props.davPath || ''
		if (fileId) {
			params.set('fileid', String(fileId))
		}
		if (path) {
			params.set('file', String(path))
		}
		return OC.generateUrl('/apps/files_cad/view') + '?' + params.toString()
	}

	function openDrawing(props) {
		window.location.href = viewerUrl(props)
	}

	var CadViewerComponent = {
		name: 'FilesCadViewer',
		props: {
			filename: { type: String, default: '' },
			path: { type: String, default: '' },
			davPath: { type: String, default: '' },
			source: { type: String, default: '' },
			mime: { type: String, default: '' },
			fileid: { type: [Number, String], default: 0 },
			fileId: { type: [Number, String], default: 0 },
		},
		computed: {
			src: function () {
				return viewerUrl(this)
			},
		},
		mounted: function () {
			window.location.href = viewerUrl(this)
		},
		render: function (h) {
			var src = this.src
			var create = typeof h === 'function'
				? h
				: (window.Vue && typeof window.Vue.h === 'function' ? window.Vue.h : null)
			if (!create) {
				return null
			}
			return create('iframe', {
				class: 'files-cad__frame',
				attrs: {
					src: src,
					allowfullscreen: true,
					title: 'CAD',
				},
				src: src,
				allowfullscreen: true,
				title: 'CAD',
			})
		},
	}

	function registerViewer() {
		if (!window.OCA || !window.OCA.Viewer || typeof window.OCA.Viewer.registerHandler !== 'function') {
			return false
		}
		if (window.OCA.Viewer._filesCadRegistered) {
			return true
		}
		window.OCA.Viewer.registerHandler({
			id: 'files_cad',
			group: 'cad',
			mimes: MIMES,
			component: CadViewerComponent,
		})
		window.OCA.Viewer._filesCadRegistered = true
		return true
	}

	function registerLegacyActions() {
		if (!window.OCA || !window.OCA.Files || !window.OCA.Files.fileActions) {
			return
		}
		MIMES.forEach(function (mime) {
			window.OCA.Files.fileActions.registerAction({
				name: 'files_cad',
				displayName: 'Просмотр чертежа',
				mime: mime,
				permissions: window.OC && window.OC.PERMISSION_READ,
				iconClass: 'icon-toggle',
				actionHandler: function (filename, context) {
					var dir = context.dir || context.fileList.getCurrentDirectory()
					var file = context.fileInfoModel || context.fileList.getModelForFile(filename)
					openDrawing({
						fileid: file && (file.get && file.get('id') || file.id),
						path: (dir === '/' ? '' : dir) + '/' + filename,
						filename: filename,
					})
				},
			})
			window.OCA.Files.fileActions.setDefault(mime, 'files_cad')
		})
	}

	registerViewer()
	registerLegacyActions()
	var tries = 0
	var timer = setInterval(function () {
		tries += 1
		registerViewer()
		registerLegacyActions()
		if (tries > 40) {
			clearInterval(timer)
		}
	}, 250)
})()
