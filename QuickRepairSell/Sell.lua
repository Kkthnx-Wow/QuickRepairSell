local addonName, addon = ...

-- Add selling code
-- Add options panel
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

local table_wipe = table.wipe

local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_UseContainerItem = C_Container.UseContainerItem
local C_Timer_After = C_Timer.After
local C_TransmogCollection_GetItemInfo = C_TransmogCollection.GetItemInfo
local IsShiftKeyDown = IsShiftKeyDown

local petTrashCurrenies = {
	[3300] = true,
	[3670] = true,
	[6150] = true,
	[11406] = true,
	[11944] = true,
	[25402] = true,
	[36812] = true,
	[62072] = true,
	[67410] = true,
}

local isKnownString = {
	[TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN] = true,
	[TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN] = true,
}

local function IsUnknownTransmog(bagID, slotID)
	local tooltipData = C_TooltipInfo.GetBagItem(bagID, slotID)
	if not tooltipData or not tooltipData.lines then
		return
	end

	for i = #tooltipData.lines, 1, -1 do
		local line = tooltipData.lines[i]
		if line and line.args then
			local argAppearanceString = line.args[2] and line.args[2].stringVal
			local argPrice = line.args[4] and line.args[4].field == "price"
			if argPrice then
				return false
			elseif argAppearanceString and isKnownString[argAppearanceString] then
				return true
			end
		end
	end
end

local stop = true -- a flag used to stop the selling process
local cache = {} -- a table used to store items that have already been processed
local errorText = ERR_VENDOR_DOESNT_BUY -- error message for when the vendor doesn't buy certain items

local function startSelling()
	-- if the stop flag is set, exit the function
	if stop then
		return
	end

	-- loop through all bags
	for bag = 0, 5 do
		-- loop through all slots in the current bag
		for slot = 1, C_Container_GetContainerNumSlots(bag) do
			-- if the stop flag is set, exit the function
			if stop then
				return
			end

			-- get information about the item in the current slot
			local info = C_Container_GetContainerItemInfo(bag, slot)
			if info then
				if not cache["b" .. bag .. "s" .. slot] and info.hyperlink and not info.hasNoValue and (info.quality == 0 and not petTrashCurrenies[info.itemID] and (not C_TransmogCollection_GetItemInfo(info.hyperlink) or not IsUnknownTransmog(bag, slot))) then
					cache["b" .. bag .. "s" .. slot] = true
					C_Container_UseContainerItem(bag, slot)
					C_Timer_After(0.15, startSelling)
					return
				end
			end
		end
	end
end

local function updateSelling(event, ...)
	if not QuickRepairSellDB.autoSellEnabled then
		return
	end

	local _, arg = ...
	if event == "MERCHANT_SHOW" then
		-- exit if shift key is pressed
		local shiftKeyDown = IsShiftKeyDown()
		if shiftKeyDown then
			return
		end

		-- start selling items
		stop = false
		table_wipe(cache)
		-- start selling items
		startSelling()
		-- register for error messages and merchant close events
		frame:RegisterEvent("UI_ERROR_MESSAGE")
	elseif event == "UI_ERROR_MESSAGE" and arg == errorText or event == "MERCHANT_CLOSED" then
		-- set stop flag to true
		stop = true
	end
end

local function CreateAutoSell()
	frame:RegisterEvent("MERCHANT_SHOW")
	frame:RegisterEvent("MERCHANT_CLOSED")
end

function frame:OnEvent(event, ...)
	if event == "PLAYER_LOGIN" then
		CreateAutoSell()
	elseif event == "MERCHANT_SHOW" then
		updateSelling(event, ...)
	elseif event == "MERCHANT_CLOSED" then
		updateSelling(event, ...)
	elseif event == "UI_ERROR_MESSAGE" then
		updateSelling(event, ...)
	end
end

frame:SetScript("OnEvent", frame.OnEvent)
