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

	
