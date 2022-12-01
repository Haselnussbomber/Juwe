--[[ * Juwe * ]]--

local _G = _G;
local C_TooltipInfo = C_TooltipInfo;
local ContinuableContainer = ContinuableContainer;
local GetItemInfoInstant = GetItemInfoInstant;
local Item = Item;
local RETRIEVING_ITEM_INFO = RETRIEVING_ITEM_INFO;
local TooltipUtil = TooltipUtil;

local initialized = false;
local isJewelcrafting = false;
local isDisabled = false;
local cache = {};

local toggleButton = CreateFrame("Button", "JuweToggleButton", ProfessionsFrame, "UIPanelButtonTemplate");
toggleButton:SetPoint("TOPRIGHT", ProfessionsFrame.CloseButton, "TOPLEFT", 0, -4);
toggleButton:SetFrameLevel(ProfessionsFrame.TitleContainer:GetFrameLevel() + 10);
toggleButton:SetSize(20, 15);
toggleButton:SetText("J");
toggleButton:SetScript("OnClick", function()
	isDisabled = not isDisabled;
	ProfessionsFrame.CraftingPage:Init(ProfessionsFrame:GetProfessionInfo());
	ProfessionsFrame.OrdersPage:Init(ProfessionsFrame:GetProfessionInfo());
end);

local function GetGemStats(item)
	if (not item) then
		return false;
	end

	local itemID = item:GetItemID();

	if (cache[itemID] ~= nil and cache[itemID] == false) then
		return false;
	end

	local itemData = C_TooltipInfo.GetItemByID(itemID);
	if (not itemData) then
		return false;
	end

	-- scan tooltip lines
	for i, lineData in ipairs(itemData.lines) do
		TooltipUtil.SurfaceArgs(lineData);

		if (lineData.leftText) then
			if (lineData.leftText == RETRIEVING_ITEM_INFO) then
				return false;
			end

			local lineMatch = lineData.leftText:match("^(%+?[0-9]+.*) |A") or lineData.leftText:match("^%+?[0-9]+.*");
			if (lineMatch) then
				cache[itemID] = lineMatch;
				return lineMatch;
			end
		end
	end

	-- no stats were found
	cache[itemID] = false;
	return false;
end

-- executes after ProfessionsCraftingPageMixin:Init or ProfessionsCraftingOrderPageMixin:Init
local function InitHook(self, professionInfo)
	isJewelcrafting = professionInfo.profession == 12;
	toggleButton:SetShown(isJewelcrafting);

	if (isDisabled or not isJewelcrafting) then
		return;
	end

	local recipeList = (self.BrowseFrame and self.BrowseFrame.RecipeList) or self.RecipeList;
	local dataProvider = recipeList.ScrollBox:GetDataProvider();
	local items = {};
	local hasItems = false;

	for index, node in dataProvider:Enumerate() do
		local data = node:GetData();
		if (data and data.recipeInfo and data.recipeInfo.recipeID and data.recipeInfo.hyperlink) then
			local itemID, _, _, _, _, classID = GetItemInfoInstant(data.recipeInfo.hyperlink);
			if (itemID and classID == 3) then -- only process gems
				items[data.recipeInfo.recipeID] = Item:CreateFromItemLink(data.recipeInfo.hyperlink);
				hasItems = true;
			end
		end
	end

	if (not hasItems) then
		return;
	end

	-- wait for items to load
	local continuableContainer = ContinuableContainer:Create();
	continuableContainer:AddContinuables(items);
	continuableContainer:ContinueOnLoad(function()
		for index, node in dataProvider:Enumerate() do
			local data = node:GetData();
			if (data and data.recipeInfo and data.recipeInfo.recipeID) then
				local item = items[data.recipeInfo.recipeID];
				if (item) then
					local stats = GetGemStats(item);
					if (stats) then
						data.recipeInfo.name = stats;
					end
				end
			end
		end

		recipeList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition);
	end);
end

hooksecurefunc(ProfessionsFrame.CraftingPage, "Init", InitHook);
hooksecurefunc(ProfessionsFrame.OrdersPage, "Init", InitHook);
