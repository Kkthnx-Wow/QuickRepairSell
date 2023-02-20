local addonName, addon = ...

local f = CreateFrame("Frame")

local defaults = {
	autoSellEnabled = false,
	autoRepairEnabled = false,
	useGuildFunds = false,
}

function f:OnEvent(event, addOnName)
	if addOnName == "QuickRepairSell" then
		QuickRepairSellDB = QuickRepairSellDB or CopyTable(defaults)
		self.db = QuickRepairSellDB
		self:InitializeOptions()
	end
end

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", f.OnEvent)

function f:InitializeOptions()
	-- Create the options panel frame
	local optionsPanel = CreateFrame("Frame", "QuickRepairSellOptionsPanel", SettingsPanel.Container)
	optionsPanel.name = addonName

	-- Add the auto sell checkbox
	local autoSellCheckbox = CreateFrame("CheckButton", "QuickRepairSellAutoSellCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	autoSellCheckbox:SetPoint("TOPLEFT", 16, -16)
	autoSellCheckbox.Text:SetText("Enable Auto Sell")
	autoSellCheckbox:SetScript("OnClick", function()
		self.db.autoSellEnabled = autoSellCheckbox:GetChecked()
	end)
	autoSellCheckbox:SetChecked(self.db.autoSellEnabled)

	-- Add the auto repair checkbox
	local autoRepairCheckbox = CreateFrame("CheckButton", "QuickRepairSellAutoRepairCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	autoRepairCheckbox:SetPoint("TOPLEFT", autoSellCheckbox, "BOTTOMLEFT", 0, -16)
	autoRepairCheckbox.Text:SetText("Enable Auto Repair")
	autoRepairCheckbox:SetScript("OnClick", function()
		self.db.autoRepairEnabled = autoRepairCheckbox:GetChecked()
		if self.db.autoRepairEnabled then
			QuickRepairSellAutoRepairGuildFundsCheckbox:SetEnabled(true)
			QuickRepairSellAutoRepairGuildFundsCheckbox:SetAlpha(1)
		else
			QuickRepairSellAutoRepairGuildFundsCheckbox:SetEnabled(false)
			QuickRepairSellAutoRepairGuildFundsCheckbox:SetAlpha(0.5)
		end
	end)
	autoRepairCheckbox:SetChecked(self.db.autoRepairEnabled)

	-- Add the guild funds checkbox (disabled by default)
	local guildFundsCheckbox = CreateFrame("CheckButton", "QuickRepairSellAutoRepairGuildFundsCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	guildFundsCheckbox:SetPoint("TOPLEFT", autoRepairCheckbox, "BOTTOMLEFT", 16, -16)
	guildFundsCheckbox.Text:SetText("Use Guild Funds for Repairs")
	guildFundsCheckbox:SetEnabled(false)
	guildFundsCheckbox:SetAlpha(0.5)
	guildFundsCheckbox:SetScript("OnClick", function()
		self.db.useGuildFunds = guildFundsCheckbox:GetChecked()
	end)
	guildFundsCheckbox:SetChecked(self.db.useGuildFunds)

	-- Register the options panel with the Blizzard options UI
	InterfaceOptions_AddCategory(optionsPanel)
end
