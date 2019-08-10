# -------------------------------------------------#
# EXTERNAL PAGE
# -------------------------------------------------#
class ExternalPageDialog extends ContentTools.DialogUI
    constructor: () ->
        super('Insert external page')

    mount: () ->
        super()

        #update dialog class
        ContentEdit.addCSSClass(@_domElement, 'ct-external-page-dialog')

        # update view class
        ContentEdit.addCSSClass(@_domView, 'ct-external-page-dialog-preview')

        # add controls
        domControlGroup = @constructor.createDiv(['ct-control-group'])
        @_domControls.appendChild(domControlGroup)

        # input
        @_domInput = document.createElement('input')
        @_domInput.setAttribute('class', 'ct-external-page-dialog-url-input')
        @_domInput.setAttribute('name', 'url')
        @_domInput.setAttribute(
            'placeholder',
            ContentEdit._('Paste the link to the page') + '...'
            )
        @_domInput.setAttribute('type', 'url')
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

        @displaypagePreviewHelp()

        #DOM listeners
        @_addDOMEventListeners()

    _addDOMEventListeners: () ->
        super()

        @_canSave = false

        #provide preview on change of input url
        @_domInput.addEventListener 'input', (ev) =>
            @_updateCanSave()
            if ev.target.value
                url = @_domInput.value.trim()
                @preview(url)

        # Button
        @_domButton.addEventListener 'click', (ev) =>
            ev.preventDefault()

            # Check if the fields are populated
            if @_canSave
                @save()

    _updateCanSave: () ->
        @_canSave = (@_domInput and @_domInput.value.trim())
        if @_canSave
            ContentEdit.removeCSSClass(@_domButton, 'ct-control--muted')
        else
            ContentEdit.addCSSClass(@_domButton, 'ct-control--muted')

    displaypagePreviewHelp: () ->
        @_domPreview = document.createElement('p')
        @_domPreview.setAttribute('class', 'ct-external-page-dialog-preview-text')
        @_domPreview.innerHTML = ContentEdit._('Please provide a valid page url. Be aware that not all websites allow to be embedded')
        @_domPreview.setAttribute('style', 'text-align: center')
        @_domView.appendChild(@_domPreview)

    preview: (url) ->
        #clear preview if any
        if(@_domPreview)
            @_domPreview.parentNode.removeChild(@_domPreview)
            @_domPreview = undefined

        # Insert the preview iframe
        @_domPreview = document.createElement('iframe')
        @_domPreview.setAttribute('frameborder', '0')
        @_domPreview.setAttribute('height', '100%')
        @_domPreview.setAttribute('src', url)
        @_domPreview.setAttribute('width', '100%')
        @_domView.appendChild(@_domPreview)

    save: () ->
        data = {
            src: @_domInput.value.trim(),
        }
        @dispatchEvent(@createEvent('save', data))


class ExternalPageTool extends ContentTools.Tool
    ContentTools.ToolShelf.stow(@, 'external-page')

    @label = 'External Page'
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
        dialog = new ExternalPageDialog()

        #support cancelling
        dialog.addEventListener 'cancel', () =>
            modal.hide()
            dialog.hide()
            if element.restoreState
                element.restoreState()
            callback(false)

        #support saving
        dialog.addEventListener 'save', (ev) =>
            attrs = {
                src: ev.detail().src
                width: '200' #'100%'
                height: '200'
            }
            image = new ContentEdit.Video('iframe', attrs)
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