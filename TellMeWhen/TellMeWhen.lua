-- --------------------------------------
-- TellMeWhen
-- by Nephthys <Drunken Monkeys> of Hyjal
-- --------------------------------------



-- -------------
-- ADDON GLOBALS
-- -------------

TELLMEWHEN_VERSION = "1.0";
TELLMEWHEN_MAXGROUPS = 4;
TELLMEWHEN_MAXROWS = 7;
TELLMEWHEN_ICONSPACING = 2;
TELLMEWHEN_UPDATE_INTERVAL = 0.2;

TellMeWhen_Icon_Defaults = {
	Enabled				= true,
	Name				= "",
	Type				= "",
	CooldownType		= "spell",
	Unit				= "player",
	BuffShowWhen		= "present",
	CooldownShowWhen	= "usable",
	BuffOrDebuff		= "HELPFUL",
	OnlyMine			= false,
	WpnEnchantType		= "mainhand",
};

TellMeWhen_Group_Defaults = {
	Enabled			= false,
	Scale			= 2.0,
	Rows			= 1,
	Columns			= 4,
	Icons			= {},
	OnlyInCombat	= false,
};
for iconID = 1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
	TellMeWhen_Group_Defaults["Icons"][iconID] = TellMeWhen_Icon_Defaults;
end;

TellMeWhen_Defaults = {
	Version 		= 	TELLMEWHEN_VERSION,
	Locked 			= 	false,
	Groups 			= 	{}, 
};
for groupID = 1, TELLMEWHEN_MAXGROUPS do
	TellMeWhen_Defaults["Groups"][groupID] = TellMeWhen_Group_Defaults;
end

--	TellMeWhen_Settings_Metatable = {};
--	TellMeWhen_Settings_Metatable.__index = TellMeWhen_Defaults;

function TellMeWhen_Test(stuff)
	if ( stuff ) then
		DEFAULT_CHAT_FRAME:AddMessage("TellMeWhen test: "..stuff);
	else
		DEFAULT_CHAT_FRAME:AddMessage("TellMeWhen test: "..this:GetName());
	end
end




-- ---------------
-- EXECUTIVE FRAME
-- ---------------

function TellMeWhen_OnEvent(self, event)
	if ( event == 'VARIABLES_LOADED' ) then
		if ( not TellMeWhen_Settings ) then
			TellMeWhen_Settings = CopyTable(TellMeWhen_Defaults);
		end
--		setmetatable(TellMeWhen_Settings, TellMeWhen_Settings_Metatable);
		SlashCmdList["TELLMEWHEN"] = TellMeWhen_SlashCommand;
		SLASH_TELLMEWHEN1 = "/tellmewhen";
		SLASH_TELLMEWHEN2 = "/tmw";
	elseif ( event == "PLAYER_LOGIN" ) then
		-- initialization needs to be late enough that the icons can find their textures
		TellMeWhen_Update();
	end
end

function TellMeWhen_Update()
	for groupID = 1, TELLMEWHEN_MAXGROUPS do
		TellMeWhen_Group_Update(groupID);
	end
end

do
	executiveFrame = CreateFrame("Frame", "TellMeWhen");
	executiveFrame:SetScript("OnEvent", TellMeWhen_OnEvent);
	executiveFrame:RegisterEvent("VARIABLES_LOADED");
	executiveFrame:RegisterEvent("PLAYER_LOGIN");
	executiveFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
end



-- -----------
-- GROUP FRAME
-- -----------

function TellMeWhen_Group_OnEvent(self, event)
	-- called if OnlyInCombat true for this group
	if ( event == "PLAYER_REGEN_DISABLED" ) then
		self:Show();
	elseif ( event == "PLAYER_REGEN_ENABLED" ) then
		self:Hide();
	end
end

function TellMeWhen_Group_Update(groupID)
	local groupName = "TellMeWhen_Group"..groupID;
	local group = getglobal(groupName);
	local resizeButton = getglobal(groupName.."_ResizeButton");

	local locked = TellMeWhen_Settings["Locked"];
	local enabled = TellMeWhen_Settings["Groups"][groupID]["Enabled"];
	local scale = TellMeWhen_Settings["Groups"][groupID]["Scale"];
	local rows = TellMeWhen_Settings["Groups"][groupID]["Rows"];
	local columns = TellMeWhen_Settings["Groups"][groupID]["Columns"];
	local onlyInCombat = TellMeWhen_Settings["Groups"][groupID]["OnlyInCombat"];

	for row = 1, rows do
		for column = 1, columns do
			local iconID = (row-1)*columns + column; 
			local iconName = groupName.."_Icon"..iconID;
			local icon = getglobal(iconName) or CreateFrame("Frame", iconName, group, "TellMeWhen_IconTemplate");
			icon:SetID(iconID);
			icon:Show();
			if ( column > 1 ) then
				icon:SetPoint("TOPLEFT", getglobal(groupName.."_Icon"..(iconID-1)), "TOPRIGHT", TELLMEWHEN_ICONSPACING, 0);
			elseif ( row > 1 ) and ( column == 1 ) then 
				icon:SetPoint("TOPLEFT", getglobal(groupName.."_Icon"..(iconID-columns)), "BOTTOMLEFT", 0, -TELLMEWHEN_ICONSPACING);
			elseif ( iconID == 1 ) then 
				icon:SetPoint("TOPLEFT", group, "TOPLEFT");
			end
			TellMeWhen_Icon_Update(icon, groupID, iconID);
			if ( not enabled ) then
				TellMeWhen_Icon_ClearScripts(icon);
			end
		end
	end
	for iconID = rows*columns+1, TELLMEWHEN_MAXROWS*TELLMEWHEN_MAXROWS do
		local icon = getglobal(groupName.."_Icon"..iconID);
		if icon then
			icon:Hide();
			TellMeWhen_Icon_ClearScripts(icon);
		end
	end

	group:SetScale(scale);
	local lastIcon = groupName.."_Icon"..(rows*columns);
	resizeButton:SetPoint("BOTTOMRIGHT", lastIcon, "BOTTOMRIGHT", 3, -3);
	if ( locked ) then
		resizeButton:Hide();
	else
		resizeButton:Show();
	end

	if ( onlyInCombat and enabled and locked ) then
		group:RegisterEvent("PLAYER_REGEN_ENABLED");
		group:RegisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", TellMeWhen_Group_OnEvent);
		group:Hide();
	else
		group:UnregisterEvent("PLAYER_REGEN_ENABLED");
		group:UnregisterEvent("PLAYER_REGEN_DISABLED");
		group:SetScript("OnEvent", nil);
		if ( enabled ) then
			group:Show();
		else
			group:Hide();
		end
	end
end



-- -------------
-- ICON FUNCTION
-- -------------

function TellMeWhen_Icon_Update(icon, groupID, iconID)

	local iconSettings = TellMeWhen_Settings["Groups"][groupID]["Icons"][iconID];

	local enabled = iconSettings.Enabled;
	local type = iconSettings.Type;
	local cooldownType = iconSettings.CooldownType;
	local cooldownShowWhen = iconSettings.CooldownShowWhen;
	local buffShowWhen = iconSettings.BuffShowWhen;

	icon.name = iconSettings.Name;
	icon.unit = iconSettings.Unit;
	icon.onlyMine = iconSettings.OnlyMine;
	icon.buffOrDebuff = iconSettings.BuffOrDebuff;
	icon.wpnEnchantType = iconSettings.WpnEnchantType;

	icon.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;

	local texture = getglobal(icon:GetName().."Texture");
	local countText = getglobal(icon:GetName().."Count");

	icon:UnregisterEvent("ACTIONBAR_UPDATE_USABLE");
	icon:UnregisterEvent("PLAYER_TARGET_CHANGED");
	icon:UnregisterEvent("PLAYER_FOCUS_CHANGED");
	icon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	icon:UnregisterEvent("UNIT_AURA");
	icon:UnregisterEvent("UNIT_INVENTORY_CHANGED");

	-- used by both cooldown and reactive icons
	if ( cooldownShowWhen == "usable" ) then
		icon.usableAlpha = 1;
		icon.unusableAlpha = 0;
	else
		icon.usableAlpha = 0;
		icon.unusableAlpha = 1;
	end

	-- used by both buff/debuff and wpnenchant icons
	if ( buffShowWhen == "present" ) then
		icon.presentAlpha = 1;
		icon.absentAlpha = 0;
	else
		icon.presentAlpha = 0;
		icon.absentAlpha = 1;
	end

	if ( type == "cooldown" ) then

		if ( cooldownType == "spell" ) then
			if ( GetSpellCooldown(icon.name) ) then
				texture:SetTexture(GetSpellTexture(icon.name));
				icon:SetScript("OnUpdate", TellMeWhen_Icon_SpellCooldown_OnUpdate);
				icon:SetScript("OnEvent", nil);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
		elseif ( cooldownType == "item" ) then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(icon.name);
			if ( itemName ) then
				texture:SetTexture(itemTexture);
				icon:SetScript("OnUpdate", TellMeWhen_Icon_ItemCooldown_OnUpdate);
				icon:SetScript("OnEvent", nil);
			else
				TellMeWhen_Icon_ClearScripts(icon);
				icon.learnedTexture = false;
				texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
			end
		end
		countText:Hide();

	elseif ( type == "buff" ) then

		icon:RegisterEvent("PLAYER_TARGET_CHANGED");
		icon:RegisterEvent("PLAYER_FOCUS_CHANGED");
		icon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
		icon:RegisterEvent("UNIT_AURA");
		icon:SetScript("OnEvent", TellMeWhen_Icon_Buff_OnEvent);
		icon:SetScript("OnUpdate", nil);

		if ( icon.name == "" ) then
			texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		elseif ( GetSpellTexture(icon.name) ) then
			texture:SetTexture(GetSpellTexture(icon.name));
		elseif ( not icon.learnedTexture ) then
--			texture:SetTexture("Interface\\Icons\\INV_Misc_Book_09");
			texture:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01");
			icon.needsTexture = true;
		end	

	elseif ( type == "reactive" ) then

		if ( GetSpellTexture(icon.name) ) then
			texture:SetTexture(GetSpellTexture(icon.name));
			icon:RegisterEvent("ACTIONBAR_UPDATE_USABLE");
			icon:SetScript("OnEvent", TellMeWhen_Icon_Reactive_OnEvent);
			icon:SetScript("OnUpdate", nil);
		else
			TellMeWhen_Icon_ClearScripts(icon);
			icon.learnedTexture = false;
			texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end	
		countText:Hide();

	elseif ( type == "wpnenchant" ) then

		icon:RegisterEvent("UNIT_INVENTORY_CHANGED");
		local slotID, textureName;
		if ( icon.wpnEnchantType == "mainhand" ) then
			slotID, textureName = GetInventorySlotInfo("MainHandSlot");
		elseif ( icon.wpnEnchantType == "offhand" ) then
			slotID, textureName = GetInventorySlotInfo("SecondaryHandSlot");
		end
		local wpnTexture = GetInventoryItemTexture("player", slotID);
		if ( wpnTexture ) then 
			texture:SetTexture(wpnTexture);
			icon:SetScript("OnEvent", TellMeWhen_Icon_WpnEnchant_OnEvent);
			icon:SetScript("OnUpdate", TellMeWhen_Icon_WpnEnchant_OnUpdate);
		else
			TellMeWhen_Icon_ClearScripts(icon);
			texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end
		countText:Hide();

	else
		TellMeWhen_Icon_ClearScripts(icon);
--		texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		texture:SetTexture(nil);
	end

	if ( enabled ) then
		icon:SetAlpha(1.0);
	else
		icon:SetAlpha(0.4);
		TellMeWhen_Icon_ClearScripts(icon);
	end

	icon:Show();
	if ( TellMeWhen_Settings["Locked"] ) then
		icon:EnableMouse(0);
		if ( not enabled ) then
			icon:Hide();
		elseif (icon.name == "") and ( type ~= "wpnenchant" ) then
			icon:Hide();
		end
		TellMeWhen_Icon_StatusCheck(icon, type);
	else
		icon:EnableMouse(1);
		TellMeWhen_Icon_ClearScripts(icon);
	end

end

function TellMeWhen_Icon_ClearScripts(icon)
	icon:SetScript("OnEvent", nil);
	icon:SetScript("OnUpdate", nil);
end

function TellMeWhen_Icon_StatusCheck(icon, type)
	-- this function is so OnEvent-based icons can do a check when the addon is locked
	if ( type == "reactive" ) then
		TellMeWhen_Icon_ReactiveCheck(icon);
	elseif ( type == "buff" ) then
		TellMeWhen_Icon_BuffCheck(icon);
	end
end

function TellMeWhen_Icon_SpellCooldown_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then 
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local startTime, timeLeft, enabled = GetSpellCooldown(self.name);
		if ( timeLeft > 1.5 ) then
			self:SetAlpha(self.unusableAlpha);
		elseif ( timeLeft == 0 ) then
			self:SetAlpha(self.usableAlpha);
		end
	end
end

function TellMeWhen_Icon_ItemCooldown_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then 
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local startTime, timeLeft, enabled = GetItemCooldown(self.name);
		if ( timeLeft > 1.5 ) then
			self:SetAlpha(self.unusableAlpha);
		elseif ( timeLeft == 0 ) then
			self:SetAlpha(self.usableAlpha);
		end
	end
end

function TellMeWhen_Icon_Buff_OnEvent(self, event, ...)
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
--		local timestamp, combatEvent, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags;
--		local spellID, spellName, spellSchool, auraType;
		local combatEvent = select(2, ...);
		if ( combatEvent == "SPELL_AURA_APPLIED" ) 
			or ( combatEvent == "SPELL_AURA_REMOVED" ) 
			or ( combatEvent == "SPELL_AURA_APPLIED_DOSE" ) 
			or ( combatEvent == "SPELL_AURA_REMOVED_DOSE" ) 
			or ( combatEvent == "SPELL_AURA_REFRESH" ) 		-- not working in WoW 2.4.3
			or ( combatEvent == "SPELL_AURA_BROKEN" ) 
			or ( combatEvent == "SPELL_AURA_BROKEN_SPELL" ) 
		then
			local spellName = select(10, ...);
			if ( spellName == self.name ) then				-- could add check for unitGUID here, i guess.  meh.  
				TellMeWhen_Icon_BuffCheck(self);
			end
		elseif ( combatEvent == "UNIT_DIED" ) then
			local dstGUID = select(6, ...);
			local watchedGUID = UnitGUID(self.unit);
			if ( dstGUID == watchedGUID ) then
				TellMeWhen_Icon_BuffCheck(self);
			end
		end
	elseif (event == "UNIT_AURA" ) then						-- only needed for buff/debuff refresh. drop when 3.0 hits. 
		local unit = select(1, ...);
		if ( unit == self.unit ) then
			TellMeWhen_Icon_BuffCheck(self);
--			TellMeWhen_Test("TellMeWhen: "..event.." event detected on "..unit);
		end
	elseif ( event == "PLAYER_TARGET_CHANGED" ) or ( event == "PLAYER_FOCUS_CHANGED" ) then
		TellMeWhen_Icon_BuffCheck(self);
	end
end

function TellMeWhen_Icon_BuffCheck(icon)
	if ( UnitName(icon.unit) ) then
		local buffName, rank, iconTexture, count, duration, timeLeft;
		local countText = getglobal(icon:GetName().."Count");
		for buffIndex = 1, 40 do
			if ( icon.buffOrDebuff == "HELPFUL" ) then
				buffName, rank, iconTexture, count, duration, timeLeft = UnitBuff(icon.unit, buffIndex);
			else
				buffName, rank, iconTexture, count, duration, timeLeft = UnitDebuff(icon.unit, buffIndex);
			end
			if ( not buffName ) then
				icon:SetAlpha(icon.absentAlpha);
				countText:Hide();
				return;
			elseif ( buffName == icon.name ) then
				if ( icon.needsTexture ) then
					getglobal(icon:GetName().."Texture"):SetTexture(iconTexture);
					icon.learnedTexture = true;
					icon.needsTexture = nil;
				end
				if ( not icon.onlyMine ) or ( icon.onlyMine and timeLeft ) then
					icon:SetAlpha(icon.presentAlpha);
					if ( count > 1 ) then
						countText:SetText(count);
						countText:Show();
					else
						countText:Hide();
					end
					return;
				end
			end
		end
	else
		icon:SetAlpha(0);
	end
end

function TellMeWhen_Icon_Reactive_OnEvent(self, event)
	if ( event == "ACTIONBAR_UPDATE_USABLE" ) then
		TellMeWhen_Icon_ReactiveCheck(self);
	end
end

function TellMeWhen_Icon_ReactiveCheck(icon)
	local usable, nomana = IsUsableSpell(icon.name);
	if ( usable ) then
		icon:SetAlpha(icon.usableAlpha);
	elseif ( not usable and not nomana ) then
		icon:SetAlpha(icon.unusableAlpha);
	end
end

function TellMeWhen_Icon_WpnEnchant_OnEvent(self, event, ...)
	if ( event == "UNIT_INVENTORY_CHANGED" ) and ( select(1, ...) == "player" ) then
		local slotID, textureName;
		if ( self.wpnEnchantType == "mainhand" ) then
			slotID, textureName = GetInventorySlotInfo("MainHandSlot");
		elseif ( self.wpnEnchantType == "offhand" ) then
			slotID, textureName = GetInventorySlotInfo("SecondaryHandSlot");
		end
		local wpnTexture = GetInventoryItemTexture("player", slotID);
		local texture = getglobal(self:GetName().."Texture");
		if ( wpnTexture ) then 
			texture:SetTexture(wpnTexture);
		else
			texture:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
		end
	end
end

function TellMeWhen_Icon_WpnEnchant_OnUpdate(self, elapsed)
	self.updateTimer = self.updateTimer - elapsed;
	if ( self.updateTimer <= 0 ) then 
		self.updateTimer = TELLMEWHEN_UPDATE_INTERVAL;
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges = GetWeaponEnchantInfo();
		if ( self.wpnEnchantType == "mainhand" ) and ( hasMainHandEnchant ) then
			self:SetAlpha(self.presentAlpha);
			local countText = getglobal(self:GetName().."Count");
			if ( mainHandCharges > 1 ) then
				countText:SetText(mainHandCharges);
				countText:Show();
			else
				countText:Hide();
			end
		elseif ( self.wpnEnchantType == "offhand" ) and ( hasOffHandEnchant ) then
			self:SetAlpha(self.presentAlpha);
			local countText = getglobal(self:GetName().."Count");
			if ( offHandCharges > 1 ) then
				countText:SetText(offHandCharges);
				countText:Show();
			else
				countText:Hide();
			end
		else
			self:SetAlpha(self.absentAlpha);
		end
	end
end

