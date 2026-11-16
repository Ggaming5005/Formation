--!strict
local Theme = {}
function Theme.colors()
	local theme = settings().Studio.Theme
	local function get(style: Enum.StudioStyleGuideColor)
		return theme:GetColor(style)
	end
	return {
		background = get(Enum.StudioStyleGuideColor.MainBackground),
		panel = get(Enum.StudioStyleGuideColor.InputFieldBackground),
		text = get(Enum.StudioStyleGuideColor.MainText),
		muted = get(Enum.StudioStyleGuideColor.DimmedText),
		border = get(Enum.StudioStyleGuideColor.Border),
		button = get(Enum.StudioStyleGuideColor.Button),
		accent = Color3.fromRGB(92, 158, 127),
	}
end
return Theme
