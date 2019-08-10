#DIALOGS
class ExternalImageLinkDialog extends ContentTools.DialogUI
	constructor: () ->
		super('Insert external image')


#TOOLS
class ExternalImageTool extends ContentTools.Tool

	ContentTools.ToolShelf.stow(@, 'external-image')

	@label = 'External Image'
	@icon = 'image'
	
	@canApply: (element, selection) ->
        # Return true if the tool can be applied to the current
        # element/selection.
        if element.isFixed()
            unless element.type() is 'ImageFixture'
                return false
        return true

    @apply: (element, selection, callback) ->
    	app = ContentTools.EditorApp.get()
    	modal = new ContentTools.ModalUI()
    	dialog = new ExternalImageLinkDialog()

    	app.attach(modal)
    	app.attach(dialog)
    	modal.show()
    	dialog.show()
