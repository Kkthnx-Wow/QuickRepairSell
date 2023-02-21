local addonName = ...

-- Create a new frame named "AutoRepairFrame"
local AutoRepairFrame = CreateFrame("Frame", addonName)

-- Register the "PLAYER_LOGIN" event for the AutoRepairFrame
AutoRepairFrame:RegisterEvent("PLAYER_LOGIN")

-- Set up local references to various functions and constants for easy access
local cTimerAfter = C_Timer.After -- For setting a timer
local canGuildBankRepair = CanGuildBankRepair -- Check if guild bank repair is available
local canMerchantRepair = CanMerchantRepair -- Check if merchant repair is available
local getGuildBankWithdrawMoney = GetGuildBankWithdrawMoney -- Get the amount of money available in the guild bank
local getMoney = GetMoney -- Get the player's current money
local getRepairAllCost = GetRepairAllCost -- Get the cost to repair all items
local isInGuild = IsInGuild -- Check if the player is in a guild
local isShiftKeyDown = IsShiftKeyDown -- Check if the Shift key is being held down
local leGameErrGuildNotEnoughMoney = LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY -- Error message constant for when the guild bank doesn't have enough money to repair
local repairAllItems = _G.RepairAllItems -- Repair all items function from the default UI
local stringFormat = string.format -- Format a string with variables inserted

-- Auto repair
local autoRepair -- function that handles the repair of all items
local canRepair -- boolean indicating if repair is possible
local isBankEmpty -- boolean indicating if guild bank is empty
local isShown -- boolean indicating if the function is currently shown
local repairAllCost -- cost to repair all items

-- Format the gold amount symbol with a gold color
local GOLD_AMOUNT_SYMBOL = format("|cffffd700%s|r", GOLD_AMOUNT_SYMBOL)

-- Format the silver amount symbol with a gray color
local SILVER_AMOUNT_SYMBOL = format("|cffd0d0d0%s|r", SILVER_AMOUNT_SYMBOL)

-- Format the copper amount symbol with an orange color
local COPPER_AMOUNT_SYMBOL = format("|cffc77050%s|r", COPPER_AMOUNT_SYMBOL)

local function formatMoneyString(money)
	-- If money is nil or not a number, return an empty string
	if not money or type(money) ~= "number" then
		return ""
	end

	-- Calculate the amount of gold, silver, and copper
	local gold, silver, copper = math.floor(money / 10000), math.floor((money % 10000) / 100), money % 100

	-- Initialize an empty string to hold the money amount
	local moneyString = ""

	-- If the amount of gold is greater than zero, add it to the money string with the gold symbol
	if gold > 0 then
		moneyString = format("%d%s ", gold, GOLD_AMOUNT_SYMBOL)
	end

	-- If the amount of silver is greater than zero or there is gold, add it to the money string with the silver symbol
	if silver > 0 or gold > 0 then
		moneyString = format("%s%d%s ", moneyString, silver, SILVER_AMOUNT_SYMBOL)
	end

	-- Add the amount of copper to the money string with the copper symbol
	moneyString = format("%s%d%s", moneyString, copper, COPPER_AMOUNT_SYMBOL)

	-- Return the completed money string
	return moneyString
end

local function autoRepair(override)
	-- If the auto-repair frame is already shown and not overridden, return
	if isShown and not override then
		return
	end

	-- Set the auto-repair frame to be shown
	isShown = true

	-- Reset the isBankEmpty variable
	isBankEmpty = false

	-- Get the player's current amount of money
	local myMoney = getMoney()

	-- Get the cost of repairing all items and whether or not they can be repaired
	repairAllCost, canRepair = getRepairAllCost()

	-- If the items can be repaired and have a cost...
	if canRepair and repairAllCost > 0 then
		-- If QuickRepairSellDB.useGuildFunds is true, the player is in a guild, and the guild bank has enough money...
		if not override and QuickRepairSellDB.useGuildFunds and isInGuild() and canGuildBankRepair() and getGuildBankWithdrawMoney() >= repairAllCost then
			-- Repair all items using guild bank funds
			repairAllItems(true)
		else
			-- If the player has enough money to repair all items, repair them and print the cost
			if myMoney > repairAllCost then
				repairAllItems()
				print(stringFormat("|cffffff00Your items have been repaired for:|r %s", formatMoneyString(repairAllCost)))
				return
			else
				-- If the player doesn't have enough money, print a message and return
				print(stringFormat("You don't have enough money to repair, %s", UnitName("player")))
				return
			end
		end

		-- Wait 0.5 seconds and check if the bank is empty
		cTimerAfter(0.5, function()
			if isBankEmpty then
				-- If the bank is empty, call autoRepair with override set to true
				autoRepair(true)
			else
				-- If the bank has enough money to repair, print the cost
				print(stringFormat("|cffffff00Your items have been repaired using guild bank funds for: %s|r", formatMoneyString(repairAllCost)))
			end
		end)
	end
end

local function checkBankFund(_, msgType)
	-- If the error message type is "not enough money in guild bank"...
	if msgType == leGameErrGuildNotEnoughMoney then
		-- Set isBankEmpty to true
		isBankEmpty = true
	end
end

local function merchantClose()
	-- Set the auto-repair frame to not be shown
	isShown = false

	-- Unregister the UI_ERROR_MESSAGE and MERCHANT_CLOSED events for the auto-repair frame
	AutoRepairFrame:UnregisterEvent("UI_ERROR_MESSAGE")
	AutoRepairFrame:UnregisterEvent("MERCHANT_CLOSED")
end

local function merchantShow()
	-- If the shift key is pressed, auto-repair is not enabled, or the merchant cannot repair items, return
	if isShiftKeyDown() or not QuickRepairSellDB.autoRepairEnabled or not canMerchantRepair() then
		return
	end

	-- Call the autoRepair function
	autoRepair()

	-- Register the UI_ERROR_MESSAGE and MERCHANT_CLOSED events for the auto-repair frame
	AutoRepairFrame:RegisterEvent("UI_ERROR_MESSAGE")
	AutoRepairFrame:RegisterEvent("MERCHANT_CLOSED")
end

local function createAutoRepair()
	-- Register the MERCHANT_SHOW event for the auto-repair frame
	AutoRepairFrame:RegisterEvent("MERCHANT_SHOW")
end

function AutoRepairFrame:OnEvent(event, ...)
	-- If the event is PLAYER_LOGIN, call createAutoRepair
	if event == "PLAYER_LOGIN" then
		createAutoRepair()
	-- If the event is MERCHANT_SHOW, call merchantShow
	elseif event == "MERCHANT_SHOW" then
		merchantShow()
	-- If the event is MERCHANT_CLOSED, call merchantClose
	elseif event == "MERCHANT_CLOSED" then
		merchantClose()
	-- If the event is UI_ERROR_MESSAGE, call checkBankFund
	elseif event == "UI_ERROR_MESSAGE" then
		checkBankFund(event, ...)
	end
end

-- Set the OnEvent script for the auto-repair frame
AutoRepairFrame:SetScript("OnEvent", AutoRepairFrame.OnEvent)
