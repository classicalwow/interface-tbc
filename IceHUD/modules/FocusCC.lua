local AceOO = AceLibrary("AceOO-2.0")

-- changed to inherit from the TargetCC bar since the only difference is the unit and the default placement
-- helps keep changes in one place and we don't have to duplicate the CC spell tables and they don't have to be globals
local FocusCC = AceOO.Class(TargetCC)

-- Constructor --
function FocusCC.prototype:init()
	FocusCC.super.prototype.init(self, "FocusCC", "focus")
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function FocusCC.prototype:GetDefaultSettings()
	local settings = FocusCC.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 4
    
	return settings
end

-- 'Protected' methods --------------------------------------------------------

-- Load us up
IceHUD.FocusCC = FocusCC:new()
