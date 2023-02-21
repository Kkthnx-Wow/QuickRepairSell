local addonName = ...

-- Create a new frame named "QuickRepairSellFrame"
local QuickRepairSellFrame = CreateFrame("Frame")

-- Default settings for the addon
local defaults = {
	autoSellEnabled = false,
	autoRepairEnabled = false,
	useGuildFunds = false,
}

-- Event handler for the QuickRepairSellFrame
function QuickRepairSellFrame:OnEvent(_, addon)
	-- If the addon that was loaded is the QuickRepairSell addon, set up the database and initialize the options
	if addon == addonName then
		-- If the QuickRepairSellDB database doesn't exist yet, create it and set it to the default values
		QuickRepairSellDB = QuickRepairSellDB or CopyTable(defaults)

		-- Set up the QuickRepairSellFrame's database to use QuickRepairSellDB
		self.dataBase = QuickRepairSellDB

		-- Initialize the addon's options
		self:InitializeOptions()
	end
end

-- Register the ADDON_LOADED event for the QuickRepairSellFrame
QuickRepairSellFrame:RegisterEvent("ADDON_LOADED")

-- Set the script for the QuickRepairSellFrame to use the QuickRepairSellFrame:OnEvent function as the event handler
QuickRepairSellFrame:SetScript("OnEvent", QuickRepairSellFrame.OnEvent)

-- Function to initialize the addon options
function QuickRepairSellFrame:InitializeOptions()
	-- Create the options panel frame and set the name to the addon name
	local optionsPanel = CreateFrame("Frame", "QuickRepairSellOptionsPanel", SettingsPanel.Container)
	optionsPanel.name = addonName

	-- Add the auto sell checkbox
	local autoSellCheckbox = CreateFrame("CheckButton", "QuickRepairSellAutoSellCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	autoSellCheckbox:SetPoint("TOPLEFT", 16, -16)
	autoSellCheckbox.Text:SetText("Enable Auto Sell")

	-- Set up the auto sell checkbox to update the database when clicked and initialize its checked status
	autoSellCheckbox:SetScript("OnClick", function()
		self.dataBase.autoSellEnabled = autoSellCheckbox:GetChecked()
	end)
	autoSellCheckbox:SetChecked(self.dataBase.autoSellEnabled)

	-- Add the auto repair checkbox
	local autoRepairCheckbox = CreateFrame("CheckButton", "QuickRepairSellAutoRepairCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	autoRepairCheckbox:SetPoint("TOPLEFT", autoSellCheckbox, "BOTTOMLEFT", 0, -16)
	autoRepairCheckbox.Text:SetText("Enable Auto Repair")

	-- Set up the auto repair checkbox to update the database when clicked and initialize its checked status
	autoRepairCheckbox:SetScript("OnClick", function()
		self.dataBase.autoRepairEnabled = autoRepairCheckbox:GetChecked()

		-- Enable/disable the guild funds checkbox based on the auto repair checkbox status
		if self.dataBase.autoRepairEnabled then
			QuickRepairSellGuildFundsCheckbox:SetEnabled(true)
			QuickRepairSellGuildFundsCheckbox:SetAlpha(1)
		else
			QuickRepairSellGuildFundsCheckbox:SetEnabled(false)
			QuickRepairSellGuildFundsCheckbox:SetAlpha(0.5)
		end
	end)
	autoRepairCheckbox:SetChecked(self.dataBase.autoRepairEnabled)

	-- Add the guild funds checkbox (disabled by default)
	local guildFundsCheckbox = CreateFrame("CheckButton", "QuickRepairSellGuildFundsCheckbox", optionsPanel, "InterfaceOptionsCheckButtonTemplate")
	guildFundsCheckbox:SetPoint("TOPLEFT", autoRepairCheckbox, "BOTTOMLEFT", 16, -16)
	guildFundsCheckbox.Text:SetText("Use Guild Funds for Repairs")
	guildFundsCheckbox:SetEnabled(false)
	guildFundsCheckbox:SetAlpha(0.5)

	-- Set up the guild funds checkbox to update the database when clicked and initialize its checked status
	guildFundsCheckbox:SetScript("OnClick", function()
		self.dataBase.useGuildFunds = guildFundsCheckbox:GetChecked()
	end)
	guildFundsCheckbox:SetChecked(self.dataBase.useGuildFunds)

	-- Register the options panel with the Blizzard options UI
	InterfaceOptions_AddCategory(optionsPanel)
end
