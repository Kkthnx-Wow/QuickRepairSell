local addonName, addon = ...

local frame = CreateFrame("Frame", addonName)
frame:RegisterEvent("PLAYER_LOGIN")

local cTimerAfter = C_Timer.After
local canGuildBankRepair = CanGuildBankRepair
local canMerchantRepair = CanMerchantRepair
local getGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local getMoney = GetMoney
local getRepairAllCost = GetRepairAllCost
local isInGuild = IsInGuild
local isShiftKeyDown = IsShiftKeyDown
local leGameErrGuildNotEnoughMoney = LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY
local repairAllItems = _G.RepairAllItems
local stringFormat = string.format

-- Auto repair
local autoRepair -- function that handles the repair of all items
local canRepair -- boolean indicating if repair is possible
local isBankEmpty -- boolean indicating if guild bank is empty
local isShown -- boolean indicating if the function is currently shown
local repairAllCost -- cost to repair all items

local GOLD_AMOUNT_SYMBOL = format("|cffffd700%s|r", GOLD_AMOUNT_SYMBOL)
local SILVER_AMOUNT_SYMBOL = format("|cffd0d0d0%s|r", SILVER_AMOUNT_SYMBOL)
local COPPER_AMOUNT_SYMBOL = format("|cffc77050%s|r", COPPER_AMOUNT_SYMBOL)

local function formatMoneyString(money, shortFormat)
	if not money or type(money) ~= "number" then
		return ""
	end

	local gold, silver, copper = math.floor(money / 10000), math.floor((money % 10000) / 100), money % 100
	local moneyString = ""

	if gold > 0 then
		moneyString = format("%d%s ", gold, GOLD_AMOUNT_SYMBOL)
	end

	if silver > 0 or gold > 0 then
		moneyString = format("%s%d%s ", moneyString, silver, SILVER_AMOUNT_SYMBOL)
	end

	moneyString = format("%s%d%s", moneyString, copper, COPPER_AMOUNT_SYMBOL)

	return moneyString
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
		if not override and QuickRepairSellDB.useGuildFunds and isInGuild() and canGuildBankRepair() and getGuildBankWithdrawMoney() >= repairAllCost then
			repairAllItems(true)
		else
			if myMoney > repairAllCost then
				repairAllItems()
				print(stringFormat("|cffffff00Your items have been repaired for:|r %s", formatMoneyString(repairAllCost)))
			else
				print(stringFormat("You don't have enough money to repair, %s", UnitName("player")))
			end
		end

		cTimerAfter(0.5, function()
			if isBankEmpty then
				autoRepair(true)
			else
				print(stringFormat("|cffffff00Your items have been repaired using guild bank funds for: %s|r", formatMoneyString(repairAllCost)))
			end
		end)
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
	if isShiftKeyDown() or not QuickRepairSellDB.autoRepairEnabled or not canMerchantRepair() then
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
