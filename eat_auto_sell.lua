local lastUpdate = 0

local restockItems = {
	[17031] = {10,1}, --传送符文
	[17032] = {10,1}, --传送门符文
	[17020] = {20,1}, --魔粉
	[21177] = {300,1}, --王者印记
	[17033] = {10,1}, --神圣符印
	[13444] = {20,0}, --大蓝 特效法力药水
}

local function moneyToString(totalMoney)
	local gold = floor(abs(totalMoney / 10000))
	local silver = floor(abs(mod(totalMoney / 100, 100)))
	local copper = floor(abs(mod(totalMoney, 100)))
	-- wow has shorthand references to the Lua string library
	return format("%dg %ds %dc", gold, silver, copper)
end

--restock item if in restockItems table
local function purchaseIf(item, index)
	local restockInfo = restockItems[item]
	if not restockInfo then return end
	local maxCount = restockInfo[1]
	local minCount = restockInfo[2]
	
	local curCount = GetItemCount(item)
	if not curCount or curCount<minCount then return end
	if curCount >= maxCount then return end
	
	local need = maxCount - curCount
	local itemName = GetItemInfo(item)
	local maxStack = GetMerchantItemMaxStack(index)
	print(string.format('补充%d个%s，总共%d个。', need, itemName, maxStack))
	
	while need>0 do
		local amount=min(maxStack, need)
		BuyMerchantItem(index, amount)
		need=need-amount
	end
end

local function sell_junk()
	local totalMoney = 0
	for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		--if no container, slots is 0
		for slot = 1, slots do
			local item_id = GetContainerItemID(container, slot)
			if item_id ~= nil then
				local texture, count, locked, quality, readable, lootable, link, isFiltered = GetContainerItemInfo(container, slot)
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(item_id)
				
				--is junk
				if quality == 0 then
					UseContainerItem(container, slot)
					totalMoney = totalMoney + itemSellPrice * count
					--print(itemName, itemSellPrice * count)
				end
			end
		end
	end
	
	--print money gain
	if totalMoney > 0 then
		print('selling junk gains', moneyToString(totalMoney))
	end
	
	--repair
	if CanMerchantRepair() then
		local cost = GetRepairAllCost()
		if cost > 0 then
			RepairAllItems()
			print('repair costs', moneyToString(cost))
		end
	end
	
	local numItems = GetMerchantNumItems()
	for index = 1, numItems do
		local itemID = GetMerchantItemID(index)
		purchaseIf(itemID, index)
	end
end

local function destroy_items()
	for container = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
		local slots = GetContainerNumSlots(container)
		--if no container, slots is 0
		for slot = 1, slots do
			local item_id = GetContainerItemID(container, slot)
			if item_id ~= nil then
				local texture, count, locked, quality, readable, lootable, link, isFiltered = GetContainerItemInfo(container, slot)
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(item_id)
				
				--need destroy
				if itemName == 'Mark of Aquaos' then
					--PickupContainerItem(bagID, slot)
					PickupItem(itemName)
					DeleteCursorItem()
					print(itemName, 'destroyed')
				end
			end
		end
	end
end

function autosell_destroy(targetItemName)
	
	local character_containers = {0, 1, 2, 3, 4}
	
	for _, container in ipairs(character_containers) do
		local slots = GetContainerNumSlots(container)
		--if no container, slots is 0
		for slot = 1, slots do
			local item_id = GetContainerItemID(container, slot)
			if item_id ~= nil then
				local texture, count, locked, quality, readable, lootable, link, isFiltered = GetContainerItemInfo(container, slot)
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(item_id)
				local bagType = GetItemFamily(item_id)
				if itemName == targetItemName then
					print('found, destroying', targetItemName)
					PickupContainerItem(container, slot)
					DeleteCursorItem()
				end
			end
		end
	end
end

--local e,m,n,f=EnumerateFrames,MouseIsOver;ChatFrame1:AddMessage("The mouse is over the following frames:");f=e();while f do n=f:GetName();if n and f:IsVisible()and m(f) then ChatFrame1:AddMessage("   - "..n) end f=e(f) end

local function onUpdate(self, elapsed)
	local now = time();
	if now - lastUpdate >= 1 then
		lastUpdate = time();
		
		
	end
end

local function onEvent(self, event, ...)
	if event == "MERCHANT_SHOW" then
		sell_junk()
	elseif event == "BAG_UPDATE" then
		print("BAG_UPDATE", GetTime())
	elseif event == "BAG_UPDATE_DELAYED" then
		print("BAG_UPDATE_DELAYED", GetTime())
	elseif event == "ITEM_PUSH" then
		print("ITEM_PUSH", GetTime())
		--destroy_items()
	end
end

--create a frame for receiving events
CreateFrame("FRAME", "eat_auto_sell_frame");
eat_auto_sell_frame:RegisterEvent("MERCHANT_SHOW");
--cas_frame:RegisterEvent("BAG_UPDATE");
--cas_frame:RegisterEvent("BAG_UPDATE_DELAYED");
--cas_frame:RegisterEvent("ITEM_PUSH");
eat_auto_sell_frame:SetScript("OnEvent", onEvent);
