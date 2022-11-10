--[[ * Juwe * ]]--

local _G = _G;
local Item = Item;
local ContinuableContainer = ContinuableContainer;
local string_match = string.match;
local GetItemInfoInstant = GetItemInfoInstant;

local initialized = false;
local isJewelcrafting = false;
local isDisabled = false;
local cache = {};

local tooltip = CreateFrame("GameTooltip", "JuweTooltip", nil, "GameTooltipTemplate");
tooltip:SetOwner(UIParent, "ANCHOR_NONE");

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
		return;
	end

	local itemID = item:GetItemID();

	-- get or create cached recipe
	cache[itemID] = cache[itemID] or {
		retries = 0,
		valid = true,
		name = nil
	};

	-- return if no stats found or tried multiple times to get info
	if (cache[itemID].valid == false or cache[itemID].retries > 3) then
		return cache[itemID];
	end

	cache[itemID].retries = cache[itemID].retries + 1;

	-- request item tooltip
	tooltip:SetItemByID(itemID);
	if (not tooltip:IsShown()) then
		return cache[itemID];
	end

	-- scan tooltip lines for stats
	for i=2, tooltip:NumLines() do
		local lineFrame = _G[tooltip:GetName().."TextLeft"..i];
		local lineText = lineFrame:GetText() or "";
		local lineMatch = string_match(lineText, "^%+?[0-9]+.*");
		if (lineMatch) then
			cache[itemID].name = lineMatch; -- stats found
			return cache[itemID];
		end
	end

	-- invalidate if no stats found (example: Brilliant Scarlet Ruby)
	cache[itemID].valid = false;
	return cache[itemID];
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
					if (stats and stats.valid) then
						data.recipeInfo.name = stats.name;
					end
				end
			end
		end

		recipeList.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition);
	end);
end

hooksecurefunc(ProfessionsFrame.CraftingPage, "Init", InitHook);
hooksecurefunc(ProfessionsFrame.OrdersPage, "Init", InitHook);
