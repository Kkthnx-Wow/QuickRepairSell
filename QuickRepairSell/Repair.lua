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
-- local autoRepair -- function that handles the repair of all items
-- local canRepair -- boolean indicating if repair is possible
local isBankEmpty -- boolean indicating if guild bank is empty
local isShown -- boolean indicating if the function is currently shown
local repairAllCost -- cost to repair all items

local stringFormat = string.format
local cTimerAfter = C_Timer.After
local canGuildBankRepair = CanGuildBankRepair
local canMerchantRepair = CanMerchantRepair
local getGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local getMoney = GetMoney
local getRepairAllCost = GetRepairAllCost
local isShiftKeyDown = IsShiftKeyDown
local isInGuild = IsInGuild
local leGameErrGuildNotEnoughMoney = LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY
local repairAllItems = _G.RepairAllItems

local autoRepairOptions = {
	none = false,
	guild = true,
	player = true,
}

local moneyFormat = {
	gold = "|cffffd700%s|r",
	silver = "|cffd0d0d0%s|r",
	copper = "|cffc77050%s|r",
}

local function formatMoneyString(money, shortFormat)
	if money >= 1e6 and not shortFormat then
		local formattedMoney = BreakUpLargeNumbers(stringFormat("%d", money / 1e4))
		return stringFormat("%s%s", formattedMoney, moneyFormat.gold)
	else
		if money > 0 then
			local moneyString = ""
			local gold = floor(money / 1e4)
			local silver = floor(money / 100) % 100
			local copper = money % 100

			if gold > 0 then
				moneyString = stringFormat(" %d%s", gold, moneyFormat.gold)
			end

			if silver > 0 then
				moneyString = stringFormat("%s %d%s", moneyString, silver, moneyFormat.silver)
			end

			if copper > 0 then
				moneyString = stringFormat("%s %d%s", moneyString, copper, moneyFormat.copper)
			end

			return moneyString
		else
			return stringFormat(" 0%s", moneyFormat.copper)
		end
	end
end

local function delayFunc()
	if isBankEmpty then
		repairAllItems(true)
	else
		print(
			stringFormat(
				"|cffffff00Your items have been repaired using guild bank funds for: %s|r",
				formatMoneyString(repairAllCost)
			)
		)
	end
end

local function autoRepair(override)
	if isShown and not override then
		return
	end

	isShown = true
	isBankEmpty = false

	local myMoney = getMoney()

	local repairAllCost, canRepair = getRepairAllCost()

	if canRepair and repairAllCost > 0 then
		if
			not override
			and autoRepairOptions.guild
			and isInGuild()
			and canGuildBankRepair()
			and getGuildBankWithdrawMoney() >= repairAllCost
		then
			repairAllItems(true)
		else
			if myMoney > repairAllCost then
				repairAllItems()
				print(
					stringFormat("|cffffff00Your items have been repaired for:|r %s", formatMoneyString(repairAllCost))
				)
			else
				print(stringFormat("You don't have enough money to repair,|r %s", UnitName("player")))
			end
		end

		cTimerAfter(0.5, delayFunc)
	end
end

local function checkBankFund(_, msgType)
	if msgType == leGameErrGuildNotEnoughMoney then
		isBankEmpty = true
	end
end

local function merchantClose()
	isShown = false
	frame:UnregisterEvent("UI_ERROR_MESSAGE")
	frame:UnregisterEvent("MERCHANT_CLOSED")
end

local function merchantShow()
	if isShiftKeyDown() or autoRepairOptions.none or not canMerchantRepair() then
		return
	end

	autoRepair()
	frame:RegisterEvent("UI_ERROR_MESSAGE")
	frame:RegisterEvent("MERCHANT_CLOSED")
end

local function createAutoRepair()
	frame:RegisterEvent("MERCHANT_SHOW")
end

function frame:OnEvent(event, ...)
	if event == "PLAYER_LOGIN" then
		createAutoRepair()
	elseif event == "MERCHANT_SHOW" then
		merchantShow()
	elseif event == "MERCHANT_CLOSED" then
		merchantClose()
	elseif event == "UI_ERROR_MESSAGE" then
		checkBankFund(event, ...)
	end
end

frame:SetScript("OnEvent", frame.OnEvent)
