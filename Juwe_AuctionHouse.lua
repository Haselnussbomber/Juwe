local _, Juwe = ...;

local Item = Item;

Juwe.OnAddonLoaded("Blizzard_AuctionHouseUI", function()
	Juwe.CreateToggleButton(AuctionHouseFrame, function()
		AuctionHouseFrame.BrowseResultsFrame.ItemList.tableBuilder:Arrange();
	end);

	-- executes after AuctionHouseTableCellItemDisplayMixin:UpdateDisplay
	local function updateDisplayHook(self, itemKey, itemKeyInfo)
		Juwe.GetGemStats(Item:CreateFromItemID(itemKey.itemID), function(item, stats)
			itemKeyInfo.itemName = stats;
			self.Text:SetText(AuctionHouseUtil.GetItemDisplayTextFromItemKey(itemKey, itemKeyInfo, self.hideItemLevel, self.rowData));
		end);
	end

	hooksecurefunc(AuctionHouseTableCellItemDisplayMixin, "UpdateDisplay", updateDisplayHook);
end);
