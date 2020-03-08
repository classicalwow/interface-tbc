﻿assert(Cartographer, "Cartographer not found!")
local Cartographer = Cartographer
local revision = tonumber(string.sub("$Revision: 78706 $", 12, -3))
if revision > Cartographer.revision then
	Cartographer.version = "r" .. revision
	Cartographer.revision = revision
	Cartographer.date = string.sub("$Date: 2008-07-18 19:25:23 -0400 (Fri, 18 Jul 2008) $", 8, 17)
end

local L = Rock("LibRockLocale-1.0"):GetTranslationNamespace("Cartographer_Professions")
L:AddTranslations("enUS", function() return {
	["Professions"] = true,
	["Always"] = true,
	["With Profession"] = true,
	["When active"] = true,
	["Never"] = true,
	["Stub for loading Cartographer module addons based on your professions."] = true,
	["Unable to load addon `%s': %s"] = true,
	["Load all professions"] = true,
	["This option will load all the profession modules including those you currently dont know."] = true,
} end)

L:AddTranslations("zhTW", function() return {
	["Professions"] = "專業技能",
	["Always"] = "永遠",
	["With Profession"] = "配合專業技能",
	["When active"] = "當啟用時",
	["Never"] = "絕不",
	["Stub for loading Cartographer module addons based on your professions."] = "依據你的專業技能載入 Cartographer 模組。",
	["Unable to load addon `%s': %s"] = "無法載入插件「%s」: %s",
	["Load all professions"] = "載入所有專業技能",
	["This option will load all the profession modules including those you currently dont know."] = "載入所有專業技能模組，不管你學過與否。",
} end)

L:AddTranslations("zhCN", function() return {
	["Professions"] = "专业技能",
	["Always"] = "总是",
	["With Profession"] = "配合专业技能",
	["When active"] = "当启用时",
	["Never"] = "从不",
	["Stub for loading Cartographer module addons based on your professions."] = "根据你的专业技能加载 Cartographer 模块。",
	["Unable to load addon `%s': %s"] = "无法加载插件 '%s'：%s",
	["Load all professions"] = "加载所有专业技能",
	["This option will load all the profession modules including those you currently dont know."] = "加载所有专业技能模块，不管你有没有学习。",
} end)

local mod = Cartographer:NewModule('Professions', 'LibRockEvent-1.0', 'LibRockConsole-1.0')

local bs = {
	["Mining"] = GetSpellInfo(2575), --2575 Mining
	["Herbalism"] = GetSpellInfo(9134), -- 9134 Herbalism
	["Fishing"] = GetSpellInfo(7620), -- 7620 Fishing
	["Engineering"] = GetSpellInfo(4036), -- 4036 Engineering
}

function mod:OnInitialize()
	self.name    = L["Professions"]
	self.title   = L["Professions"]
	self.author  = 'Chris "kergoth" Larson'
	self.notes   = L["Stub for loading Cartographer module addons based on your professions."]
	self.email   = 'clarson@kergoth.com'
	self.website = nil
	self.version = nil
	-- adjustment for load all option
    self.db = Cartographer:AcquireDBNamespace("Professions")
	Cartographer:RegisterDefaults("Professions", "profile", {
		profs = {},
	})


	local opts = {
		name = L["Professions"],
		desc = L["Stub for loading Cartographer module addons based on your professions."],
		type = 'group',
		args = {
			toggle = {
				name = Cartographer.L["Enabled"],
				desc = Cartographer.L["Suspend/resume this module."],
				type  = 'toggle',
				order = -1,
				get   = function() return Cartographer:IsModuleActive(self) end,
				set   = function() Cartographer:ToggleModuleActive(self) end,
			},
		},
		handler = self,
	}
	for n=1,GetNumAddOns() do
		local pipometa = GetAddOnMetadata(n, 'X-Cartographer-Prof')
		if pipometa and bs[pipometa] then
			local profLocale = bs[pipometa]
			if not self.db.profile.profs[profLocale] then
				self.db.profile.profs[profLocale] = "With Profession"
			end
			opts.args[profLocale] = {
				name = profLocale,
				desc = profLocale,
				type = 'text',
				get = function()
					return self:LoadProfPref(profLocale)
				end,
				set = function(v)
					self:SetProfLoad(profLocale,v)
				end,
				disabled = function() return not Cartographer:IsModuleActive(self) end,
				validate = {
					["Always"] = L["Always"],
					["With Profession"] = L["With Profession"],
					["When active"] = L["When active"],
					["Never"] = L["Never"]
				},
			}
		end
	end
	Cartographer.options.args.Professions = opts
	self.addons = {}
end

function mod:OnEnable()
	self:AddEventListener('SKILL_LINES_CHANGED')
	self:AddEventListener('MINIMAP_UPDATE_TRACKING')
	self:SKILL_LINES_CHANGED()
end

function mod:OnDisable()
	for k,v in pairs(self.addons) do
		Cartographer:ToggleModuleActive(v,false)
	end
end

function mod:SetProfLoad(prof,v)
	self.db.profile.profs[prof] = v
	self:SKILL_LINES_CHANGED()
end

function mod:LoadProfPref(v)
	if not self.db.profile.profs[v] then
		self.db.profile.profs[v] = "With Profession"
	end
	return self.db.profile.profs[v]
end

function mod:BootProfession(n,name)
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(n)
	if not IsAddOnLoaded(n) then
		if enabled and loadable then
			local loaded, reason = LoadAddOn(n)
			if not loaded then
				self:Print(L["Unable to load addon `%s': %s"], name, reason)
			end
		end
	end
end

local textureToProfessionMap = {
	["Interface\\Icons\\Spell_Nature_Earthquake"] = bs["Mining"],
	["Interface\\Icons\\INV_Misc_Flower_02"] = bs["Herbalism"],
	["Interface\\Icons\\INV_Misc_Fish_02"] = bs["Fishing"],
}

function mod:MINIMAP_UPDATE_TRACKING()
	local track = GetTrackingTexture()
	for k,v in pairs(self.addons) do
		if self.db.profile.profs[k] == "When active" then
			Cartographer:ToggleModuleActive(v, k == textureToProfessionMap[track])
		end
	end
end

function mod:SKILL_LINES_CHANGED()
	local skills = {}
	for i=1,GetNumSkillLines() do
		local skillname, isHeader = GetSkillLineInfo(i)
		if not isHeader and skillname then
			skills[skillname] = true
		end
	end

	for n=1,GetNumAddOns() do
		local pipometa = GetAddOnMetadata(n, 'X-Cartographer-Prof')
		if pipometa and bs[pipometa] then
			local l = self.db.profile.profs[bs[pipometa]]
			if l == "Always" then
				self:BootProfession(n)
			elseif l == "With Profession" or l == "When active" then
				local localProf = bs[pipometa]
				for skillname in pairs(skills) do
					if localProf == skillname then
						self:BootProfession(n)
					end
				end
			end
		end
	end

	for k,v in pairs(self.addons) do
		if self.db.profile.profs[k] == "Always" then
			Cartographer:ToggleModuleActive(v,true)
		elseif self.db.profile.profs[k] == "With Profession" and skills[k] then
			Cartographer:ToggleModuleActive(v,true)
		elseif self.db.profile.profs[k] == "When active" and skills[k] then
			local track = GetTrackingTexture()
			if textureToProfessionMap[track] then
				Cartographer:ToggleModuleActive(v, k == textureToProfessionMap[track])
			end
		else
			Cartographer:ToggleModuleActive(v,false)
		end
	end
end

