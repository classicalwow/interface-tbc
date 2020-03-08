﻿--[[
Name: Sink-2.0
Revision: $Rev: 75975 $
Author(s): Rabbit (rabbit.magtheridon@gmail.com), Antiarc (cheal@gmail.com)
Website: http://rabbit.nihilum.eu
Documentation: http://wiki.wowace.com/index.php/Sink-2.0
SVN: http://svn.wowace.com/wowace/trunk/SinkLib/Sink-2.0
Description: Library that handles chat output.
Dependencies: LibStub, SharedMedia-3.0 (optional)
License: GPL v2 or later.
]]

--[[
Copyright (C) 2008 Rabbit

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
]]

-----------------------------------------------------------------------
-- Sink-2.0

local SINK20 = "LibSink-2.0"
local SINK20_MINOR = string.match("$Revision: 75975 $", "[0-9]+")

local sink = LibStub:NewLibrary(SINK20, SINK20_MINOR)
if not sink then return end

-- Start upgrade
sink.storageForAddon = sink.storageForAddon or {}
sink.override = sink.override or {}
sink.msbt_registered_fonts = sink.msbt_registered_fonts or {}
sink.registeredScrollAreaFunctions = sink.registeredScrollAreaFunctions or {}
sink.handlers = sink.handlers or {}

sink.stickyAddons = sink.stickyAddons or {
	Blizzard = true,
	MikSBT = true,
	SCT = true,
	Parrot = true,
	BCF = true,
}

-- Upgrade complete

local L_DEFAULT = "Default"
local L_DEFAULT_DESC = "Route output from this addon through the first available handler, preferring scrolling combat text addons if available."
local L_ROUTE = "Route output from this addon through %s."
local L_SCT = "Scrolling Combat Text"
local L_MSBT = "MikSBT"
local L_BIGWIGS = "BigWigs"
local L_BCF = "BlinkCombatFeedback"
local L_UIERROR = "Blizzard Error Frame"
local L_CHAT = "Chat"
local L_BLIZZARD = "Blizzard FCT"
local L_RW = "Raid Warning"
local L_PARROT = "Parrot"
local L_CHANNEL = "Channel"
local L_OUTPUT = "Output"
local L_OUTPUT_DESC = "Where to route the output from this addon."
local L_SCROLL = "Sub section"
local L_SCROLL_DESC = "Set the sub section where messages should appear.\n\nOnly available for some output sinks."
local L_STICKY = "Sticky"
local L_STICKY_DESC = "Set messages from this addon to appear as sticky.\n\nOnly available for some output sinks."
local L_NONE = "None"
local L_NONE_DESC = "Hide all messages from this addon."

local l = GetLocale()
if l == "zhCN" then
	L_DEFAULT = "默认"
	L_DEFAULT_DESC = "插件的输出方式取决于第一个可用插件，例如有 SCT 插件，则优先使用。"
	L_ROUTE = "经由%s显示信息。"
	L_SCT = "SCT"
	L_MSBT = "MikSBT"
	L_BIGWIGS = "BigWigs"
	L_BCF = "BlinkCombatFeedback"
	L_UIERROR = "Blizzard 错误框体"
	L_CHAT = "聊天框体"
	L_BLIZZARD = "系统自带滚动战斗信息"
	L_RW = "团队警告"
	L_PARROT = "Parrot"
	L_CHANNEL = "频道"
	L_OUTPUT = "输出模式"
	L_OUTPUT_DESC = "设置显示位置。"
	L_SCROLL = "滚动区域"
	L_SCROLL_DESC = "设置滚动信息显示位置。\n\n只有 Parrot、SCT 及 MikSBT 支持。"
	L_STICKY = "固定"
	L_STICKY_DESC = "设置信息固定显示位置。\n\n只有系统自带滚动战斗信息、Parrot、SCT 及 MikSBT 支持。"
	L_NONE = "隐藏"
	L_NONE_DESC = "隐藏所有来自插件的信息。"
elseif l == "zhTW" then
	L_DEFAULT = "預設"
	L_DEFAULT_DESC = "插件輸出經由第一個可使用的處理器顯示，如果有 SCT 的話，則優先使用。"
	L_ROUTE = "插件輸出經由%s顯示。"
	L_SCT = "SCT"
	L_MSBT = "MikSBT"
	L_BIGWIGS = "BigWigs"
	L_BCF = "BlinkCombatFeedback"
	L_UIERROR = "Blizzard 錯誤訊息框架"
	L_CHAT = "聊天視窗"
	L_BLIZZARD = "Blizzard 浮動戰鬥文字"
	L_RW = "團隊警告"
	L_PARROT = "Parrot"
	L_OUTPUT = "顯示模式"
	L_OUTPUT_DESC = "插件輸出經由哪裡顯示。"
	L_SCROLL = "滾動區域"
	L_SCROLL_DESC = "設定滾動訊息出現位置。\n\n只有 Parrot，SCT 及 MikSBT 有支援。"
	L_STICKY = "固定"
	L_STICKY_DESC = "設定使用固定訊息。\n\n只有 Blizzard 浮動戰鬥文字，Parrot，SCT 及 MikSBT 有支援。"
	L_NONE = "隱藏"
	L_NONE_DESC = "隱藏所有插件輸出。"
end

local SML = LibStub("LibSharedMedia-3.0", true)

local _G = getfenv(0)

function sink:Embed(addon)
	addon.Pour = self.Pour
	addon.RegisterSink = self.RegisterSink
	addon.SetSinkStorage = self.SetSinkStorage
	addon.GetSinkAce2OptionsDataTable = self.GetSinkAce2OptionsDataTable
	addon.GetSinkAce3OptionsDataTable = self.GetSinkAce3OptionsDataTable
end

local function getSticky(addon)
	return sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20Sticky or nil
end

-- Thanks to Antiarc and his Soar-1.0 library for most of the 'meat' of the
-- sink-specific functions.

local function parrot(addon, text, r, g, b, font, size, outline, sticky, loc, icon)
	local location = sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20ScrollArea or "Notification"
	local s = getSticky(addon) or sticky
	Parrot:ShowMessage(text, location, s, r, g, b, font, size, outline, icon)
end

local sct_color = {}
local function sct(addon, text, r, g, b, font, size, outline, sticky, _, icon)
	sct_color.r, sct_color.g, sct_color.b = r, g, b
	local loc = sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20ScrollArea or "Messages"
	local location = (loc == "Outgoing" and SCT.FRAME1) or (loc == "Incoming" and SCT.FRAME2) or SCT.MSG
	local s = getSticky(addon) or sticky
	SCT:DisplayCustomEvent(text, sct_color, s, location, nil, icon)
end

local msbt_outlines = {["NORMAL"] = 1, ["OUTLINE"] = 2, ["THICKOUTLINE"] = 3}
local function msbt(addon, text, r, g, b, font, size, outline, sticky, _, icon)
	if font and SML and not sink.msbt_registered_fonts[font] then
		MikSBT.RegisterFont(font, SML:Fetch("font", font))
		sink.msbt_registered_fonts[font] = true
	end
	local location = sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20ScrollArea or MikSBT.DISPLAYTYPE_NOTIFICATION
	local s = getSticky(addon) or sticky
	MikSBT.DisplayMessage(text, location, s, r * 255, g * 255, b * 255, size, font, msbt_outlines[outline], icon)
end

local bcf_outlines = {NORMAL = "", OUTLINE = "OUTLINE", THICKOUTLINE = "THICKOUTLINE"}
local function bcf(addon, text, r, g, b, font, size, outline, sticky, _, icon)
	if icon then text = "|T"..icon..":20:20:-5|t"..text end
	local loc = sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20ScrollArea or "Sticky"
	local s = getSticky(addon) or sticky
	BlinkCombatFeedback:DisplayCustomEvent({display = {msg = text, color = ("%02x%02x%02x"):format(r * 255, g * 255, b * 255), scrollArea = loc, scrollType = s and "Sticky" or "up", size = size, outling = bcf_outlines[outline], align = "center", font = font}})
end

local function blizzard(addon, text, r, g, b, font, size, outline, sticky, _, icon)
	if icon then text = "|T"..icon..":20:20:-5|t"..text end
	if tostring(SHOW_COMBAT_TEXT) ~= "0" then
		local s = getSticky(addon) or sticky
		CombatText_AddMessage(text, CombatText_StandardScroll, r, g, b, s and "crit" or nil, false)
	else
		UIErrorsFrame:AddMessage(text, r, g, b, 1, UIERRORS_HOLD_TIME)
	end
end

local channelMapping = {
	[SAY] = "SAY",
	[PARTY] = "PARTY",
	[BATTLEGROUND] = "BATTLEGROUND",
	[GUILD_CHAT] = "GUILD",
	[OFFICER_CHAT] = "OFFICER",
	[YELL] = "YELL",
	[RAID] = "RAID",
	[RAID_WARNING] = "RAID_WARNING",
}

local function channel(addon, text)
	-- Sanitize the text, remove all color codes.
	text = text:gsub("(|c%x%x%x%x%x%x%x%x)", ""):gsub("(|r)", "")
	local loc = sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20ScrollArea or SAY
	SendChatMessage(text, channelMapping[loc] or SAY)
end

local function chat(addon, text, r, g, b, _, _, _, _, _, icon)
	if icon then text = "|T"..icon..":15|t"..text end
	DEFAULT_CHAT_FRAME:AddMessage(text, r, g, b)
end

local function uierror(addon, text, r, g, b, _, _, _, _, _, icon)
	if icon then text = "|T"..icon..":20:20:-5|t"..text end
	UIErrorsFrame:AddMessage(text, r, g, b, 1, UIERRORS_HOLD_TIME)
end

local rw
do
	local c = {}
	function rw(addon, text, r, g, b, _, _, _, _, _, icon)
		if not c[r] then c[r] = {} end
		if not c[r][g] then c[r][g] = {} end
		if not c[r][g][b] then c[r][g][b] = {r = r, g = g, b = b} end
		if icon then text = "|T"..icon..":20:20:-5|t"..text end
		RaidNotice_AddMessage(RaidWarningFrame, text, c[r][g][b])
	end
end

local function noop() --[[ noop! ]] end

local handlerPriority = { "Parrot", "SCT", "MikSBT", "BCF" }
-- Thanks to ckk for these
local customHandlersEnabled = {
	Parrot = function()
		return _G.Parrot and _G.Parrot:IsActive()
	end,
	SCT = function()
		return _G.SCT and _G.SCT:IsEnabled()
	end,
	BCF = function()
		return bcfDB and bcfDB["enable"]
	end,
}

-- Default to version 5 or higher now
local msbtVersion = tonumber(string.match(GetAddOnMetadata("MikScrollingBattleText", "Version") or "","^%d+\.%d+")) or 5
local isMSBTFive = math.floor(msbtVersion) > 4 and true or nil
if isMSBTFive then
	customHandlersEnabled.MikSBT = function()
		return _G.MikSBT and not _G.MikSBT.IsModDisabled()
	end
else
	customHandlersEnabled.MikSBT = function()
		return _G.MikSBT and _G.MSBTProfiles and _G.MSBTProfiles.GetSavedVariables() and not MSBTProfiles.GetSavedVariables().UserDisabled
	end
end

local currentHandler = nil
local function getPrioritizedSink()
	if currentHandler then
		local check = customHandlersEnabled[currentHandler]
		if check and check() then
			return sink.handlers[currentHandler]
		end
	end
	for i, v in ipairs(handlerPriority) do
		local check = customHandlersEnabled[v]
		if check and check() then
			currentHandler = v
			return sink.handlers[v]
		end
	end
	if SHOW_COMBAT_TEXT and tostring(SHOW_COMBAT_TEXT) ~= "0" then
		return blizzard
	end
	return chat
end

local function pour(addon, text, r, g, b, ...)
	local func = sink.override and sink.handlers[sink.override] or nil
	if not func and sink.storageForAddon[addon] and sink.storageForAddon[addon].sink20OutputSink then
		local h = sink.storageForAddon[addon].sink20OutputSink
		func = sink.handlers[h]
		-- If this sink is not available now, find one manually.
		if customHandlersEnabled[h] and not customHandlersEnabled[h]() then
			func = nil
		end
	end
	if not func then
		func = getPrioritizedSink()
	end
	if not func then func = chat end
	func(addon, text, r or 1, g or 1, b or 1, ...)
end

function sink:Pour(textOrAddon, ...)
	local t = type(textOrAddon)
	if t == "string" then
		pour(self, textOrAddon, ...)
	elseif t == "table" then
		pour(textOrAddon, ...)
	else
		sink:error("Invalid argument 2 to :Pour, must be either a string or a table.")
	end
end

local sinks
do
	-- Maybe we want to hide them instead of disable
	local function shouldDisableSCT()
		return not _G.SCT
	end
	local function shouldDisableMSBT()
		return not _G.MikSBT
	end
	local function shouldDisableBCF()
		return not ( bcfDB and bcfDB["enable"] )
	end
	local function shouldDisableParrot()
		return not _G.Parrot
	end
	local function shouldDisableFCT()
		return not SHOW_COMBAT_TEXT or tostring(SHOW_COMBAT_TEXT) == "0"
	end

	local channelAreas = { SAY, YELL, PARTY, GUILD_CHAT, OFFICER_CHAT, RAID, RAID_WARNING, BATTLEGROUND }
	local sctFrames = {"Incoming", "Outgoing", "Messages"}
	local msbtFrames = nil
	local function getScrollAreasForAddon(addon)
		if type(addon) ~= "string" then return nil end
		if addon == "Parrot" then
			if Parrot.GetScrollAreasChoices then
				return Parrot:GetScrollAreasChoices()
			else
				return Parrot:GetScrollAreasValidate()
			end
		elseif addon == "MikSBT" then
			if isMSBTFive then
				if not msbtFrames then
					msbtFrames = {}
					for key, name in MikSBT.IterateScrollAreas() do
						table.insert(msbtFrames, name)
					end
				end
				return msbtFrames
			else
				return MikSBT.GetScrollAreaList()
			end
		elseif addon == "BCF" then
			if bcfDB then
				local bcfAreas = { }
				for i = 1, #bcfDB["scrollAreas"] do
					table.insert(bcfAreas, bcfDB["scrollAreas"][i]["name"])
				end
				return bcfAreas
			end
		elseif addon == "SCT" then
			return sctFrames
		elseif addon == "Channel" then
			return channelAreas
		elseif sink.registeredScrollAreaFunctions[addon] then
			return sink.registeredScrollAreaFunctions[addon]()
		end
		return nil
	end

	local emptyTable, args, options = {}, {}, {}
	sinks = {
		Default = {L_DEFAULT, L_DEFAULT_DESC},
		SCT = {L_SCT, nil, shouldDisableSCT},
		MikSBT = {L_MSBT, nil, shouldDisableMSBT},
		BCF = {L_BCF, nil, shouldDisableBCF},
		Parrot = {L_PARROT, nil, shouldDisableParrot},
		Blizzard = {L_BLIZZARD, nil, shouldDisableFCT},
		RaidWarning = {L_RW},
		ChatFrame = {L_CHAT},
		Channel = {L_CHANNEL},
		UIErrorsFrame = {L_UIERROR},
		None = {L_NONE, L_NONE_DESC}
	}

	local function getAce2SinkOptions(key, opts)
		local name, desc, hidden = unpack(opts)
		args["Ace2"][key] = {
			type = "toggle",
			name = name,
			desc = desc or L_ROUTE:format(name),
			isRadio = true,
			hidden = hidden
		}
	end

	function sink.GetSinkAce2OptionsDataTable(addon)
		options["Ace2"][addon] = options["Ace2"][addon] or {
			output = {
				type = "group",
				name = L_OUTPUT,
				desc = L_OUTPUT_DESC,
				pass = true,
				get = function(key)
					if not sink.storageForAddon[addon] then
						return "Default"
					end
					if tostring(key) == "nil" then
						-- Means AceConsole wants to list the output option,
						-- so we should show which sink is currently used.
						return sink.storageForAddon[addon].sink20OutputSink or L_DEFAULT
					end
					if key == "ScrollArea" then
						return sink.storageForAddon[addon].sink20ScrollArea
					elseif key == "Sticky" then
						return sink.storageForAddon[addon].sink20Sticky
					else
						if sink.storageForAddon[addon].sink20OutputSink == key then
							local sa = getScrollAreasForAddon(key)
							options["Ace2"][addon].output.args.ScrollArea.validate = sa or emptyTable
							options["Ace2"][addon].output.args.ScrollArea.disabled = not sa
							options["Ace2"][addon].output.args.Sticky.disabled = not sink.stickyAddons[key]
						end
						return sink.storageForAddon[addon].sink20OutputSink and sink.storageForAddon[addon].sink20OutputSink == key or nil
					end
				end,
				set = function(key, value)
					if not sink.storageForAddon[addon] then return end
					if key == "ScrollArea" then
						sink.storageForAddon[addon].sink20ScrollArea = value
					elseif key == "Sticky" then
						sink.storageForAddon[addon].sink20Sticky = value
					elseif value then
						local sa = getScrollAreasForAddon(key)
						options["Ace2"][addon].output.args.ScrollArea.validate = sa or emptyTable
						options["Ace2"][addon].output.args.ScrollArea.disabled = not sa
						options["Ace2"][addon].output.args.Sticky.disabled = not sink.stickyAddons[key]
						sink.storageForAddon[addon].sink20OutputSink = key
					end
				end,
				args = args["Ace2"],
				disabled = function()
					return (type(addon.IsActive) == "function" and not addon:IsActive()) or nil
				end
			}
		}
		return options["Ace2"][addon]
	end

	-- Ace3 options data table format
	local function getAce3SinkOptions(key, opts)
		local name, desc, hidden = unpack(opts)
		args["Ace3"][key] = {
			type = "toggle",
			name = name,
			desc = desc or L_ROUTE:format(name),
			hidden = hidden
		}
	end

	function sink.GetSinkAce3OptionsDataTable(addon)
		if not options["Ace3"][addon] then
			options["Ace3"][addon] = {
				type = "group",
				name = L_OUTPUT,
				desc = L_OUTPUT_DESC,
				args = args["Ace3"],
				get = function(info)
					local key = info[#info]
					if not sink.storageForAddon[addon] then
						return "Default"
					end
					if tostring(key) == "nil" then
						-- Means AceConsole wants to list the output option,
						-- so we should show which sink is currently used.
						return sink.storageForAddon[addon].sink20OutputSink or L_DEFAULT
					end
					if key == "ScrollArea" then
						return sink.storageForAddon[addon].sink20ScrollArea
					elseif key == "Sticky" then
						return sink.storageForAddon[addon].sink20Sticky
					else
						if sink.storageForAddon[addon].sink20OutputSink == key then
							local sa = getScrollAreasForAddon(key)
                            if sa then
                                for k,v in ipairs(sa) do
                                    sa[k] = nil
                                    sa[v] = v
                                end
                            end
							options["Ace3"][addon].args.ScrollArea.values = sa or emptyTable
							options["Ace3"][addon].args.ScrollArea.disabled = not sa
							options["Ace3"][addon].args.Sticky.disabled = not sink.stickyAddons[key]
						end
						return sink.storageForAddon[addon].sink20OutputSink and sink.storageForAddon[addon].sink20OutputSink == key or nil
					end
				end,
				set = function(info, v)
					local key = info[#info]
					if not sink.storageForAddon[addon] then return end
					if key == "ScrollArea" then
						sink.storageForAddon[addon].sink20ScrollArea = v
					elseif key == "Sticky" then
						sink.storageForAddon[addon].sink20Sticky = v
					elseif v then
						local sa = getScrollAreasForAddon(key)
                        if sa then
                            for k,v in ipairs(sa) do
                                sa[k] = nil
                                sa[v] = v
                            end
                        end
						options["Ace3"][addon].args.ScrollArea.values = sa or emptyTable
						options["Ace3"][addon].args.ScrollArea.disabled = not sa
						options["Ace3"][addon].args.Sticky.disabled = not sink.stickyAddons[key]
						sink.storageForAddon[addon].sink20OutputSink = key
					end
				end,
				disabled = function()
					return (type(addon.IsEnabled) == "function" and not addon:IsEnabled()) or nil
				end,
			}
		end
		return options["Ace3"][addon]
	end

	local sinkOptionGenerators = {
		["Ace2"] = getAce2SinkOptions,
		["Ace3"] = getAce3SinkOptions
	}
	for generatorName, generator in pairs(sinkOptionGenerators) do
		options[generatorName] = options[generatorName] or {}
		args[generatorName] = args[generatorName] or {}
		for name, opts in pairs(sinks) do
			generator(name, opts)
		end
	end

	args["Ace2"].ScrollArea = {
		type = "text",
		name = L_SCROLL,
		desc = L_SCROLL_DESC,
		validate = emptyTable,
		order = -1,
		disabled = true
	}
	args["Ace2"].Sticky = {
		type = "toggle",
		name = L_STICKY,
		desc = L_STICKY_DESC,
		validate = emptyTable,
		order = -2,
		disabled = true
	}

	args["Ace3"].ScrollArea = {
		type = "select",
		name = L_SCROLL,
		desc = L_SCROLL_DESC,
		values = emptyTable,
		order = -1,
		disabled = true
	}
	args["Ace3"].Sticky = {
		type = "toggle",
		name = L_STICKY,
		desc = L_STICKY_DESC,
		order = -2,
		disabled = true
	}

	function sink:RegisterSink(shortName, name, desc, func, scrollAreaFunc, hasSticky)
		assert(type(shortName) == "string")
		assert(type(name) == "string")
		assert(type(desc) == "string" or desc == nil)
		assert(type(func) == "function" or type(func) == "string")
		assert(type(scrollAreas) == "function" or scrollAreas == nil)
		assert(type(hasSticky) == "boolean" or hasSticky == nil)

		if sinks[shortName] or sink.handlers[shortName] then
			sink:error("There's already a sink by the short name %q.", shortName)
		end
		sinks[shortName] = {name, desc}
		-- Save it for library upgrades.
		if not sink.registeredSinks then sink.registeredSinks = {} end
		sink.registeredSinks[shortName] = sinks[shortName]

		if type(func) == "function" then
			sink.handlers[shortName] = func
		else
			sink.handlers[shortName] = function(...)
				self[func](self, ...)
			end
		end
		if type(scrollAreaFunc) == "function" then
			sink.registeredScrollAreaFunctions[shortName] = scrollAreaFunc
		elseif type(scrollAreaFunc) == "string" then
			sink.registeredScrollAreaFunctions[shortName] = function(...)
				return self[scrollAreaFunc](self, ...)
			end
		end
		sink.stickyAddons[shortName] = hasSticky and true or nil

		for k, v in pairs(sinkOptionGenerators) do
			v(shortName, sinks[shortName])
		end
	end
end

function sink.SetSinkStorage(addon, storage)
	assert(type(addon) == "table")
	assert(type(storage) == "table", "Storage must be a table")
	sink.storageForAddon[addon] = storage
end

-- Sets a sink override for -all- addons, librarywide.
function sink:SetSinkOverride(override)
	assert(type(override) == "string" or override == nil)
	if override and not sink.handlers[override] then
		sink:error("There's no %q sink.", override)
	end
	sink.override = override
end

-- Put this at the bottom, because we need the local functions to exist first.
local handlers = {
	Parrot = parrot,
	SCT = sct,
	MikSBT = msbt,
	BCF = bcf,
	ChatFrame = chat,
	Channel = channel,
	UIErrorsFrame = uierror,
	Blizzard = blizzard,
	RaidWarning = rw,
	None = noop,
}
-- Overwrite any handler functions from the old library
for k, v in pairs(handlers) do
	sink.handlers[k] = v
end

