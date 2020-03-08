
assert(oRA, "oRA not found!")

------------------------------
--      Are you local?      --
------------------------------

local mod = nil

local L = AceLibrary("AceLocale-2.2"):new("oRAOptions")
local Tablet = AceLibrary("Tablet-2.0")
local waterfall = AceLibrary:HasInstance("Waterfall-1.0") and AceLibrary("Waterfall-1.0") or nil

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	tablethint = "|cffeda55fShift-Click|r to open oRA Configuration. |cffeda55fCtrl-Alt-Click|r to disable oRA completely. |cffeda55fAlt-Drag|r to move MT,PT and the monitors.",
	tablethint_disabled = "|cffeda55fClick|r to enable.",
	["oRA is currently disabled."] = true,
	["oRA Options"] = true,
	["Hidden"] = true,
	["Shown"] = true,
	["Minimap"] = true,
	["Toggle the minimap button."] = true,
} end)

L:RegisterTranslations("koKR", function() return {
	tablethint = "oRA 환경설정을 열려면 |cffeda55fSHIFT-클릭|r하세요. oRA를 사용하지 않으려면 |cffeda55fCTRL-ALT-클릭|r하세요. 메인탱커와 플레이어탱커, 각종 현황창을 이동하려면 |cffeda55fALT-드래그|r하세요.",
	tablethint_disabled = "|cffeda55f클릭시|r 사용합니다.",
	["oRA is currently disabled."] = "oRA 는 현재 사용중지 중입니다.",
	["oRA Options"] = "oRA 설정",
	["Hidden"] = "숨김",
	["Shown"] = "표시",
	["Minimap"] = "미니맵",
	["Toggle the minimap button."] = "미니맵 버튼 표시를 선택합니다.",
} end)


L:RegisterTranslations("zhCN", function() return {
	tablethint = "|cffeda55fCtrl-Alt-点击|r 来关闭 oRA。|cffeda55f按住 Alt-拖动|r来移动 MT、PT 和监视框架。",
	tablethint_disabled = "|cffeda55f点击|r 激活。",
	["oRA is currently disabled."] = "oRA 目前已关闭。",
	["oRA Options"] = "oRA 选项",
	["Hidden"] = "隐藏",
	["Shown"] = "显示",
	["Minimap"] = "小地图",
	["Toggle the minimap button."] = "显示小地图图标。",
} end)

L:RegisterTranslations("zhTW", function() return {
	tablethint = "|cffeda55fCtrl-Alt-點擊|r 可關閉 oRA。 |cffeda55fAlt-拖曳|r 可移動 MT、PT 及監視框架。",
	tablethint_disabled = "oRA 目前已關閉。|cffeda55f點擊|r可啟動 oRA。",
	["oRA is currently disabled."] = "oRA 目前已關閉",
	["oRA Options"] = "oRA 選項",
	["Hidden"] = "隱藏",
	["Shown"] = "顯示",
	["Minimap"] = "小地圖",
	["Toggle the minimap button."] = "顯示小地圖按鈕",
} end)

L:RegisterTranslations("frFR", function() return {
	tablethint = "|cffeda55fShift-Clic|r pour configurer oRA. |cffeda55fCtrl-Alt-Clic|r pour désactiver complètement oRA. Maintenez la touche Alt enfoncée pour déplacer les cadres des MTs & des PTs ainsi que les moniteurs.",
	tablethint_disabled = "|cffeda55fCliquez|r pour l'activer.",
	["oRA is currently disabled."] = "oRA est actuellement désactivé.",
	["oRA Options"] = "Options concernant oRA.",
	["Hidden"] = "Masqué",
	["Shown"] = "Affiché",
	["Minimap"] = "Minicarte",
	["Toggle the minimap button."] = "Affiche ou non le bouton de la minicarte.",
} end)

L:RegisterTranslations("deDE", function() return {
	tablethint = "|cffeda55fShift+Klicken|r um die oRA Konfiguration zu öffnen. |cffeda55fStrg+Alt+Klicken|r um oRA zu deaktivieren. |cffeda55fAlt+Drag|r zum verschieben der MT, PT und Fenster.",
	tablethint_disabled = "|cffeda55fKlicken|r um oRA zu aktivieren.",
	["oRA is currently disabled."] = "oRA ist deaktiviert.",
	["oRA Options"] = "oRA Optionen",
	["Hidden"] = "Ausblenden",
	["Shown"] = "Anzeigen",
	["Minimap"] = "Minikarte",
	["Toggle the minimap button."] = "Minikarten Button ein-/ausblenden.",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local deuce = oRA:NewModule("Options Menu")
deuce.hasFuBar = IsAddOnLoaded("FuBar") and FuBar
deuce.consoleCmd = not deuce.hasFuBar and "minimap"
deuce.consoleOptions = not deuce.hasFuBar and {
	type = "toggle",
	name = L["Minimap"],
	desc = L["Toggle the minimap button."],
	get = function() return mod.minimapFrame and mod.minimapFrame:IsVisible() or false end,
	set = function(v) if v then mod:Show() else mod:Hide() end end,
	map = {[false] = L["Hidden"], [true] = L["Shown"]},
	hidden = function() return deuce.hasFuBar and true end,
}

----------------------------
--      FuBar Plugin      --
----------------------------

mod = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceConsole-2.0", "AceDB-2.0", "FuBarPlugin-2.0")
mod.name = "FuBar - oRA"

mod.hasNoColor = true
mod.hasIcon = "Interface\\AddOns\\oRA2\\Icons\\core_enabled"
mod.defaultMinimapPosition = 180
mod.hideWithoutStandby = true
mod.clickableTooltip = true

-----------------------------
--      Icon Handling      --
-----------------------------

function mod:OnInitialize()
	self:RegisterDB("oRAFubarDB")

	-- XXX total hack
	self.OnMenuRequest = oRA.consoleOptions
	local args = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(mod)
	for k, v in pairs(args) do
		if self.OnMenuRequest.args[k] == nil then
			self.OnMenuRequest.args[k] = v
		end
	end
	-- XXX end hack

	if waterfall then
		waterfall:Register("oRA2","aceOptions", oRA.consoleOptions, "colorR", .6, "colorG", .5, "colorB", .8)
	end
end

function mod:OnEnable()
	self:RegisterEvent("oRA_CoreEnabled", "CoreState")
	self:RegisterEvent("oRA_CoreDisabled", "CoreState")
	self:RegisterEvent("oRA_UpdateConfigGUI", "Update")

	self:CoreState()
end

function mod:CoreState()
	if oRA:IsActive() then
		self:SetIcon("Interface\\AddOns\\oRA2\\Icons\\core_enabled")
	else
		self:SetIcon("Interface\\AddOns\\oRA2\\Icons\\core_disabled")
	end

	self:UpdateTooltip()
end

-----------------------------
--      FuBar Methods      --
-----------------------------

function mod:OnTooltipUpdate()
	if oRA:IsActive() then
		Tablet:SetHint(L["tablethint"])
		for n, m in oRA:IterateModules() do
			if m.OnTooltipUpdate and oRA:IsModuleActive(m) then
				m:OnTooltipUpdate()
			end
		end
	else
		local cat = Tablet:AddCategory("colums", 1)
		cat:AddLine("text", L["oRA is currently disabled."], "func", mod.OnClick, "arg1", mod)
		Tablet:SetHint(L["tablethint_disabled"])
	end
end

function mod:OnClick()
	if oRA:IsActive() then
		if IsControlKeyDown() and IsAltKeyDown() then
			oRA:ToggleActive(false)
		elseif IsShiftKeyDown() and waterfall then
			waterfall:Open("oRA2")
		end
	else
		oRA:ToggleActive(true)
	end

	self:UpdateTooltip()
end

