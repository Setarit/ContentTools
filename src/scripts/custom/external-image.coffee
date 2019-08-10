#DIALOGS
class ExternalImageLinkDialog extends ContentTools.DialogUI
    constructor: () ->
        super('Insert external image')

    mount: () ->
        super()

        #update dialog class
        ContentEdit.addCSSClass(@_domElement, 'ct-external-image-dialog')

        # update view class
        ContentEdit.addCSSClass(@_domView, 'ct-external-image-dialog-preview')

        # add controls
        domControlGroup = @constructor.createDiv(['ct-control-group'])
        @_domControls.appendChild(domControlGroup)

        # input
        @_domInput = document.createElement('input')
        @_domInput.setAttribute('class', 'ct-external-image-dialog__input')
        @_domInput.setAttribute('name', 'url')
        @_domInput.setAttribute(
            'placeholder',
            ContentEdit._('Paste the link to the image') + '...'
            )
        @_domInput.setAttribute('type', 'text')
        domControlGroup.appendChild(@_domInput)

        # Insert button
        @_domButton = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--insert'
            'ct-control--muted'
            ])
        @_domButton.textContent = ContentEdit._('Insert')
        domControlGroup.appendChild(@_domButton)



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
        #If supported allow store the state for restoring once the dialog is
        # cancelled.
        if element.storeState
            element.storeState()

        app = ContentTools.EditorApp.get()
        modal = new ContentTools.ModalUI()
        dialog = new ExternalImageLinkDialog()

        #support cancelling
        dialog.addEventListener 'cancel', () =>
            modal.hide()
            dialog.hide()
            callback(false)

        #support saving
        dialog.addEventListener 'save', (ev) =>
            console.log(ev);
            modal.hide()
            dialog.hide()
            callback(true)

        app.attach(modal)
        app.attach(dialog)
        modal.show()
        dialog.show()


