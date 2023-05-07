local _, Juwe = ...;

local Item = Item;
local PROFESSIONS_RECRAFT_ORDER_NAME_FMT = PROFESSIONS_RECRAFT_ORDER_NAME_FMT;

Juwe.OnAddonLoaded("Blizzard_ProfessionsCustomerOrders", function()
	local Professions = Professions;

	local wasFavoritesSearch = C_CraftingOrders.HasFavoriteCustomerOptions();

	Juwe.CreateToggleButton(ProfessionsCustomerOrdersFrame, function()
		ProfessionsCustomerOrdersFrame.BrowseOrders:StartSearch(wasFavoritesSearch);
	end);

	-- executes after ProfessionsCustomerTableCellItemNameMixin:Populate
	local function populateHook(self, rowData, dataIndex)
		local order = rowData.option;

		Juwe.GetGemStats(Item:CreateFromItemID(order.itemID), function(item, stats)
			local qualityColor = item:GetItemQualityColor().color;
			local itemName = qualityColor:WrapTextInColorCode(stats);
			if order.isRecraft then
				itemName = PROFESSIONS_RECRAFT_ORDER_NAME_FMT:format(itemName);
			end
			if order.minQuality and order.minQuality > 1 then
				itemName = itemName.." "..Professions.GetChatIconMarkupForQuality(order.minQuality, true);
			end

			self.Text:SetText(itemName);
		end);
	end

	-- executes after ProfessionsCustomerOrdersBrowsePageMixin:StartSearch
	local function startSearchHook(self, isFavoritesSearch)
		wasFavoritesSearch = isFavoritesSearch;
	end

	hooksecurefunc(ProfessionsCustomerTableCellItemNameMixin, "Populate", populateHook);
	hooksecurefunc(ProfessionsCustomerOrdersFrame.BrowseOrders, "StartSearch", startSearchHook);
end);
