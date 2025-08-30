-- Loader shim for ArkInventory-Tint by Xayia under new folder name
-- If the old file is present, use it; otherwise, expect code to be consolidated here in future.

local addonName = "ArkInventory_Tint_Xayia"
local displayName = "ArkInventory-Tint by Xayia"
local f = CreateFrame("Frame")

local DB
local defaults = {
	armor = {},
	weapon = {},
	debug = false,
	mailShowBelow40 = false,
	mailSubtypeLabel = nil,
	cloakNoTint = false,
}

local function scheduleWelcome()
	if f.welcomed then return end
	f.welcomed = true
	local namePart = "|cff00ffffArkInventory-Tint|r |cffffffffby|r |cffff0000Xayia|r"
	local msg = string.format("%s loaded. Type |cffffd100/aitint|r for options.", namePart)
	if not f.welcomeRunner then
		f.welcomeRunner = CreateFrame("Frame")
		f.welcomeRunner.elapsed = 0
		f.welcomeRunner:SetScript("OnUpdate", function(self, e)
			self.elapsed = self.elapsed + e
			if self.elapsed > 1 then
				if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(msg) else print(msg) end
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end)
	end
	f.welcomeRunner.elapsed = 0
	f.welcomeRunner:Show()
end

local armorIndex, armorSubs
local weaponIndex, weaponSubs

local function ensureAuctionSubs()
	if armorSubs and weaponSubs and #armorSubs > 0 and #weaponSubs > 0 then return end
	local classes = { GetAuctionItemClasses() }
	armorIndex, weaponIndex = nil, nil
	for idx, className in ipairs(classes) do
		if className == ARMOR then armorIndex = idx end
		if className == WEAPON then weaponIndex = idx end
	end
	armorSubs = armorIndex and { GetAuctionItemSubClasses(armorIndex) } or armorSubs or {}
	weaponSubs = weaponIndex and { GetAuctionItemSubClasses(weaponIndex) } or weaponSubs or {}
	if not armorSubs or #armorSubs == 0 then
		armorSubs = { "Miscellaneous", "Cloth", "Leather", "Mail", "Plate", "Shields" }
	end
	if not weaponSubs or #weaponSubs == 0 then
		weaponSubs = {
			"One-Handed Axes", "Two-Handed Axes",
			"Bows", "Guns", "One-Handed Maces", "Two-Handed Maces",
			"Polearms", "One-Handed Swords", "Two-Handed Swords",
			"Staves", "Fist Weapons", "Daggers", "Thrown",
			"Crossbows", "Wands", "Fishing Poles"
		}
	end
end

local function getItemInfoFast(link)
	if not link then return end
	local name, _, quality, itemLevel, reqLevel, itemType, itemSubType, _, equipLoc = GetItemInfo(link)
	return name, quality, itemLevel, reqLevel, itemType, itemSubType, equipLoc
end

local function isEquippableLoc(equipLoc)
	return type(equipLoc) == "string" and string.sub(equipLoc, 1, 7) == "INVTYPE"
end

local function isMailSubtypeName(sub)
	ensureAuctionSubs()
	if not sub then return false end
	local candidates = {}
	if armorSubs and armorSubs[4] then candidates[armorSubs[4]] = true end
	if DB and DB.mailSubtypeLabel then candidates[DB.mailSubtypeLabel] = true end
	candidates["Mail"] = true
	return candidates[sub] == true
end

local function shouldTint(i)
	if not i or not i.h then return false end
	ensureAuctionSubs()
	local name, _, _, reqLevel, itemType, itemSubType, equipLoc = getItemInfoFast(i.h)
	if not itemSubType then return nil end
	if not isEquippableLoc(equipLoc) then return false end
	local tint = false
	if itemType == ARMOR or itemType == "Armor" then
		local isMail = isMailSubtypeName(itemSubType)
		if DB.debug and DEFAULT_CHAT_FRAME and isMail then
			DEFAULT_CHAT_FRAME:AddMessage(string.format("[AITint] mail<40 debug: enabled=%s reqLevel=%s subtype=%s", tostring(DB.mailShowBelow40), tostring(reqLevel or "nil"), tostring(itemSubType)))
		end
		if DB.mailShowBelow40 and isMail and (reqLevel or 0) < 40 then
			if DB.debug and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[AITint] mail<40 (reqLevel) exception -> not tinting") end
			return false
		end
		if DB.cloakNoTint and equipLoc == "INVTYPE_CLOAK" then
			if DB.debug and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[AITint] cloakNoTint exception -> not tinting") end
			return false
		end
		tint = DB.armor[itemSubType] and true or false
	elseif itemType == WEAPON or itemType == "Weapon" then
		tint = DB.weapon[itemSubType] and true or false
	else
		tint = (DB.armor[itemSubType] or DB.weapon[itemSubType]) and true or false
	end
	if DB.debug and DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(string.format("[AITint] type=%s sub=%s equip=%s tint=%s", tostring(itemType), tostring(itemSubType), tostring(equipLoc), tostring(tint)))
	end
	return tint
end

local function ensureOverlay(frame)
	if not frame.AITintOverlay then
		local ov = frame:CreateTexture(nil, "OVERLAY")
		ov:SetDrawLayer("OVERLAY", 7)
		ov:SetAllPoints(frame)
		ov:SetTexture([[Interface\Buttons\WHITE8X8]])
		ov:SetVertexColor(1.0, 0.0, 0.0, 0.60)
		ov:Hide()
		frame.AITintOverlay = ov
	end
	return frame.AITintOverlay
end

local function tintFrame(frame, red)
	if not frame then return end
	local ov = ensureOverlay(frame)
	if red then
		ov:Show()
	else
		ov:Hide()
	end
end

local onItemUpdate

local pending = {}
local runner
local function scheduleRecheck(frame)
	if not runner then
		runner = CreateFrame("Frame")
		runner:SetScript("OnUpdate", function(self, e)
			local now = GetTime()
			local any = false
			for fr, deadline in pairs(pending) do
				any = true
				if now >= deadline then
					pending[fr] = nil
					onItemUpdate(fr)
				end
			end
			if not any then self:Hide() end
		end)
	end
	if not pending[frame] then
		pending[frame] = GetTime() + 0.2
		runner:Show()
	end
end

function onItemUpdate(frame)
	if not frame or not frame.ARK_Data then return end
	local i = ArkInventory and ArkInventory.Frame_Item_GetDB and ArkInventory.Frame_Item_GetDB(frame)
	if not i then return end
	local red = shouldTint(i)
	if red == nil then
		scheduleRecheck(frame)
		return
	end
	tintFrame(frame, red)
end

local function hookOnce()
	if not ArkInventory or not ArkInventory.Frame_Item_Update then return end
	if f.hooked then return end
	f.hooked = true
	hooksecurefunc(ArkInventory, "Frame_Item_OnLoad", onItemUpdate)
	hooksecurefunc(ArkInventory, "Frame_Item_Update", function(loc_id, bag_id, slot_id)
		local framename = ArkInventory.ContainerItemNameGet(loc_id, bag_id, slot_id)
		local btn = _G[framename]
		if btn then onItemUpdate(btn) end
	end)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Texture", onItemUpdate)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Border", onItemUpdate)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Count", onItemUpdate)
	if ArkInventory.Frame_Item_Update_Fade then
		hooksecurefunc(ArkInventory, "Frame_Item_Update_Fade", onItemUpdate)
	end
end

local optionsPanel
local function buildOptions()
	if optionsPanel then return end
	ensureAuctionSubs()
	optionsPanel = CreateFrame("Frame", addonName .. "Options", InterfaceOptionsFramePanelContainer)
	optionsPanel.name = displayName
	optionsPanel:Hide()
	optionsPanel:SetScript("OnShow", function(panel)
		panel:SetScript("OnShow", nil)
		local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText(displayName)

		local function addSection(headerText, entries, dbTable, anchor)
			local sectionKey
			if headerText == ARMOR or headerText == "Armor" then
				sectionKey = "Armor"
			elseif headerText == WEAPON or headerText == "Weapon" then
				sectionKey = "Weapon"
			else
				sectionKey = "Section"
			end
			local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
			header:SetText(headerText or sectionKey)

			local btnAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
			btnAll:SetSize(80, 20)
			btnAll:SetText("All")
			btnAll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
			btnAll:SetScript("OnClick", function()
				for _, sub in ipairs(entries or {}) do if sub and sub ~= "" then dbTable[sub] = true end end
				if ArkInventory and ArkInventory.Frame_Main_Generate then ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh) end
			end)

			local btnNone = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
			btnNone:SetSize(80, 20)
			btnNone:SetText("None")
			btnNone:SetPoint("LEFT", btnAll, "RIGHT", 6, 0)
			btnNone:SetScript("OnClick", function()
				for _, sub in ipairs(entries or {}) do if sub and sub ~= "" then dbTable[sub] = false end end
				if ArkInventory and ArkInventory.Frame_Main_Generate then ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh) end
			end)

			local filtered = {}
			for _, sub in ipairs(entries or {}) do if sub and sub ~= "" then table.insert(filtered, sub) end end
			local cols = 2
			local colWidth = 220
			local xOff, yOff = 0, -30
			local c = 0
			local mailName = (armorSubs and armorSubs[4]) or "Mail"
			for _, sub in ipairs(filtered) do
				local cb = CreateFrame("CheckButton", addonName .. sectionKey .. tostring(sub), panel, "UICheckButtonTemplate")
				cb:SetPoint("TOPLEFT", header, "BOTTOMLEFT", xOff, yOff)
				_G[cb:GetName() .. "Text"]:SetText(sub)
				cb:SetChecked(dbTable[sub] or false)
				cb:SetScript("OnClick", function(self)
					dbTable[sub] = self:GetChecked() or false
					if sub == mailName and sectionKey == "Armor" and panel.AITintMailBelow40 then
						if self:GetChecked() then panel.AITintMailBelow40:Show() else panel.AITintMailBelow40:Hide() end
					end
					if ArkInventory and ArkInventory.Frame_Main_Generate then ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh) end
				end)
				if sectionKey == "Armor" and sub == mailName then
					DB.mailSubtypeLabel = sub
					local subCB = CreateFrame("CheckButton", addonName .. "ArmorMailBelow40", panel, "UICheckButtonTemplate")
					subCB:SetPoint("LEFT", cb, "RIGHT", 24, 0)
					_G[subCB:GetName() .. "Text"]:SetText("Show Mail under level 40 (attunable for plate)")
					subCB:SetChecked(DB.mailShowBelow40 or false)
					subCB:SetScript("OnClick", function(self)
						DB.mailShowBelow40 = self:GetChecked() or false
						if ArkInventory and ArkInventory.Frame_Main_Generate then ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh) end
					end)
					panel.AITintMailBelow40 = subCB
					if dbTable[sub] then panel.AITintMailBelow40:Show() else panel.AITintMailBelow40:Hide() end
				elseif sectionKey == "Armor" and sub == "Cloth" then
					local subCB = CreateFrame("CheckButton", addonName .. "ArmorClothNoTintCloak", panel, "UICheckButtonTemplate")
					subCB:SetPoint("LEFT", cb, "RIGHT", 24, 0)
					_G[subCB:GetName() .. "Text"]:SetText("Don't tint Cloak")
					subCB:SetChecked(DB.cloakNoTint or false)
					subCB:SetScript("OnClick", function(self)
						DB.cloakNoTint = self:GetChecked() or false
						if ArkInventory and ArkInventory.Frame_Main_Generate then ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh) end
					end)
					panel.AITintClothNoTintCloak = subCB
					if dbTable[sub] then panel.AITintClothNoTintCloak:Show() else panel.AITintClothNoTintCloak:Hide() end
				end
				c = c + 1
				if c % cols == 0 then
					yOff = yOff - 22
					xOff = 0
				else
					xOff = xOff + colWidth
				end
			end
			local rows = math.ceil(#filtered / cols)
			local usedHeight = 30 + (rows > 0 and ((rows - 1) * 22) or 0)
			local spacer = CreateFrame("Frame", nil, panel)
			spacer:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -usedHeight - 14)
			spacer:SetSize(1, 1)
			return spacer
		end

		local anchor = title
		anchor = addSection(ARMOR, armorSubs or {}, DB.armor, anchor)
		anchor = addSection(WEAPON, weaponSubs or {}, DB.weapon, anchor)
	end)
	InterfaceOptions_AddCategory(optionsPanel)
end

SLASH_AITINT1 = "/aitint"
SlashCmdList.AITINT = function(msg)
	msg = (msg or ""):lower()
	if msg == "debug" then
		DB.debug = not DB.debug
		if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("[AITint] debug=" .. tostring(DB.debug)) end
		return
	end
	InterfaceOptionsFrame_OpenToCategory(displayName)
	InterfaceOptionsFrame_OpenToCategory(displayName)
end

f:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		ArkInventory_Tint_XayiaDB = ArkInventory_Tint_XayiaDB or {}
		DB = ArkInventory_Tint_XayiaDB
		for k,v in pairs(defaults) do if DB[k] == nil then DB[k] = v end end
		buildOptions()
	elseif event == "ADDON_LOADED" and arg1 == "ArkInventory" then
		hookOnce()
	elseif event == "PLAYER_LOGIN" then
		hookOnce()
		scheduleWelcome()
	elseif event == "PLAYER_ENTERING_WORLD" then
		scheduleWelcome()
	end
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
