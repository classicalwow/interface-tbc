ZYGORGUIDESVIEWER_COMMAND = "/zygor"

ZygorGuidesViewer = Rock:NewAddon("Zygor Guides Viewer", "LibRockEvent-1.0", "LibRockTimer-1.0", "LibRockDB-1.0", "LibRockModuleCore-1.0", "LibRockHook-1.0", "LibRockConfig-1.0")

ZGV = ZygorGuidesViewer

local L = AceLibrary("AceLocale-2.2"):new("ZygorGuidesViewer")
L:RegisterTranslations("enUS", function() return {
	["name"] = "Zygor's Guides Viewer",
	["title"] = "Zygor's Guides",

	["toggle_window"] = "Toggle Zygor's Guides window",
	
	["opt_debug"] = "Debug",
	 ["opt_debug_desc"] = "Display debug info.",
	["opt_debugging"] = "Debugging",
	 ["opt_debugging_desc"] = "Debugging options.",
	["opt_opacitymain"] = "Main window opacity",
	 ["opt_opacitymain_desc"] = "Opacity of the main Zygor's Guides window.",
	["opt_opacitymini"] = "Mini window opacity",
	 ["opt_opacitymini_desc"] = "Opacity of Zygor's Guides mini window.",
	["opt_browse"] = "Toggle windows",
	 ["opt_browse_desc"] = "Toggle the visibility of either of Zygor's Guides windows.",
	["opt_autosizemini"] = "Auto-size mini window",
	 ["opt_autosizemini_desc"] = "Automatically adjust the height of the mini window.",
	["opt_minimapnotedesc"] = "Show mapnote text in mini window",
	 ["opt_minimapnotedesc_desc"] = "Show mapnote description not only on the mapnote tooltip, but on the mini window as well.",
	["opt_autoskip"] = "Advance automatically",
	 ["opt_autoskip_desc"] = "Automatically skip to the next step, when all conditions are completed. You might still have to manually skip some steps that have completion conditions too complex for the guide to detect reliably.",
	["opt_showgoals"] = "Show step goals",
	 ["opt_showgoals_desc"] = "Show step completion goals in the mini window",

	["checkmap"] = "Check your map.",

	["initialized"] = 'Initialized.',

	["missing_text_long"] = "Zygor's 1-70 "..UnitFactionGroup("player").." Leveling Guide is not loaded.|n|nPlease go to http://zygorguides.com to purchase it!|n|nIf you have indeed installed Zygor's 1-70 "..UnitFactionGroup("player").." Leveling Guide, make sure it's properly located in the Interface\\Addons\\ZygorGuides"..UnitFactionGroup("player").." folder in your World of Warcraft game folder and enabled on the character selection screen.",
	["missing_text_short"] = "Zygor's 1-70 "..UnitFactionGroup("player").." Leveling Guide is either missing, disabled, or improperly installed.",

	["stepgoal_questaccepted"] = "Accept: %s",
	["stepgoal_questturnedin"] = "Turn in: %s",
	["stepgoal_questgoal"] = "%s",
	["stepgoal_level"] = "To level %d: %d%%",
	["stepgoal_home"] = "Set home location to %s",
	["stepgoal_flightpath"] = "Get the %s flight path",
	["stepgoal_location"] = "Go to %s %d:%d",
	["stepgoal_location_onlyzone"] = "Go to %s",
	["stepgoal_item"] = "%s (%d/%d)",

	["stepgoalshort_complete"] = "(complete)",
	["stepgoalshort_incomplete"] = "",
	["stepgoalshort_questgoal"] = "(%d/%d)",
	["stepgoalshort_level"] = "(%d%%)",

	["stepgoal_complete"] = " (complete)",

	["home_trigger"] = "(.*) is now your home",
	["flightpath_trigger"] = "New flight path discovered",

	["map_highlight"] = "Highlight"

} end)

BINDING_HEADER_ZYGORGUIDES = L["title"]
BINDING_NAME_ZYGORGUIDES_OPENGUIDE = L["toggle_window"]

--ZygorGuidesViewer = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "AceModuleCore-2.0")

local me = ZygorGuidesViewer

me.L = L

--me:RegisterDB("ZygorGuidesViewer_Profile");
me:SetDatabase("ZygorGuidesViewerSettings","ZygorGuidesViewerSettingsChar")


me.icons = {
	["hilite"] = {	text = L["map_highlight"],		path = "Interface\\AddOns\\ZygorGuidesViewer\\Skin\\highlightmap",	width = 32, height = 32, alpha=1 },
	["hilitesquare"] = {	text = L["map_highlight"],		path = "Interface\\AddOns\\ZygorGuidesViewer\\Skin\\highlightmap_square",	width = 32, height = 32, alpha=1 },
}

me.CartographerDatabase = { }

me.StepLimit = 350;

local lua51
function me:OnInitialize() 
	--self:RegisterDefaults("profile", { debug=false })

	self:SetProfile("char")
	if self.db.profile.visible==nil then
		self.db.profile["starting"] = true
		self.db.profile["section"] = 1
		self.db.profile["step"] = 1
		self.db.profile["debug"] = false
		self.db.profile["minimode"] = false
		self.db.profile["visible"] = true
		self.db.profile["hidecompleted"] = false
		self.db.profile["iconAlpha"] = 1
		self.db.profile["iconScale"] = .5
		self.db.profile["minicons"] = true
		self.db.profile["filternotes"] = true
		self.db.profile["autosizemini"] = true
		self.db.profile["minimapnotedesc"] = true
		self.db.profile["autoskip"] = true
		self.db.profile["showgoals"] = true
	end

	self.options = {
		type='group',
		name = L["name"],
		desc = self.notes,
		handler = self,
		args = {
			debug = {
				name = L["opt_debug"],
				desc = L["opt_debug_desc"],
				type = 'toggle',
				get = "GetDebugMode",
				set = "SetDebugMode",
				order=-10,
			},
			opacitymain = {
				name = L["opt_opacitymain"],
				desc = L["opt_opacitymain_desc"],
				type = 'number',
				get = "GetOpacityMain",
				set = "SetOpacityMain",
				min = 0,
				max = 1,
				isPercent = true,
				step = 0.01,
				bigStep = 0.1,
				stepBasis = 0,
				order=1,
			},
			opacitymini = {
				name = L["opt_opacitymini"],
				desc = L["opt_opacitymini_desc"],
				type = 'number',
				get = "GetOpacityMini",
				set = "SetOpacityMini",
				min = 0,
				max = 1,
				isPercent = true,
				step = 0.01,
				bigStep = 0.1,
				stepBasis = 0,
				order=1,
			},
			debugging = {
				name = L["opt_debugging"],
				hidden = function() return not self.db.profile.debug end,
				desc = L["opt_debugging_desc"],
				type = 'group',
				order=-9,
				args = {
					test = {
						type = 'execute',
						name = 'test',
						desc = 'Test whatever\'s being tested.',
						func = "Test",
						order=21,
					},
				},
			},

			autosizemini = {
				name = L["opt_autosizemini"],
				desc = L["opt_autosizemini_desc"],
				type = 'toggle',
				get = "GetAutosizeMini",
				set = "SetAutosizeMini",
				order=-10,
			},
			autoskip = {
				name = L["opt_autoskip"],
				desc = L["opt_autoskip_desc"],
				type = 'toggle',
				get = "GetAutoskip",
				set = "SetAutoskip",
				order=-10,
			},
			showgoals = {
				name = L["opt_showgoals"],
				desc = L["opt_showgoals_desc"],
				type = 'toggle',
				get = "GetShowgoals",
				set = "SetShowgoals",
				order=-10,
			},
			minimapnotedesc = {
				name = L["opt_minimapnotedesc"],
				desc = L["opt_minimapnotedesc_desc"],
				type = 'toggle',
				get = "GetMiniMapnoteDesc",
				set = "SetMiniMapnoteDesc",
				order=-10,
			},
			transparency = {
				name = "Icon alpha",
				desc = "Alpha transparency of map note icons",
				type = 'range',
				min = 0.1,
				max = 1,
				step = 0.01,
				bigStep = 0.05,
				isPercent = true,
				get = "GetIconAlpha",
				set = "SetIconAlpha",
				order = 1
			},
			scale = {
				name = "Icon size",
				desc = "Size of the icons on the map",
				type = 'range',
				min = 0.5,
				max = 2,
				step = 0.01,
				bigStep = 0.05,
				isPercent = true,
				get = "GetIconScale",
				set = "SetIconScale",
				order = 1
			},
			minicons = {
				name = "Show minimap icons",
				desc = "Show icons on the minimap",
				type = 'toggle',
				set = "ToggleShowingMinimapIcons",
				get = "IsShowingMinimapIcons",
				order = 1,
			},
			--[[
			mapicons = {
				name = "Show map icons",
				desc = "Show icons on the world map",
				type = 'toggle',
				set = "ToggleShowingMapIcons",
				get = "IsShowingMapIcons",
				order = 1,
			},
			toggle = {
				name = Cartographer.L["Enabled"],
				desc = Cartographer.L["Suspend/resume this module."],
				type  = 'toggle',
				order = -1,
				get   = function() return Cartographer:IsModuleActive(self) end,
				set   = function() Cartographer:ToggleModuleActive(self) end,
			}	
			]]--
		},
	}
	
	--self:RegisterChatCommand({ZYGORGUIDESVIEWER_COMMAND}, self.options);
	self:SetConfigSlashCommand(ZYGORGUIDESVIEWER_COMMAND, "/zg");
	self:SetConfigTable(self.options);
	
	if ZygorGuidesViewerFrame then
		self.options.args['show'] = {
			name = L["opt_browse"],
			desc = L["opt_browse_desc"],
			type = 'execute',
			func = "ToggleFrame",
		}
	end

	self.CurrentStepNum = self.db.profile.step
	self.CurrentSectionNum = self.db.profile.section

	self.QuestCacheTime = 0
	self.QuestCacheUndertimeRepeats = 0
	self.questIndicesByTitle = {}
	self.StepCompletion = {}
	self.recentlyCompletedQuests = {}
	self.recentlyAcceptedQuests = {}
	self.LastSkip = 0
	self.AutoskipTemp = true

	self:Echo(L["initialized"]);
	lua51 = loadstring("return function(...) return ... end") and true or false
end

function me:OnEnable()
	self:Debug("enabling")

	local faction = UnitFactionGroup("player")

	if not IsAddOnLoaded("ZygorGuides"..faction) then
		loaded,reason = LoadAddOn("ZygorGuides"..faction)
		if not loaded then
			self:Echo ("Unable to load the "..faction.." Guide: "..reason)
		end
	end
	
	self.Guide = getglobal("ZygorGuidesViewer_"..UnitFactionGroup("player").."Guide")

	if self.Guide then
		self.MapNotes = _G["ZygorGuides_"..UnitFactionGroup("player").."Mapnotes"]

		if Cartographer_Notes then
			self:Debug("registering database "..#self.MapNotes)
			Cartographer_Notes:RegisterNotesDatabase('ZygorGuides', self.MapNotes, self)
			self:Debug("registered database")

			self:Debug("registering icons")
			if not self.iconsregistered then
				for k,v in pairs(self.icons) do
					Cartographer_Notes:RegisterIcon(k, v)
				end
			end
			self.iconsregistered = true
			self:Debug("registered icons")
		else
			self:Echo ("Cartographer Notes module not found.")
		end

		ZYGORGUIDESVIEWERFRAME_TITLE = "Zygor's 1-70 "..UnitFactionGroup("player").." Leveling Guide";
		self:Echo (UnitFactionGroup("player").." guide loaded.")

		self:AddRepeatingTimer("ZygorGuidesViewer_MapArrow", 0.1, "UpdateMinimapArrow")
		self:AddRepeatingTimer(self, 1, "TryToCompleteStep")
		self:AddEventListener("MINIMAP_UPDATE_ZOOM")
		ZygorGuidesViewerMapArrow:SetScale(0.66)
		ZygorGuidesViewerMapArrow:SetFrameLevel(10)

		-- retrieve profile settings
		if not self.db.profile['section'] or not self.Guide[self.db.profile['section']] or self.db.profile["starting"] then
			self.db.profile['section'] = self:FindDefaultSection()
		end
		self:SetSection(self.db.profile["section"])
		if #self.CurrentSection.steps<self.db.profile["step"] then 
			self.db.profile['step'] = 1
		end
		self:FocusStep(self.db.profile['step'])
	else
		self:Echo (UnitFactionGroup("player").." guide missing.")
	end

	self.db.profile["starting"] = false

	if self.db.profile["visible"] then self:ToggleFrame() end

	ZygorGuidesViewerMapIcon:Show()
	self:SetOpacityMain(self:GetOpacityMain())
	self:SetOpacityMini(self:GetOpacityMini())

	self:Debug("enabled")

	self:AddEventListener("QUEST_WATCH_UPDATE")
	self:AddEventListener("QUEST_LOG_UPDATE")
	self:AddEventListener("QUEST_COMPLETE")
	self:AddEventListener("QUEST_FINISHED")
--	self:AddEventListener("QUEST_PROGRESS")
	self:AddEventListener("QUEST_ITEM_UPDATE")
	self:AddEventListener("UNIT_QUEST_LOG_CHANGED")
	self:AddEventListener("CHAT_MSG_SYSTEM")
	self:AddEventListener("UI_INFO_MESSAGE")
end

function me:OnDisable()
--	self:UnregisterAllEvents()

	if Cartographer_Notes then
		Cartographer_Notes:UnregisterNotesDatabase('ZygorGuidesViewer')
	end
	ZygorGuidesViewerMapIcon:Hide()
	ZygorGuidesViewerFrame:Hide()
	ZygorGuidesViewerMiniFrame:Hide()
end

function me:SetSection(num)
	self:Debug("SetSection "..num)
	if num<1 then num=1 end
	if num>#self.Guide then num=#self.Guide end
	self.CurrentSectionNum = num
	self.db.profile["section"] = num
	self.CurrentSection = self.Guide[num]
	self:UpdateMainFrame()
end

function me:FindDefaultSection()
	local x,race = UnitRace("player")
	for i,sec in pairs(self.Guide) do
		if sec.defaultfor == race then
			return i
		end
	end
	return 1
end

function me:Test ()
	self:Debug("Testing 1,2,3")
end

function me:Echo (s)
	--if not self.db.profile.silent then 
	self:Print(self:nilsafe(s))
	--end
end

function me:nilsafe(s)
	if s==true then return "true" end
	if s==false then return "false" end
	if s==nil then return "nil" end
	return s
end

function me:Debug (s)
	if self.db.profile.debug then
		self.DebugI = (self.DebugI or 0) + 1
		self:Echo('|cffa0a0a0#' .. self.DebugI .. ': ' .. self:nilsafe(s))
	end
end

function me:GetDebugMode()
	return self.db.profile.debug;
end
function me:SetDebugMode(v)
	self.db.profile.debug = v
end

function me:GetAutosizeMini()
	return self.db.profile.autosizemini
end
function me:SetAutosizeMini(n)
	self.db.profile.autosizemini = n
	self:UpdateMiniFrame()
end

function me:GetShowgoals()
	return self.db.profile.showgoals
end
function me:SetShowgoals(n)
	self.db.profile.showgoals = n
	self:UpdateMiniFrame()
end

function me:GetAutoskip()
	return self.db.profile.autoskip
end
function me:SetAutoskip(n)
	self.db.profile.autoskip = n
end

function me:GetMiniMapnoteDesc()
	return self.db.profile.minimapnotedesc
end
function me:SetMiniMapnoteDesc(n)
	self.db.profile.minimapnotedesc = n
	self:UpdateMiniFrame()
end

function me:GetOpacityMain()
	return self.db.profile.opacitymain or 1.0
end
function me:SetOpacityMain(n)
	self.db.profile.opacitymain = n
	ZygorGuidesViewerFrame:SetAlpha(n)
end

function me:GetOpacityMini()
	return self.db.profile.opacitymini or 1.0
end
function me:SetOpacityMini(n)
	self.db.profile.opacitymini = n
	ZygorGuidesViewerMiniFrame_Border:SetAlpha(n)
	ZygorGuidesViewerMiniFrame_Background:SetAlpha(n)
end

function me:FocusStep(num)
	self:Debug("FocusStep "..num)
	self.CurrentStepNum = num
	self.db.profile["step"] = num
	self.CurrentStep = self.CurrentSection["steps"][num]
	self:PrepareStepCompletion()
	self:HighlightCurrentStep()
	self:UpdateMainFrame()
	self:UpdateMiniFrame()
	self:UpdateCartographerExport()
	self:SetWaypoint()
	self:UpdateMinimapArrow(true)
	if (self:IsStepComplete() and self.LastSkip~=0) then self.AutoskipTemp=false else self.AutoskipTemp=true end
	self.LastSkip=0
end

function me:TryToCompleteStep()
	if self.AutoskipTemp and self.db.profile.autoskip and self:IsStepComplete() then
		self.recentlyCompletedQuests = {} -- forget it! We're skipping the step, already.
		self.recentlyAcceptedQuests = {}
		self.recentlyHomeChanged = false
		self.recentlyDiscoveredFlightpath = false
		self:SkipStep(1)
	end
	self:UpdateMiniFrame()
end

function me:GetTextualCompletion()
	if not self.db.profile.showgoals then return "" end
	local s = "|n---"
	if (#self.StepCompletion > 0) then
		for i,v in pairs(self.StepCompletion) do
			s = s .. "|n" .. self:GetTextualCompletionGoal(i)
		end
	end
	return s
end

function me:GetTextualCompletionGoal(goalIndex)
	local goal = self.StepCompletion[goalIndex]
	local desc = ""
--	self:Debug("GetTextualCompletionGoal goalindex "..goalIndex)
	if goal.questaccepted then
		desc = L["stepgoal_questaccepted"]:format(goal.questaccepted)
	end
	if goal.questturnedin then
		desc = L["stepgoal_questturnedin"]:format(goal.questturnedin)
	end
	if goal.questgoal then
		local quest,goal,count = goal.questgoal[1],goal.questgoal[2],goal.questgoal[3]
		if quest=="*" then
			quest = self:ImproviseQuestTitle(goal)
		end
		local questIndex = self.questIndicesByTitle[quest]
		if questIndex and questIndex>0 then
			local goals,goalsNamed = self:GetQuestLeaderBoards(questIndex)
			local questGoal = goalsNamed[goal]
			if questGoal then
				desc = L["stepgoal_questgoal"]:format(questGoal.leaderboard)
			else
				desc = goal .. ": ?"
			end
		else
			desc = goal .. ": 0"
		end
	end
	if goal.level then
		local percent = floor(UnitXP("player")/UnitXPMax("player") * 100)
		if self:IsStepGoalComplete(goalIndex) then
			percent = 100
		end
		desc = L["stepgoal_level"]:format(goal.level,percent)
	end
	if goal.home then
		desc = L["stepgoal_home"]:format(goal.home)
	end
	if goal.flightpath then
		desc = L["stepgoal_flightpath"]:format(goal.flightpath)
	end
	if goal.location then
		if goal.location.x then
			desc = L["stepgoal_location"]:format(goal.location.mapzone, goal.location.x, goal.location.y)
		else
			desc = L["stepgoal_location_onlyzone"]:format(goal.location.mapzone or "?")
		end
	end
	if goal.item then
		desc = L["stepgoal_item"]:format(goal.item[1],GetItemCount(goal.item[1]),goal.item[2])
	end

	local complete,ext = self:IsStepGoalComplete(goalIndex)
	if complete then
		desc = "|cffbbffbb" .. desc .. " " .. L["stepgoal_complete"] .. "|r"
	elseif ext then
		desc = "|cffffbbbb" .. desc .. "|r"
	else
		desc = "|cffaaaaaa" .. desc .. "|r"
	end
	return desc
end

function me:GetTextualCompletionGoalShort(goalIndex)
	local goal = self.StepCompletion[goalIndex]
	local completecolor = " |cffbbffbb"
	local incompletecolor = " |cffffbbbb"

	local complete,ext = self:IsStepGoalComplete(goalIndex)

--	self:Debug("GetTextualCompletionGoal goalindex "..goalIndex)
	if goal.questaccepted or goal.questturnedin or goal.home or goal.location or goal.flightpath then
		return (complete and completecolor..L["stepgoalshort_complete"] or incompletecolor..L["stepgoalshort_incomplete"]) .."|r"
	end
	if goal.questgoal then
		local quest,goal,count = goal.questgoal[1],goal.questgoal[2],goal.questgoal[3]
		if quest=="*" then
			quest = self:ImproviseQuestTitle(goal)
		end
		local questIndex = self.questIndicesByTitle[quest]
		if questIndex and questIndex>0 then
			local goals,goalsNamed = self:GetQuestLeaderBoards(questIndex)
			local questGoal = goalsNamed[goal]
			if questGoal then
				return (complete and completecolor..L["stepgoalshort_complete"] or incompletecolor..L["stepgoalshort_questgoal"]:format(questGoal.num,questGoal.needed)) .."|r"
			else
				return ""
			end
		else
			return ""
		end
	end
	if goal.level then
		local percent = floor(UnitXP("player")/UnitXPMax("player") * 100)
		if self:IsStepGoalComplete(goalIndex) then
			percent = 100
		end
		return (complete and completecolor..L["stepgoalshort_complete"] or incompletecolor..L["stepgoal_level"]:format(percent)) .."|r"
	end
	return ""
end

function me:ImproviseQuestTitle(goal)
	if not self.quests then return "" end
	for i,q in pairs(self.quests) do
		if q.goals then
			for j,g in pairs(q.goals) do
				if g.item==goal then
					return q.title
				end
			end
		end
	end
	return ""
end

-- returns: true = complete, false = incomplete
-- second return: true = completable, false = incompletable
function me:IsStepGoalComplete(goalIndex)
	local goal = self.StepCompletion[goalIndex]
	if not goal then return false end
	if goal.questaccepted then
		-- Check for "turn in, accept" pair of the same quest - a workaround for "turn in part 1, accept part 2" steps
		if self.questIndicesByTitle[goal.questaccepted] and goalIndex>1 then
			local i
			for i = goalIndex-1, 1, -1 do
				if self.StepCompletion[i].questturnedin==goal.questaccepted and not self:IsStepGoalComplete(i) then return false,true end
			end
		end
		return (self.questIndicesByTitle[goal.questaccepted] or self.recentlyAcceptedQuests[goal.questaccepted]) and true or false, true
	end
	if goal.questturnedin then
		return self.recentlyCompletedQuests[goal.questturnedin], self.questIndicesByTitle[goal.questturnedin] and (self.quests[self.questIndicesByTitle[goal.questturnedin]].complete or #self.quests[self.questIndicesByTitle[goal.questturnedin]].goals==0)
	end
	if goal.questgoal then
		local quest,goal,count = goal.questgoal[1],goal.questgoal[2],goal.questgoal[3]
		if quest=="*" then
			quest = self:ImproviseQuestTitle(goal)
		end
		local questIndex = self.questIndicesByTitle[quest]
		if questIndex and questIndex>0 then
			local goals,goalsNamed = self:GetQuestLeaderBoards(questIndex)
			local questGoal = goalsNamed[goal]
--			self:Debug("IsStepComplete: quest goal "..goal)
			if questGoal then
				if questGoal.complete then
					return true
				else
--					self:Debug("Not yet completed: "..questGoal.num.."/"..questGoal.needed)
					return false, true
				end
			else
--				self:Debug("No goal "..goal)
				return false, false
			end
		else
--			self:Debug("No quest "..quest)
			return false, false
		end
	end
	if goal.level then
		return UnitLevel("player")>=tonumber(goal.level), true
	end
	if goal.location then
		if GetZoneText()~=goal.location.mapzone then return false,false end
		if goal.location.x then
			local x,y = GetPlayerMapPosition("player")
			local dist = goal.location.dist/100 or 0.01
			return abs(x-goal.location.x/100)<=dist and abs(y-goal.location.y/100)<=dist , true
		else
			return true,true
		end
	end
	if goal.home then
--		return GetBindLocation("player")==goal.home, true  -- didn't work well
		return self.recentlyHomeChanged, true
	end
	if goal.flightpath then
--		return GetBindLocation("player")==goal.home, true  -- didn't work well
		return self.recentlyDiscoveredFlightpath, true
	end
	if goal.item then
		return GetItemCount(goal.item[1])>=goal.item[2], true
	end
	return false,false
end

function me:IsStepComplete()
	--self:Debug("Step complete check")
	if (#self.StepCompletion > 0) then
		for i,v in pairs(self.StepCompletion) do
			if not self:IsStepGoalComplete(i) then
				return false
			end
		end
		return true
	else
		return false
	end
end

function me:PrepareStepCompletion()
	self.StepCompletion = {}
	if self.CurrentStep.completion then
		for i,v in pairs(self.CurrentStep.completion) do
			if v.questaccepted then
				v.questaccepted = string.gsub(v.questaccepted," part [1-9]$","")
			end
			if v.questturnedin then
				v.questturnedin = string.gsub(v.questturnedin," part [1-9]$","")
			end
			if v.location and not v.location.mapzone and self.CurrentStep.mapnote then
				self:Debug("Dist only!")
				v.location.mapzone = self.CurrentStep.mapzone
				v.location.x,v.location.y = Cartographer_Notes.getXY(self.CurrentStep.mapnote)
				v.location.x,v.location.y = v.location.x*100,v.location.y*100
			end
			self.StepCompletion[#self.StepCompletion+1] = v
		end
	end
	self:Dump(self.StepCompletion)
end

function me:FindMatchingGoal(s)
	local verb,pronoun
	quest = string.match(s,"Accept.*`(.*)'")
	if quest then
		quest = string.gsub(quest," part [1-9]$","")
		for i=1, #self.CurrentStep.completion, 1 do if self.CurrentStep.completion[i].questaccepted == quest then return i end end
	end
	quest = string.match(s,"Turn in.*`(.*)'")
	if quest then
		quest = string.gsub(quest," part [1-9]$","")
		for i=1, #self.CurrentStep.completion, 1 do if self.CurrentStep.completion[i].questturnedin == quest then return i end end
	end
	level = tonumber(string.match(s,"Grind to level ([0-9]+)"))
	if level then
		for i=1, #self.CurrentStep.completion, 1 do if self.CurrentStep.completion[i].level == level then return i end end
	end
	return nil
end




function me:SetWaypoint()
	if Cartographer_Waypoints then
		self:Debug("Setting waypoint")
		local mapnote = self.CurrentStep["mapnote"]
		local mapzone = self.CurrentStep["mapzone"]
--		self:Debug(self.CurrentStep.mapnote)
		local queue = Cartographer_Waypoints.Queue
		for i,v in ipairs(queue) do
			if v and v.Db=="ZygorGuides" then
				table.remove(queue,i)
			end
		end
		if mapnote and mapzone then
			Cartographer_Waypoints:SetNoteAsWaypoint(mapzone,mapnote)
		end
	else
		self:Debug("No waypoint module!")
	end
end

local rotateMinimap = GetCVar("rotateMinimap") == "1"
--local maxdist = 0.001186
local MinimapSize = { -- radius of minimap
	indoor = {
		[0] = 150,
		[1] = 120,
		[2] = 90,
		[3] = 60,
		[4] = 40,
		[5] = 25,
	},
	outdoor = {
		[0] = 233 + 1/3,
		[1] = 200,
		[2] = 166 + 2/3,
		[3] = 133 + 1/6,
		[4] = 100,
		[5] = 66 + 2/3,
	},
}

local opx,opy = 0,0
local ozoom = -1

function me:UpdateMinimapArrow(force)
	local px,py = GetPlayerMapPosition("player")
	local diffPos = (opx~=px or opy~=py)

	local zoom=Minimap.GetZoom()
	local diffZoom = (zoom~=ozoom)

	opx,opy = px,py
	ozoom = zoom

	if not diffPos and not diffZoom and not force then return end

	ZygorGuidesViewerMapArrow:Hide()
	ZygorGuidesViewerMapArrowFrame:Hide()
	if not self.CurrentStep then return end

	local maxdist = MinimapSize.outdoor[Minimap.GetZoom()]
	local mapnote = self.CurrentStep["mapnote"]
	local mapzone = self.CurrentStep["mapzone"]

	if not mapnote or not mapzone then return end

	local zones = {GetMapZones(GetCurrentMapContinent())}
	if zones[GetCurrentMapZone()] ~= self.CurrentStep["mapzone"] then return end

	local nx,ny = Cartographer_Notes.getXY(mapnote)
	--	self:Echo(nx..' '..ny)
	local dist = Cartographer:GetDistanceToPoint(nx,ny,mapzone)
	if not dist then return end

	local diffX, diffY = px - (nx or 0), py - (ny or 0)
--	local dist = diffX*diffX + diffY*diffY

	if dist>=maxdist then
		ZygorGuidesViewerMapArrow:Show()
		ZygorGuidesViewerMapArrowFrame:Show()

		rad = -math.atan2(diffY*2/3, diffX) -(rotateMinimap and -MiniMapCompassRing:GetFacing() or 0)
		--	local direction = (rotateMinimap and -MiniMapCompassRing:GetFacing() or 0) + 1.5708
		--	local val = ((rad - direction)*_54_div_math_pi + 108) % 108

		--	ChatFrame1:AddMessage(rad)
		ZygorGuidesViewerMapArrow:SetPosition(0.085 - 0.07 * math.cos(rad), 0.085 - 0.07 * math.sin(rad), 0)
		ZygorGuidesViewerMapArrow:SetFacing(rad+1.57075)
		ZygorGuidesViewerMapArrowFrame:ClearAllPoints()
		ZygorGuidesViewerMapArrowFrame:SetPoint("CENTER","ZygorGuidesViewerMapArrow","CENTER",-60 * math.cos(rad), -60 * math.sin(rad), 0)
	end
end

function me:UpdateCartographerExport()
	if not Cartographer_Notes then return end

	Cartographer_Notes:MINIMAP_UPDATE_ZOOM()
	Cartographer_Notes:UpdateMinimapIcons()
	Cartographer_Notes:RefreshMap()
end

function me:InitializeDropDown()
	if not self.Guide then return end
	
	for i = 1, #self.Guide, 1 do
--		ChatFrame1:AddMessage(section)
		local info = {}
		info.text = self.Guide[i]["sectiontitle"]
		info.value = i
		info.func = ZGVFSectionDropDown_Func
		if (self.CurrentSectionNum == i) then
			info.checked = 1;
		else
			info.checked = nil;
		end
--		if (i == 1) then
--			info.isTitle = 1;
--		end
		UIDropDownMenu_AddButton(info);
	end
	UIDropDownMenu_SetText(self.CurrentSection["sectiontitle"], ZygorGuidesViewerFrame_SectionDropDown);
end

function me:SectionChange(name)
	ZygorGuidesViewer:SetSection(this.value)
	ZygorGuidesViewer:FocusStep(1)
	UIDropDownMenu_SetText(ZygorGuidesViewer.CurrentSection["sectiontitle"], ZygorGuidesViewerFrame_SectionDropDown);
end

function me:HighlightCurrentStep()
	if not ZygorGuidesViewerFrame or not ZygorGuidesViewerFrame:IsVisible() or not self.CurrentStepNum then return end
	ZygorGuidesViewerFrameStepsScrollFrameChildHighlightFrame:ClearAllPoints()
	ZygorGuidesViewerFrameStepsScrollFrameChildHighlightFrame:SetPoint("TOP","ZygorGuidesViewerFrameStep"..self.CurrentStepNum,"TOP",0,0)
	ZygorGuidesViewerFrameStepsScrollFrameChildHighlightFrame:SetAlpha(0.7)
	ZygorGuidesViewerFrameStepsScrollFrameChildHighlightFrame:SetHeight(getglobal("ZygorGuidesViewerFrameStep"..self.CurrentStepNum):GetHeight()+4)
end

function me:UpdateMiniFrame()
	if self.Guide and ZygorGuidesViewerMiniFrame then
		if not ZygorGuidesViewerMiniFrame:IsVisible() then return end
		local steptext
		local entries = {}
		local goal
		local i
		for i=1,#self.CurrentStep,1 do
			entries[i] = self.CurrentStep[i]
--			goal = self:FindMatchingGoal(entries[i])
--			if goal then entries[i] = entries[i] .. self:GetTextualCompletionGoalShort(goal) end
		end
		steptext = table.concat(entries,"|n")
		steptext = string.gsub(steptext,"\t([a-z]+\. )","\t|cffffff88%1|r")
		steptext = string.gsub(steptext,"\t","    ")
		ZygorGuidesViewerMiniFrame_Text:SetText(self.CurrentStepNum .. ". " .. string.gsub(steptext,"\t","  "))
		ZygorGuidesViewerMiniFrame_SectionTitle:SetText(self.CurrentSection["sectiontitle"])
		if self.CurrentStep.mapnote and self.CurrentStep.mapzone and self.db.profile.minimapnotedesc then
			local mapnote = self.MapNotes[self.CurrentStep.mapzone][self.CurrentStep.mapnote]
			if mapnote then
				local title = "|cffff77ff"..mapnote.title.."|r " or ""
				local info2 = mapnote.info2 and "|n|cffffbb77("..mapnote.info2..")|r " or ""
				local info = mapnote.info
				ZygorGuidesViewerMiniFrame_Divider2:Show()
				ZygorGuidesViewerMiniFrame_Divider2:ClearAllPoints()
				ZygorGuidesViewerMiniFrame_Divider2:SetPoint("TOPLEFT",ZygorGuidesViewerMiniFrame_Text,"TOPLEFT",0,-ZygorGuidesViewerMiniFrame_Text:GetHeight()-5)
				ZygorGuidesViewerMiniFrame_Divider2:SetPoint("RIGHT",ZygorGuidesViewerMiniFrame,"RIGHT",-5,0)

				ZygorGuidesViewerMiniFrame_Text:SetText(ZygorGuidesViewerMiniFrame_Text:GetText().."|n|n"..title.."|n"..info..info2)
			else
				ZygorGuidesViewerMiniFrame_Divider2:Hide()
			end
		else
			ZygorGuidesViewerMiniFrame_Divider2:Hide()
		end

		local s = self:GetTextualCompletion()
		if s then
			ZygorGuidesViewerMiniFrame_Text:SetText(ZygorGuidesViewerMiniFrame_Text:GetText()..s)
		end

		if (self.db.profile.autosizemini) then
			if ZygorGuidesViewerMiniFrame:GetLeft() then
				ZygorGuidesViewerMiniFrame:ClearAllPoints()
				ZygorGuidesViewerMiniFrame:SetPoint("TOPLEFT",nil,"TOPLEFT",ZygorGuidesViewerMiniFrame:GetLeft(),ZygorGuidesViewerMiniFrame:GetTop()-ZygorGuidesViewerMiniFrame:GetParent():GetHeight())
			end
			ZygorGuidesViewerMiniFrame:SetHeight(ZygorGuidesViewerMiniFrame_Text:GetHeight()+65)
		end
		if self.CurrentStep then
			if self.CurrentStep.mapzone then
				ZygorGuidesViewerMiniFrame_LocationLabel:Show()
				ZygorGuidesViewerMiniFrame_LocationText:Show()
				ZygorGuidesViewerMiniFrame_LocationText:SetText(self.CurrentStep["mapzone"])
			else
				ZygorGuidesViewerMiniFrame_LocationLabel:Hide()
				ZygorGuidesViewerMiniFrame_LocationText:Hide()
			end
			if self.CurrentStep.level then
				ZygorGuidesViewerMiniFrame_LevelLabel:Show()
				ZygorGuidesViewerMiniFrame_LevelText:Show()
				ZygorGuidesViewerMiniFrame_LevelText:SetText(self.CurrentStep.level)
			else
				ZygorGuidesViewerMiniFrame_LevelLabel:Hide()
				ZygorGuidesViewerMiniFrame_LevelText:Hide()
			end
			ZygorGuidesViewerMiniFrame_StepLabel:Show()
			ZygorGuidesViewerMiniFrame_StepText:Show()
			ZygorGuidesViewerMiniFrame_StepText:SetText(self.CurrentStepNum)
		else
			ZygorGuidesViewerMiniFrame_StepLabel:Hide()
			ZygorGuidesViewerMiniFrame_StepText:Hide()
		end
	else
		local faction = UnitFactionGroup("player")
		ZygorGuidesViewerMiniFrame_SectionTitle:Hide()
		ZygorGuidesViewerMiniFrame_LocationLabel:Hide()
		ZygorGuidesViewerMiniFrame_LevelLabel:Hide()
		ZygorGuidesViewerMiniFrame_StepLabel:Hide()
		ZygorGuidesViewerMiniFrame_PrevButton:Hide()
		ZygorGuidesViewerMiniFrame_NextButton:Hide()
		ZygorGuidesViewerMiniFrame_MissingText:SetText(L['missing_text_short'])
	end
--	ZygorGuidesViewerMiniFrame:SetFrameLevel(30)
end

function me:ToggleFilterNotes()
	self.db.profile["filternotes"] = not self.db.profile["filternotes"]
	self:UpdateMainFrame()
	Cartographer_Notes:MINIMAP_UPDATE_ZOOM()
	Cartographer_Notes:UpdateMinimapIcons()
	Cartographer_Notes:RefreshMap()
end

function me:UpdateMainFrame()
	if not ZygorGuidesViewerFrame then return end

	if not ZygorGuidesViewerFrame:IsVisible() then return end

	if self.Guide then
		ZygorGuidesViewerFrameStepsScrollFrame:Show()
		ZygorGuidesViewerFrameStepsScrollFrameChildHighlightFrame:Show()
		ZygorGuidesViewerFrame_HideCompleted:Show()
	else
		local faction = UnitFactionGroup("player")
		ZygorGuidesViewerFrame_EmptyText:SetText(L['missing_text_long'])
		ZygorGuidesViewerFrame_SectionLabel:Hide()
		ZygorGuidesViewerFrame_SectionDropDown:Hide()
		ZygorGuidesViewerFrame_LocationLabel:Hide()
		ZygorGuidesViewerFrame_HideCompleted:Hide()
		ZygorGuidesViewerFrame_LevelLabel:Hide()
		ZygorGuidesViewerFrame_StepLabel:Hide()
		return
	end
		
	local Section = self.CurrentSection
	if not Section then return end

	local stepnum,stepdata

	ZygorGuidesViewerFrame_HideCompletedText:SetText("show all dots")
	ZygorGuidesViewerFrame_HideCompleted:SetChecked(not self.db.profile["filternotes"])

	local last = nil
	local frame,frametext
	local stepnum,stepdata
	for stepnum,stepdata in pairs(Section["steps"]) do
		if stepnum>self.StepLimit then break end

		frame = getglobal("ZygorGuidesViewerFrameStep"..stepnum)
		if not frame then
			frame = CreateFrame ("Button", "ZygorGuidesViewerFrameStep"..stepnum, ZygorGuidesViewerFrameStepsScrollFrameChild, "ZGVFStep")
			frame:SetWidth(290)
		end

	--	if self.db.profile["hidecompleted"] and stepnum<self.CurrentStepNum then
	--		frame:Hide()
	--	else
		text = getglobal("ZygorGuidesViewerFrameStep"..stepnum.."_Text")
		if stepnum<self.CurrentStepNum then
			frame:SetAlpha(0.4)
		else
			frame:SetAlpha(1.0)
		end
		steptext = table.concat(stepdata,"|n")
		steptext = string.gsub(steptext,"\t([a-z]+\. )","\t|cffffff88%1|r")
		steptext = string.gsub(steptext,"\t","    ")
		text:SetText(stepnum .. ". " .. steptext)
		text:SetWidth(290)
		frame:Show()
		frame:SetHeight(text:GetStringHeight())
		frame:ClearAllPoints()
		if last then
			frame:SetPoint("TOPLEFT",getglobal("ZygorGuidesViewerFrameStep"..last),"BOTTOMLEFT",0,-15)
		else
			frame:SetPoint("TOPLEFT","ZygorGuidesViewerFrameStepsScrollFrameChild","TOPLEFT",0,-15)
		end
		frame.step = stepnum
		frame:SetScript("OnClick", function (this)
			ZygorGuidesViewer:FocusStep(this.step)
		end)
		--text:Show()
		last = stepnum
	--	end
	end

	for stepnum = last+1, self.StepLimit, 1 do
		--local text = getglobal("ZygorGuidesViewerFrame_StepText" .. stepnum)
		--if text then text:Hide() end
		frame = getglobal("ZygorGuidesViewerFrameStep"..stepnum)
		if frame then frame:Hide() end
	end

	if self.CurrentStep then
		if self.CurrentStep.mapzone then
			ZygorGuidesViewerFrame_LocationLabel:Show()
			ZygorGuidesViewerFrame_LocationText:Show()
			ZygorGuidesViewerFrame_LocationText:SetText(self.CurrentStep["mapzone"])
		else
			ZygorGuidesViewerFrame_LocationLabel:Hide()
			ZygorGuidesViewerFrame_LocationText:Hide()
		end
		if self.CurrentStep.level then
			ZygorGuidesViewerFrame_LevelLabel:Show()
			ZygorGuidesViewerFrame_LevelText:Show()
			ZygorGuidesViewerFrame_LevelText:SetText(self.CurrentStep.level)
		else
			ZygorGuidesViewerFrame_LevelLabel:Hide()
			ZygorGuidesViewerFrame_LevelText:Hide()
		end
		ZygorGuidesViewerFrame_StepLabel:Show()
		ZygorGuidesViewerFrame_StepText:Show()
		ZygorGuidesViewerFrame_StepText:SetText(self.CurrentStepNum)
	else
		ZygorGuidesViewerFrame_StepLabel:Hide()
		ZygorGuidesViewerFrame_StepText:Hide()
	end

	self:HighlightCurrentStep()
	self:ScrollToCurrentStep()

	-- hide/show scroll filler : GetVerticalScrollRange() won't return proper values yet... just base it on emptiness for now.
--[[
	self:Debug(ZygorGuidesViewerFrameStepsScrollFrameChild:GetHeight())
	if ZygorGuidesViewerFrameStepsScrollFrameChild:GetHeight()<200 then
		ZygorGuidesViewerFrame_ScrollFill:Hide()
	else
		ZygorGuidesViewerFrame_ScrollFill:Show()
	end
]]--
end

function me:ScrollToCurrentStep()
	if self.ForceScrollToCurrentStep then
		self:Debug("Scrolling to: ")
		self:Debug(self.CurrentStepNum)
		self.ForceScrollToCurrentStep = false
		if self.CurrentStepNum then
			local height=0, stepnum
			for stepnum = 1, self.CurrentStepNum-1, 1 do
				height = height + getglobal("ZygorGuidesViewerFrameStep"..stepnum):GetHeight()+15
			end
--			self:Debug(height)
		--	local y = 624 - getglobal("ZygorGuidesViewerFrameStep"..self.CurrentStepNum):GetTop()+ZygorGuidesViewerFrameStepsScrollFrame:GetVerticalScroll()
		--	if y < 0 then y = 0 end
			local current = ZygorGuidesViewerFrameStepsScrollFrame:GetVerticalScroll()
--			self:Debug(current)
			if current<height and height-current+getglobal("ZygorGuidesViewerFrameStep"..self.CurrentStepNum):GetHeight()<ZygorGuidesViewerFrameStepsScrollFrame:GetHeight() then return end
			local range = ZygorGuidesViewerFrameStepsScrollFrame:GetVerticalScrollRange()
			if height > range and range>0 then height = range end
			ZygorGuidesViewerFrameStepsScrollFrame:SetVerticalScroll(height)
		end
	else
		self.ForceScrollToCurrentStep = true
	end
end

function me:ToggleFrame()
	if ( ZygorGuidesViewerFrame:IsVisible() or ZygorGuidesViewerMiniFrame:IsVisible()) then
		self.db.profile["visible"] = false
		ZygorGuidesViewerMiniFrame:Hide()
		HideUIPanel(ZygorGuidesViewerFrame)
	else
		self.db.profile["visible"] = true
		if self.db.profile["minimode"] then
			ZygorGuidesViewerMiniFrame:Show()
		else
			ShowUIPanel(ZygorGuidesViewerFrame)
		end
	end
end

function me:ToggleMini()
	self.db.profile["minimode"] = not self.db.profile["minimode"]
	if self.db.profile["minimode"] then
		HideUIPanel(ZygorGuidesViewerFrame)
		local x,y = ZygorGuidesViewerFrame:GetRight(),ZygorGuidesViewerFrame:GetTop()
		ZygorGuidesViewerMiniFrame:ClearAllPoints()
		ZygorGuidesViewerMiniFrame:SetPoint("TOPRIGHT","UIParent","BOTTOMLEFT", x,y-11)
		ZygorGuidesViewerMiniFrame:Show()
	else
		ZygorGuidesViewerMiniFrame:Hide()
		ZygorGuidesViewerFrame:ClearAllPoints()
		local x,y = ZygorGuidesViewerMiniFrame:GetRight(),ZygorGuidesViewerMiniFrame:GetTop()
		ZygorGuidesViewerFrame:SetPoint("TOPRIGHT","UIParent","BOTTOMLEFT", x,y+11)
		ShowUIPanel(ZygorGuidesViewerFrame)
	end		
end

function me:SkipStep(delta,click)
	local i = self.CurrentStepNum+delta
	if i<1 then
		if self.CurrentSectionNum==1 then return end		-- first section? bail.
		if self.CurrentSection.defaultfor then return end		-- no skipping back from a starter section.

		local x,race = UnitRace("player")
		local default = self:FindDefaultSection()

		self:SetSection(self.CurrentSectionNum-1)
		if self.CurrentSection.defaultfor and self.CurrentSection.defaultfor ~= race then		-- wrong default section? move to ours.
			self:SetSection(default)
		end
		i=#(self.CurrentSection["steps"])
	end
	if i>#self.CurrentSection["steps"] then
		if self.CurrentSectionNum==#self.Guide then return end
		self:SetSection(self.CurrentSection.nextsection or self.CurrentSectionNum+1)
		i=1
	end
	if (click) then self.LastSkip = delta else self.LastSkip=0 end
	self:FocusStep(i)
end

function me:OpenOptions()
	self:OpenConfigMenu()
end

function me:Print(s)
	ChatFrame1:AddMessage("Zygor's Guides: "..s)
end
















function me:GetIconScale()
	return self.db.profile.iconScale
end
function me:SetIconScale(value)
	self.db.profile.iconScale = value
	Cartographer_Notes:MINIMAP_UPDATE_ZOOM()
	Cartographer_Notes:UpdateMinimapIcons()
end

function me:GetIconAlpha()
	return self.db.profile.iconAlpha
end
function me:SetIconAlpha(value)
	self.db.profile.iconAlpha = value
	Cartographer_Notes:MINIMAP_UPDATE_ZOOM()
	Cartographer_Notes:UpdateMinimapIcons()
end

function me:IsShowingMinimapIcons()
	return self.db.profile.minicons
end
function me:ToggleShowingMinimapIcons()
	self.db.profile.minicons = not self.db.profile.minicons
	Cartographer_Notes:MINIMAP_UPDATE_ZOOM()
	Cartographer_Notes:UpdateMinimapIcons()
end

function me:IsShowingMapIcons()
	return self.db.profile.mapicons
end
function me:ToggleShowingMapIcons()
	self.db.profile.mapicons = not self.db.profile.mapicons
end

-- icon handlers:

function me:GetNoteScaling(zone,id,data)
	return self.db.profile.iconScale
end

function me:IsNoteHidden(zone,id,data)
	return self.db.profile.filternotes and (not self.CurrentStep or not self.CurrentStep.mapnote or (id~=self.CurrentStep.mapnote) or (zone~=self.CurrentStep.mapzone))
end

function me:IsMiniNoteHidden(zone,id,data)
	return not self.db.profile.minicons or (self.db.profile.filternotes and ((id~=self.CurrentStep.mapnote) or (zone~=self.CurrentStep.mapzone)))
end

function me:GetNoteTransparency(zone,id,data)
	return self.db.profile.iconAlpha
end

function me:GetNoteIcon(zone,id,data)
--	return (not self.db.profile.filternotes and self.CurrentStep and (id==self.CurrentStep.mapnote) and (zone==self.CurrentStep.mapzone)) and "hilite" or data.icon
	return (self.CurrentStep and (id==self.CurrentStep.mapnote) and (zone==self.CurrentStep.mapzone)) and (data.icon=="Square" and "hilitesquare" or "hilite") or data.icon
end


function me:MINIMAP_UPDATE_ZOOM()
	self:UpdateMinimapArrow(false)
end

function me:CHAT_MSG_SYSTEM(sender,event,text)
	local zone = string.match(text,L["home_trigger"])
	if zone then self.recentlyHomeChanged = true end
end

function me:UI_INFO_MESSAGE(sender,event,text)
self:Debug(text)
	local zone = string.match(text,L["flightpath_trigger"])
	if zone then self.recentlyDiscoveredFlightpath = true end
end

function me:QUEST_WATCH_UPDATE(sender,event,index)
	self:Debug('QUEST_WATCH_UPDATE '..index);
	if (GetNumQuestLeaderBoards(index)>1) then
		self:Debug('QUEST_WATCH_UPDATE quest has multiple goals, queuing for QUEST_LOG_UPDATE');
		-- there's many goals here, we need to know which was completed. Queue it.
		self.questWatchUpdated[#self.questWatchUpdated+1] = index;
		-- ... and wait for a QUEST_LOG_UPDATE
	else
		self:Debug('QUEST_WATCH_UPDATE quest has one goal, but queuing for QUEST_LOG_UPDATE anyway');
		self.questWatchUpdated[#self.questWatchUpdated+1] = index;
--		self:Debug('Updating quest list from WATCH_UPDATE');
--		self:CacheQuestLog()
--		self:RecordData(index,'goal',1)
--		self:RefreshPlugins()
	end
end

function me:QUEST_COMPLETE(sender,event,arg1)
--	self:Debug('QUEST_COMPLETE: '..self:nilsafe(arg1));
	self.completingQuest = true
--	self:RecordData(self.questIndicesByTitle[GetTitleText()], 'finish', QuestFrameNpcNameText:GetText());
end

me.questWatchUpdated = {}

function me:QUEST_FINISHED(sender,event,arg1)
	self:Debug('QUEST_FINISHED: '..self:nilsafe(arg1));
end

function me:QUEST_ITEM_UPDATE(sender,event,arg1)
	self:Debug('QUEST_ITEM_UPDATE: '..self:nilsafe(arg1));
end

function me:UNIT_QUEST_LOG_CHANGED(sender,event,unit)
	self:Debug('UNIT_QUEST_LOG_CHANGED for '..self:nilsafe(unit));
	self.QuestLogChanged = true
end

function me:QUEST_LOG_UPDATE()
	self:Debug('QUEST_LOG_UPDATE');
--	if 1 then self:Debug('**BREAK**'); return end
	local recorded = nil
	self:CacheQuestLog()
	if self.QuestLogChanged or recorded or self.StaleMaps then
		self:Debug('Quest log changed? Refreshing plugins.')
		self.QuestLogChanged = nil
		self.StaleMaps = nil
	end

	self:TryToCompleteStep()
--	self:Debug('QUEST_LOG_UPDATE done.')
end

function me:CacheQuestLog()
	--self:Debug('CacheQuestLog: '..zone..'/'..subzone);
	--if not zone or zone=='' then return nil end

--	if 1 then self:Debug('**BREAK**'); return end
	local time = GetTime()
	if time - self.QuestCacheTime < 1 then
		self.QuestCacheUndertimeRepeats = self.QuestCacheUndertimeRepeats + 1
		if self.QuestCacheUndertimeRepeats > 10 then return end
	else
		-- overtime; everything in order.
		self.QuestCacheUndertimeRepeats = 0
		self.QuestCacheTime = time
	end
	self:Debug("CacheQuestLog after ".. time - self.QuestCacheTime)

	local iNumEntries, iNumQuests = GetNumQuestLogEntries();
	local collecting = true;
	self.oldQuestIndicesByTitle={}
	local oldn=0
	for q,qi in pairs(self.questIndicesByTitle) do self.oldQuestIndicesByTitle[q]=qi; oldn=oldn+1; end
	self.quests = {}
	self.questIndicesByTitle = {}

	--local selected = GetQuestLogSelection();

	for i = 1, iNumEntries, 1 do
		local strQuestLogTitleText, strQuestLevel, strQuestTag, numPlayers, isHeader, isCollapsed, isComplete = GetQuestLogTitle(i);

		if not isHeader then
			local goals,goalsNamed = self:GetQuestLeaderBoards(i);

			local quest = {
				title = strQuestLogTitleText,
				level = strQuestLevel,
				--objective = obj,
				--description = desc,
				complete = isComplete,
				goals = goals,
				goalsNamed = goalsNamed,
			};
			self.quests[i] = quest;
			self.questIndicesByTitle[strQuestLogTitleText] = i;
			if oldn>0 and not self.oldQuestIndicesByTitle[strQuestLogTitleText] then self:NewQuestEvent(strQuestLogTitleText) end
			
			self:Debug('collected: '..strQuestLogTitleText..' as '..i..' size '..#self.quests);
	--		end
		end
	end

	if self.oldQuestIndicesByTitle then for title,qi in pairs(self.oldQuestIndicesByTitle) do if not self.questIndicesByTitle[title] then self:LostQuestEvent(title) end end end

	return self.quests;
end

function me:ParseLeaderBoard(leaderboard)
	local i, j, strItemName, iNumItems, iNumNeeded = string.find(leaderboard, "(.*):%s*([%d]+)%s*/%s*([%d]+)");
	if (strItemName) then
		return strItemName, iNumItems, iNumNeeded;
	else
		return leaderboard, 1, 1
	end
end

function me:CleanGoal(goal)
	local cleanGoal = string.match(goal,"(.*) slain")
	if cleanGoal then return cleanGoal else return goal end
end

function me:GetQuestLeaderBoards(questindex)
	local iGoals = GetNumQuestLeaderBoards(questindex);
	local goals = {}
	local goalsNamed = {}
	if tonumber(iGoals)>0 then
		for g = 1, iGoals, 1 do
			local leaderboard,type,complete = GetQuestLogLeaderBoard(g,questindex)
			local item,num,needed = self:ParseLeaderBoard(leaderboard);
			goals[g] = { item=item, num=num, needed=needed, type=type, complete=complete, leaderboard=leaderboard };
			goalsNamed[item] = goals[g]
		end
	end
	return goals,goalsNamed
end

function me:FindCompletedGoal(questindex,a,b)
	self:Debug("Finding completed goal: "..questindex..","..self:nilsafe(a)..","..self:nilsafe(b));
	local newgoals = self:GetQuestLeaderBoards(questindex);
	for oldg,oldgoal in pairs(self.quests[questindex].goals) do
		self:Debug('#'..oldg..' '..oldgoal.item..' = '..oldgoal.num..'->'..newgoals[oldg].num);
		if (oldgoal.num<newgoals[oldg].num) then
			self:Debug('#'..oldg..' changed');
			return oldg, oldgoal.item;
		end
	end
	return 1;
end

function me:NewQuestEvent(questTitle)
	self.recentlyAcceptedQuests[questTitle]=true
	self:Debug("New Quest: "..questTitle)
end

function me:LostQuestEvent(questTitle)
	self:Debug("Lost Quest: "..questTitle)
	if self.completingQuest then
		self.recentlyCompletedQuests[questTitle]=true
		self.completingQuest = nil
	end
end

function me:GetQuestTag (questindex)
	local title, level = GetQuestLogTitle(questindex);
	return title .. ' [' .. level .. ']';
end

function me:Dump(s)
	if self.db.profile.debug then Rock("LibRockConsole-1.0"):PrintLiteral(s) end
end