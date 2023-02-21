local AutoSellFrame = CreateFrame("Frame")
AutoSellFrame:RegisterEvent("PLAYER_LOGIN")

local table_wipe = table.wipe

local C_Container_GetContainerItemInfo = C_Container.GetContainerItemInfo
local C_Container_GetContainerNumSlots = C_Container.GetContainerNumSlots
local C_Container_UseContainerItem = C_Container.UseContainerItem
local C_Timer_After = C_Timer.After
local C_TransmogCollection_GetItemInfo = C_TransmogCollection.GetItemInfo
local IsShiftKeyDown = IsShiftKeyDown

local stop = true -- a flag used to stop the selling process
local cache = {} -- a table used to store items that have already been processed
local errorText = ERR_VENDOR_DOESNT_BUY -- error message for when the vendor doesn't buy certain items

-- Table of pet trash currencies
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

-- Table of known transmogrification strings
local isKnownString = {
	[TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN] = true,
	[TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN] = true,
}

-- Function to check if an item has an unknown transmogrification appearance
local function IsUnknownTransmog(bagID, slotID)
	-- Get the tooltip data for the item
	local tooltipData = C_TooltipInfo.GetBagItem(bagID, slotID)
	if not tooltipData or not tooltipData.lines then
		return
	end

	-- Loop through the tooltip lines in reverse order
	for i = #tooltipData.lines, 1, -1 do
		local line = tooltipData.lines[i]
		if line and line.args then
			-- Check if the line has an appearance string or a price field
			local argAppearanceString = line.args[2] and line.args[2].stringVal
			local argPrice = line.args[4] and line.args[4].field == "price"
			if argPrice then
				-- If the line has a price field, the appearance is known
				return false
			elseif argAppearanceString and isKnownString[argAppearanceString] then
				-- If the line has an appearance string that matches a known string, the appearance is known
				return true
			end
		end
	end
end

-- Function to start selling items from the player's bags
local function startSelling()
	-- If the stop flag is set, exit the function
	if stop then
		return
	end

	-- Loop through all bags
	for bag = 0, 5 do
		-- Loop through all slots in the current bag
		for slot = 1, C_Container_GetContainerNumSlots(bag) do
			-- If the stop flag is set, exit the function
			if stop then
				return
			end

			-- Get information about the item in the current slot
			local info = C_Container_GetContainerItemInfo(bag, slot)
			if info then
				-- If the item is not in the cache, has a hyperlink, has a value, is not a pet trash currency, is not a known transmogrification appearance, and is of poor quality, sell the item
				if not cache["b" .. bag .. "s" .. slot] and info.hyperlink and not info.hasNoValue and (info.quality == 0 and not petTrashCurrenies[info.itemID] and (not C_TransmogCollection_GetItemInfo(info.hyperlink) or not IsUnknownTransmog(bag, slot))) then
					-- Add the item to the cache
					cache["b" .. bag .. "s" .. slot] = true
					-- Use the item to sell it
					C_Container_UseContainerItem(bag, slot)
					-- Wait for a short time before selling the next item
					C_Timer_After(0.15, startSelling)
					-- Exit the function
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
		AutoSellFrame:RegisterEvent("UI_ERROR_MESSAGE")
	elseif event == "UI_ERROR_MESSAGE" and arg == errorText or event == "MERCHANT_CLOSED" then
		-- set stop flag to true
		stop = true
	end
end

-- Function to register events for auto-selling
local function CreateAutoSell()
	AutoSellFrame:RegisterEvent("MERCHANT_SHOW")
	AutoSellFrame:RegisterEvent("MERCHANT_CLOSED")
end

-- Event handler for auto-selling
function AutoSellFrame:OnEvent(event, ...)
	-- If the event is PLAYER_LOGIN, register the events for auto-selling
	if event == "PLAYER_LOGIN" then
		CreateAutoSell()
	-- If the event is MERCHANT_SHOW, MERCHANT_CLOSED, or UI_ERROR_MESSAGE, update the selling process
	elseif event == "MERCHANT_SHOW" then
		updateSelling(event, ...)
	elseif event == "MERCHANT_CLOSED" then
		updateSelling(event, ...)
	elseif event == "UI_ERROR_MESSAGE" then
		updateSelling(event, ...)
	end
end

-- Set the script for the AutoSellFrame
AutoSellFrame:SetScript("OnEvent", AutoSellFrame.OnEvent)
