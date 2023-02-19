local addonName, addon = ...

-- Fix FormatMoneyString
-- Add options panel

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

local string_format = string.format

local C_Timer_After = C_Timer.After
local CanGuildBankRepair = CanGuildBankRepair
local CanMerchantRepair = CanMerchantRepair
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetMoney = GetMoney
local GetRepairAllCost = GetRepairAllCost
local IsInGuild = IsInGuild
local IsShiftKeyDown = IsShiftKeyDown
local LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY = LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY

-- Auto repair
local autoRepair -- function that handles the repair of all items
local canRepair -- boolean indicating if repair is possible
local isBankEmpty -- boolean indicating if guild bank is empty
local isShown -- boolean indicating if the function is currently shown
local repairAllCost -- cost to repair all items

local AutoRepair = {
	NONE = false,
	GUILD = true,
	PLAYER = true,
}

-- We have to fix this
local YELLOW_FONT_COLOR_CODE = "|cffffff00"
local GOLD_COLOR = "|cffffd700"
local SILVER_COLOR = "|cffd0d0d0"
local COPPER_COLOR = "|cffc77050"
local GOLD_AMOUNT_SYMBOL = GOLD_COLOR .. GOLD_AMOUNT_SYMBOL .. "|r"
local SILVER_AMOUNT_SYMBOL = SILVER_COLOR .. SILVER_AMOUNT_SYMBOL .. "|r"
local COPPER_AMOUNT_SYMBOL = COPPER_COLOR .. COPPER_AMOUNT_SYMBOL .. "|r"

local function FormatMoneyString(money, shortFormat)
	if money >= 1e6 and not shortFormat then
		local formattedMoney = BreakUpLargeNumbers(format("%d", money / 1e4))
		return formattedMoney .. GOLD_AMOUNT_SYMBOL
	else
		if money > 0 then
			local moneyString = ""
			local gold = floor(money / 1e4)
			local silver = floor(money / 100) % 100
			local copper = money % 100

			if gold > 0 then
				moneyString = " " .. gold .. GOLD_AMOUNT_SYMBOL
			end

			if silver > 0 then
				moneyString = moneyString .. " " .. silver .. SILVER_AMOUNT_SYMBOL
			end

			if copper > 0 then
				moneyString = moneyString .. " " .. copper .. COPPER_AMOUNT_SYMBOL
			end

			return moneyString
		else
			return " 0" .. COPPER_AMOUNT_SYMBOL
		end
	end
end

local function delayFunc()
	-- Check if the guild bank is empty
	if isBankEmpty then
		-- Call the autoRepair function with the override argument set to true
		autoRepair(true)
	else
		-- Print a message indicating that the repair was done with the guild bank
		print(string_format("%s%s", YELLOW_FONT_COLOR_CODE, "Your items have been repaired using guild bank funds for: ", FormatMoneyString(repairAllCost)))
	end
end

function autoRepair(override)
	-- If the function is already shown and override is not set, return immediately
	if isShown and not override then
		return
	end

	-- set isShown to true and isBankEmpty to false
	isShown = true
	isBankEmpty = false

	-- Get the player's current money
	local myMoney = GetMoney()

	-- Get the cost to repair all items and check if repair is possible
	repairAllCost, canRepair = GetRepairAllCost()

	-- If repair is possible and there is a cost to repair
	if canRepair and repairAllCost > 0 then
		-- If override is not set, check if C["Inventory"].AutoRepair.Value is 1 and the player is in a guild and the guild bank can repair
		if not override and AutoRepair.GUILD and IsInGuild() and CanGuildBankRepair() and GetGuildBankWithdrawMoney() >= repairAllCost then
			_G.RepairAllItems(true)
		else
			-- If the player has enough money, repair the items and print a message
			if myMoney > repairAllCost then
				_G.RepairAllItems()
				print(string_format("%s%s", YELLOW_FONT_COLOR_CODE, "Your items have been repaired for:|r ", FormatMoneyString(repairAllCost)))
				return
			else
				-- If the player doesn't have enough money, print a message
				print("You don't have enough money to repair,|r " .. UnitName("player"))
				return
			end
		end

		-- Wait 0.5 seconds before calling delayFunc
		C_Timer_After(0.5, delayFunc)
	end
end

local function checkBankFund(_, msgType)
	-- Check if the message type is indicating that the guild doesn't have enough money
	if msgType == LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY then
		-- Set the isBankEmpty variable to true
		isBankEmpty = true
	end
end

local function merchantClose()
	-- Set isShown to false
	isShown = false
	-- Unregister the UI_ERROR_MESSAGE event
	frame:UnregisterEvent("UI_ERROR_MESSAGE")
	-- Unregister the MERCHANT_CLOSED event
	frame:UnregisterEvent("MERCHANT_CLOSED")
end

local function merchantShow()
	-- If shift key is down or C["Inventory"].AutoRepair.Value is 0 or the merchant can't repair, return
	if IsShiftKeyDown() or AutoRepair.NONE or not CanMerchantRepair() then
		return
	end

	-- Call the autoRepair function
	autoRepair()
	-- Register the UI_ERROR_MESSAGE event
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	-- Register the MERCHANT_CLOSED event
	frame:RegisterEvent("MERCHANT_CLOSED")
end

local function CreateAutoRepair()
	-- Register the MERCHANT_SHOW event
	frame:RegisterEvent("MERCHANT_SHOW")
end

function frame:OnEvent(event, ...)
	print(event)
	if event == "PLAYER_LOGIN" then
		CreateAutoRepair()
	elseif event == "MERCHANT_SHOW" then
		merchantShow()
	elseif event == "MERCHANT_CLOSED" then
		merchantClose()
	elseif event == "UI_ERROR_MESSAGE" then
		checkBankFund(...)
	end
end

frame:SetScript("OnEvent", frame.OnEvent)
