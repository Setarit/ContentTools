# EXTERNAL IMAGE
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
        @_domInput.setAttribute('class', 'ct-external-image-dialog-url-input')
        @_domInput.setAttribute('name', 'url')
        @_domInput.setAttribute(
            'placeholder',
            ContentEdit._('Paste the link to the image') + '...'
            )
        @_domInput.setAttribute('type', 'text')
        domControlGroup.appendChild(@_domInput)

        # description input
        @_domDescriptionInput = document.createElement('input')
        @_domDescriptionInput.setAttribute('class', 'ct-external-image-dialog-description-input')
        @_domDescriptionInput.setAttribute('name', 'description')
        @_domDescriptionInput.setAttribute(
            'placeholder',
            ContentEdit._('Describe the image') + '...'
            )
        @_domDescriptionInput.setAttribute('type', 'text')
        domControlGroup.appendChild(@_domDescriptionInput)

        # Insert button
        @_domButton = @constructor.createDiv([
            'ct-control',
            'ct-control--text',
            'ct-control--insert'
            'ct-control--muted'
            ])
        @_domButton.textContent = ContentEdit._('Insert')
        domControlGroup.appendChild(@_domButton)

        @displayImagePreviewHelp()

        #DOM listeners
        @_addDOMEventListeners()

    _addDOMEventListeners: () ->
        super()

        @_canSave = false

        #provide preview on change of input url
        @_domInput.addEventListener 'input', (ev) =>
            @_updateInsertButton()
            if ev.target.value
                url = @_domInput.value.trim()
                @preview(url)

        #update can save on description change
        @_domDescriptionInput.addEventListener 'input', (ev) =>
            @_updateInsertButton()

        # Button
        @_domButton.addEventListener 'click', (ev) =>
            ev.preventDefault()

            # Check if the fields are populated
            if @_canSave
                @save()

    _updateInsertButton: () ->
        @_canSave = (@_domInput and @_domInput.value.trim()) and (@_domDescriptionInput and @_domDescriptionInput.value.trim())
        if @_canSave
            ContentEdit.removeCSSClass(@_domButton, 'ct-control--muted')
        else
            ContentEdit.addCSSClass(@_domButton, 'ct-control--muted')

    displayImagePreviewHelp: () ->
        @_domPreview = document.createElement('p')
        @_domPreview.setAttribute('class', 'ct-external-image-dialog-preview-text')
        @_domPreview.innerHTML = ContentEdit._('Please provide a valid image url and description')
        @_domPreview.setAttribute('style', 'text-align: center')
        @_domView.appendChild(@_domPreview)

    preview: (url) ->
        #clear preview if any
        if(@_domPreview)
            @_domPreview.parentNode.removeChild(@_domPreview)
            @_domPreview = undefined

        # Insert the preview iframe
        @_domPreview = document.createElement('img')
        @_domPreview.setAttribute('style', 'width: auto; height: 100%')
        @_domPreview.setAttribute('src', url)
        @_domView.appendChild(@_domPreview)

    save: () ->
        data = {
            src: @_domInput.value.trim(), 
            alt : @_domDescriptionInput.value.trim(),
            height : '150',
            width : '200',
        }
        @dispatchEvent(@createEvent('save', data))


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
        # Dispatch `apply` event
        toolDetail = {
            'tool': this,
            'element': element,
            'selection': selection
            }
        if not @dispatchEditorEvent('tool-apply', toolDetail)
            return

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
            if element.restoreState
                element.restoreState()
            callback(false)

        #support saving
        dialog.addEventListener 'save', (ev) =>
            image = new ContentEdit.Image(ev.detail())
            # Find insert position
            [node, index] = @_insertAt(element)
            node.parent().attach(image, index)

            # Focus the new image
            image.focus()

            modal.hide()
            dialog.hide()
            callback(true)

            @dispatchEditorEvent('tool-applied', toolDetail)

        app.attach(modal)
        app.attach(dialog)
        modal.show()
        dialog.show()


