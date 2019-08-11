# CHANGE THE FONT OF A SELECTED TEXT #
class FontDialog extends ContentTools.AnchoredDialogUI
    constructor: (font = '') ->
        super()
        #store initial font
        @_font = font

    mount: () ->
        super()
        
        @_domInput = document.createElement('select')
        @_domInput.setAttribute('class', 'ct-font-view-select')
        if ContentTools.FONTS 
            defaultOption = document.createElement('option')
            defaultOption.value = 'none'
            defaultOption.text = ContentEdit._('Default')
            @_domInput.appendChild(defaultOption)
            for fontName in ContentTools.FONTS
                option = document.createElement('option')
                option.value = fontName.replace(/\s/g, '-')
                option.text = fontName
                @_domInput.appendChild(option)
        @_domElement.appendChild(@_domInput)
    
        # Create the confirm button
        @_domButton = @constructor.createDiv(['ct-anchored-dialog__button'])
        @_domElement.appendChild(@_domButton)

        #update the class
        ContentEdit.addCSSClass(@_domElement, 'ct-font-view')

        # Add interaction handlers
        @_addDOMEventListeners()

    _addDOMEventListeners: () ->
        # Add event listeners for the widget
        # Button
        @_domButton.addEventListener 'click', (ev) =>
            ev.preventDefault()
            @save()

        @_domInput.addEventListener 'change', (ev) =>
            @dispatchEvent(@createEvent('font-updated', event.target.value))

    save: () ->
        @dispatchEvent(@createEvent('save', event.target.value))


# ------------------------------------------- #
# TOOL
# ------------------------------------------- #
class Font extends ContentTools.Tool
    ContentTools.ToolShelf.stow(@, 'font')

    @label = 'Font'
    @icon = 'font'

    @canApply: (element, selection) ->        
        elType = element.type()
        if (elType is 'Image') or (elType is 'ImageFixture') or (elType is 'Video')
            return false
        else
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

        # If supported allow store the state for restoring once the dialog is
        # cancelled.
        if element.storeState
            element.storeState()

        # Set-up the dialog
        app = ContentTools.EditorApp.get()

        # Modal
        modal = new ContentTools.ModalUI(transparent=true, allowScrolling=true)
        
        # The user did not confirm its font
        caller = this
        modal.addEventListener 'click', () ->
            @unmount()
            caller._resetGoogleFontClass(element, selection)
            dialog.hide()

            # Restore the selection
            element.restoreState()
            callback(false)

        # Dialog
        dialog = new FontDialog()

        dialog.addEventListener('font-updated', ((ev) ->
            @_resetGoogleFontClass(element, selection)
            @_addGoogleFontClass(ev.detail(), element, selection)
            ).bind(this))

        dialog.addEventListener 'save', (ev) ->
            # do nothing, the font is already applied by font-updated
            modal.hide()
            dialog.hide()
            callback(true)

            caller.dispatchEditorEvent('tool-applied', toolDetail)

        # Get the scroll position required for the dialog
        [scrollX, scrollY] = ContentTools.getScrollPosition()
        rect = ContentSelect.Range.rect()
        dialog.position([
            rect.left + (rect.width / 2) + scrollX,
            rect.top + (rect.height / 2) + scrollY
            ])

        #show the dialog
        app.attach(modal)
        app.attach(dialog)
        modal.show()
        dialog.show()

    @_resetGoogleFontClass: (element, selection) ->
        if selection.isCollapsed()
            if element.attr('data-font-wrapper') is 'gfont'
                classes = element.attr('class')
                if classes # can be empty if no class applied
                    fontClass = classes.match(/\bgf-.*\b/g)
                    for toRemove in fontClass
                        element.removeCSSClass(toRemove)
        else
            [from, to] = selection.get()
            for fontName in ContentTools.FONTS
                fontClass = 'gf-'+fontName.replace(/\s/g, '-')
                span = new HTMLString.Tag('span', {'class': fontClass, 'data-font-wrapper': 'gfont'})            
                element.content = element.content.unformat(from, to, 'span')
                element.content.optimize()
                element.updateInnerHTML()


    @_addGoogleFontClass: (font, element, selection) -> 
        fontClass = 'gf-'+font
        if selection.isCollapsed()
            element.attr('data-font-wrapper', 'gfont')
            element.addCSSClass(fontClass)
        else            
            [from, to] = selection.get()
            span = new HTMLString.Tag('span', {'class': fontClass, 'data-font-wrapper': 'gfont'})
            element.content = element.content.format(from, to, span)
            element.content.optimize()
            element.updateInnerHTML()
        

