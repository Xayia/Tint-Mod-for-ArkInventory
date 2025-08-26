local addonName = "ArkInventory_ItemLevel_Xayia"
local displayName = "ArkInventory-ItemLevel by Xayia"
local f = CreateFrame("Frame")

local DB
local defaults = {
	fontName = "", -- LSM font name or empty = game default
	size = 10
}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local LSM_FONT_KEY = (LSM and LSM.MediaType and LSM.MediaType.FONT) or "font"

local function chatOut(...)
	local msg = table.concat({...})
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	else
		print(msg)
	end
end

local function welcomeOnce()
	if f.welcomed then return end
	f.welcomed = true
	local namePart = "|cff00ffffArkInventory-ItemLevel|r |cffffffffby|r |cffff0000Xayia|r"
	chatOut(namePart, " loaded. Type |cffffd100/aiil|r to open options.")
end

local function scheduleWelcome()
	if f.welcomeScheduled then return end
	f.welcomeScheduled = true
	local d = CreateFrame("Frame")
	local elapsed = 0
	d:SetScript("OnUpdate", function(self, e)
		elapsed = elapsed + e
		if elapsed > 1 then
			welcomeOnce()
			self:SetScript("OnUpdate", nil)
			self:Hide()
		end
	end)
end

local function applyFontSettings(fs)
	local fontPath
	if DB.fontName and DB.fontName ~= "" and LSM then
		fontPath = LSM:Fetch(LSM_FONT_KEY, DB.fontName)
	end
	local currentFont, currentSize = fs:GetFont()
	local useFont = fontPath or currentFont
	local useSize = DB.size or currentSize or 10
	fs:SetFont(useFont, useSize, "OUTLINE")
end

local function ensureFontString(frame)
	if frame and not frame.AILX_ItemLevel then
		local fs = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		fs:SetDrawLayer("OVERLAY", 7)
		fs:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		fs:SetTextColor(1, 1, 1, 1)
		fs:SetJustifyH("RIGHT")
		applyFontSettings(fs)
		frame.AILX_ItemLevel = fs
	end
	return frame and frame.AILX_ItemLevel
end

local function getItemLevelFromLink(link)
	if not link then return nil end
	local ilvl = select(4, GetItemInfo(link))
	return ilvl
end

local function isArmorOrWeapon(link)
	local _, _, _, _, _, itemType = GetItemInfo(link)
	return itemType == ITEM_CLASS_ARMOR or itemType == ITEM_CLASS_WEAPON or itemType == "Armor" or itemType == "Weapon"
end

local function updateItemButton(frame)
	if not frame or not frame.ARK_Data then return end
	local i = ArkInventory and ArkInventory.Frame_Item_GetDB and ArkInventory.Frame_Item_GetDB(frame)
	local fs = ensureFontString(frame)
	if not fs then return end
	applyFontSettings(fs)
	if i and i.h and isArmorOrWeapon(i.h) then
		local ilvl = getItemLevelFromLink(i.h)
		if ilvl and ilvl > 0 then
			fs:SetText(ilvl)
			fs:Show()
		else
			fs:SetText("")
			fs:Hide()
		end
	else
		fs:SetText("")
		fs:Hide()
	end
end

local function hookOnce()
	if not ArkInventory or not ArkInventory.Frame_Item_Update then return end
	if f.hooked then return end
	f.hooked = true
	hooksecurefunc(ArkInventory, "Frame_Item_OnLoad", function(btn)
		updateItemButton(btn)
	end)
	hooksecurefunc(ArkInventory, "Frame_Item_Update", function(loc_id, bag_id, slot_id)
		local framename = ArkInventory.ContainerItemNameGet(loc_id, bag_id, slot_id)
		local btn = _G[framename]
		if btn then updateItemButton(btn) end
	end)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Texture", updateItemButton)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Border", updateItemButton)
	hooksecurefunc(ArkInventory, "Frame_Item_Update_Count", updateItemButton)
end

local function openOptions()
	InterfaceOptionsFrame_OpenToCategory(displayName)
	InterfaceOptionsFrame_OpenToCategory(displayName)
end

SLASH_AILX1 = nil
SLASH_AIIL1 = "/aiil"
SlashCmdList.AIIL = function(msg)
	openOptions()
end

local optionsPanel
local sizeSlider, fontDropdown

local function refreshOptions()
	if not optionsPanel then return end
	if sizeSlider then sizeSlider:SetValue(DB.size or defaults.size) end
	if fontDropdown then
		if DB.fontName and DB.fontName ~= "" then
			UIDropDownMenu_SetSelectedValue(fontDropdown, DB.fontName)
			fontDropdown.selectedValue = DB.fontName
			fontDropdown.selectedName = DB.fontName
			UIDropDownMenu_SetText(fontDropdown, DB.fontName)
		else
			UIDropDownMenu_ClearAll(fontDropdown)
			fontDropdown.selectedValue = nil
			fontDropdown.selectedName = nil
			UIDropDownMenu_SetText(fontDropdown, "Game Default")
		end
	end
end

local function buildOptions()
	if optionsPanel then return end
	optionsPanel = CreateFrame("Frame", addonName .. "Options", InterfaceOptionsFramePanelContainer)
	optionsPanel.name = displayName
	optionsPanel:Hide()
	optionsPanel:SetScript("OnShow", function(panel)
		panel:SetScript("OnShow", nil)
		local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		title:SetPoint("TOPLEFT", 16, -16)
		title:SetText(displayName)

		local sizeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		sizeLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
		sizeLabel:SetText("Font Size")

		sizeSlider = CreateFrame("Slider", addonName .. "SizeSlider", panel, "OptionsSliderTemplate")
		sizeSlider:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", 0, -8)
		sizeSlider:SetMinMaxValues(6, 24)
		sizeSlider:SetValueStep(1)
		if sizeSlider.SetObeyStepOnDrag then sizeSlider:SetObeyStepOnDrag(true) end
		_G[sizeSlider:GetName() .. 'Low']:SetText('6')
		_G[sizeSlider:GetName() .. 'High']:SetText('24')
		_G[sizeSlider:GetName() .. 'Text']:SetText('Size')
		sizeSlider:SetScript("OnValueChanged", function(self, value)
			DB.size = math.floor(value + 0.5)
			if ArkInventory and ArkInventory.Frame_Main_Generate then
				ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh)
			end
		end)

		local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		fontLabel:SetPoint("TOPLEFT", sizeSlider, "BOTTOMLEFT", 0, -20)
		fontLabel:SetText("Font")

		fontDropdown = CreateFrame("Frame", addonName .. "FontDropdown", panel, "UIDropDownMenuTemplate")
		fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", -16, -8)

		local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
		local function onFontChosen(btn)
			DB.fontName = btn and btn.value or ""
			local label
			if DB.fontName ~= "" then
				if btn and btn.GetText then
					label = btn:GetText()
				else
					label = (btn and btn.text) or tostring(DB.fontName)
				end
				UIDropDownMenu_SetSelectedValue(fontDropdown, DB.fontName)
				fontDropdown.selectedValue = DB.fontName
				fontDropdown.selectedName = DB.fontName
				UIDropDownMenu_SetText(fontDropdown, label)
			else
				UIDropDownMenu_ClearAll(fontDropdown)
				fontDropdown.selectedValue = nil
				fontDropdown.selectedName = nil
				UIDropDownMenu_SetText(fontDropdown, "Game Default")
			end
			CloseDropDownMenus()
			if ArkInventory and ArkInventory.Frame_Main_Generate then
				ArkInventory.Frame_Main_Generate(nil, ArkInventory.Const.Window.Draw.Refresh)
			end
		end

		local function initialize(self, level)
			local info = UIDropDownMenu_CreateInfo()
			info.func = onFontChosen
			info.text = "Game Default"
			info.value = ""
			info.checked = (DB.fontName == nil or DB.fontName == "")
			UIDropDownMenu_AddButton(info, level)
			if LSM then
				for _, name in ipairs(LSM:List(LSM_FONT_KEY)) do
					info = UIDropDownMenu_CreateInfo()
					info.func = onFontChosen
					info.text = name
					info.value = name
					info.checked = (DB.fontName == name)
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
		UIDropDownMenu_Initialize(fontDropdown, initialize)
		UIDropDownMenu_SetWidth(fontDropdown, 180)
		refreshOptions()
	end)
	InterfaceOptions_AddCategory(optionsPanel)
end

f:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		ArkInventory_ItemLevel_XayiaDB = ArkInventory_ItemLevel_XayiaDB or {}
		DB = ArkInventory_ItemLevel_XayiaDB
		for k, v in pairs(defaults) do if DB[k] == nil then DB[k] = v end end
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
