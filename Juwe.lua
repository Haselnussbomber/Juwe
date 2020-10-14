--[[ * Juwe * ]]--

local _G = _G;
local select = select;
local string_match = string.match;
local tContains = tContains;
local GetItemInfo = GetItemInfo;
local C_TradeSkillUI_GetTradeSkillLine = C_TradeSkillUI.GetTradeSkillLine;
local LE_ITEM_CLASS_GEM = LE_ITEM_CLASS_GEM;

local Juwe = CreateFrame("Frame", "Juwe");
Juwe:RegisterEvent("ADDON_LOADED");
Juwe:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED");
Juwe:RegisterEvent("GET_ITEM_INFO_RECEIVED");
Juwe:SetScript("OnEvent", function(self, event, ...)
	if (self[event]) then
		self[event](self, ...);
	end
end);

Juwe.isJewelcrafting = false;
Juwe.isDisabled = false;

local cache = {};
Juwe.cache = cache;

local tooltip = CreateFrame("GameTooltip", "JuweTooltip", nil, "GameTooltipTemplate");
tooltip:SetOwner(UIParent, "ANCHOR_NONE");
Juwe.tooltip = tooltip;

local JEWELCRAFTING_SKILL_IDS = {
	2524, -- Jewelcrafting
	2523, -- Outland Jewelcrafting
	2522, -- Northrend Jewelcrafting
	2521, -- Cataclysm Jewelcrafting
	2520, -- Pandaria Jewelcrafting
	2519, -- Draenor Jewelcrafting
	2518, -- Legion Jewelcrafting
	2517, -- Kul Tiran Jewelcrafting (Alliance) / Zandalari Jewelcrafting (Horde)
	2757, -- Shadowlands Jewelcrafting
};

--[[ Hooks ]]--

-- executes after TradeSkillRecipeListMixin:RebuildDataList
local function RebuildDataListHook(self)
	if (Juwe.isDisabled or not Juwe.isJewelcrafting) then
		return;
	end

	for i in ipairs(self.dataList) do
		if (self.dataList[i].type == "recipe") then
			local stats = Juwe:GetGemStats(self.dataList[i].recipeID);
			if (stats.valid) then
				self.dataList[i].name = stats.text;
			end
		end
	end
end

--[[ Event Handler ]]--

function Juwe:OnUpdate()
	if (not self.pendingRefresh) then
		return;
	end

	self.pendingRefresh = false;

	if (Juwe.isDisabled or not Juwe.isJewelcrafting or not TradeSkillFrame:IsShown()) then
		return;
	end

	RebuildDataListHook(TradeSkillFrame.RecipeList);
	TradeSkillFrame.RecipeList:RefreshDisplay();
end

function Juwe:ADDON_LOADED(name)
	if (self.initialized or name ~= "Blizzard_TradeSkillUI") then
		return;
	end

	local toggleButton = CreateFrame("Button", "JuweToggleButton", TradeSkillFrame, "UIPanelButtonTemplate");
	self.toggleButton = toggleButton;
	toggleButton:SetPoint("TOPRIGHT", TradeSkillFrameCloseButton, "TOPLEFT", 0, -8);
	toggleButton:SetSize(15, 15);
	toggleButton:SetText("J");
	toggleButton:SetScript("OnClick", function()
		self.isDisabled = not self.isDisabled;
		TradeSkillFrame.RecipeList:Refresh();
	end);

	hooksecurefunc(TradeSkillFrame.RecipeList, "RebuildDataList", RebuildDataListHook);

	Juwe:SetScript("OnUpdate", self.OnUpdate);

	self.initialized = true;
end

function Juwe:TRADE_SKILL_DATA_SOURCE_CHANGED()
	if (not self.initialized or not TradeSkillFrame:IsShown()) then
		return;
	end

	local tradeSkillID = C_TradeSkillUI_GetTradeSkillLine();
	self.isJewelcrafting = tContains(JEWELCRAFTING_SKILL_IDS, tradeSkillID);

	if (self.toggleButton) then
		self.toggleButton:SetShown(self.isJewelcrafting);
	end
end

function Juwe:GET_ITEM_INFO_RECEIVED()
	if (self.initialized and TradeSkillFrame:IsShown()) then
		self.pendingRefresh = true;
	end
end

--[[ Juwe Functions ]]--

function Juwe:GetGemStats(id)
	if (not id) then
		return;
	end

	-- get or create cached recipe
	cache[id] = cache[id] or {
		retries = 0,
		valid = nil,
		text = nil
	};

	-- return if not a gem or tried multiple times to get info
	if (cache[id].valid == false or cache[id].retries > 3) then
		return cache[id];
	end

	cache[id].retries = cache[id].retries + 1;

	-- request recipe result item
	tooltip:SetRecipeResultItem(id);
	if (not tooltip:IsShown()) then
		return cache[id];
	end

	-- get recipe result item
	local name, link = tooltip:GetItem();

	-- most of the time we don't get any item data immediately
	if (not name or not link or name == "") then
		self.pendingRefresh = true;
		return cache[id];
	end

	-- check if item is a gem
	local itemClassId = select(12, GetItemInfo(link));
	cache[id].valid = itemClassId == LE_ITEM_CLASS_GEM;

	-- don't process tooltip if not a gem
	if (cache[id].valid == false) then
		return cache[id];
	end

	-- scan tooltip lines for stats
	for i=2, tooltip:NumLines() do
		local lineFrame = _G[tooltip:GetName().."TextLeft"..i];
		local lineText = lineFrame:GetText() or "";
		local lineMatch = string_match(lineText, "^%+?[0-9]+.*");
		if (lineMatch) then
			cache[id].text = lineMatch; -- stats found
			return cache[id];
		end
	end

	-- invalidate if no stats found (example: Brilliant Scarlet Ruby)
	cache[id].valid = false;
	return cache[id];
end
