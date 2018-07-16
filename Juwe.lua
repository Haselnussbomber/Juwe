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
};

-- executes after TradeSkillRecipeButtonMixin:SetUpRecipe
local function SetUpRecipeHook(self, textWidth, tradeSkillInfo)
	local stats = Juwe:GetGemStats(tradeSkillInfo.recipeID);
	if (not stats) then
		return;
	end

	-- replace name with gem stats
	tradeSkillInfo.name = stats;

	-- call original function again to correctly set new name
	TradeSkillRecipeButtonMixin.SetUpRecipe(self, textWidth, tradeSkillInfo);
end

--[[ Event Handler ]]--

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

	-- buttons are being reused, so we only need to hook each once
	for i, btn in ipairs(TradeSkillFrame.RecipeList.buttons) do
		hooksecurefunc(btn, "SetUpRecipe", SetUpRecipeHook);
	end

	self.initialized = true;
end

function Juwe:TRADE_SKILL_DATA_SOURCE_CHANGED()
	if (not self.initialized) then
		return;
	end

	local tradeSkillID = C_TradeSkillUI_GetTradeSkillLine();
	self.isJewelcrafting = tContains(JEWELCRAFTING_SKILL_IDS, tradeSkillID);

	if (self.toggleButton) then
		self.toggleButton:SetShown(self.isJewelcrafting);
	end
end

function Juwe:GET_ITEM_INFO_RECEIVED()
	if (not self.initialized or self.refreshCooldown) then
		return;
	end

	-- only 1 update per frame
	self.refreshCooldown = true;
	C_Timer.After(0, function()
		self.refreshCooldown = false;
		TradeSkillFrame.RecipeList:RefreshDisplay();
	end);
end

--[[ Juwe Functions ]]--

function Juwe:GetGemStats(id)
	if (self.isDisabled or not self.isJewelcrafting or not id) then
		return;
	end

	local cached = cache[id];
	if (cached ~= nil) then
		return cached;
	end

	-- request recipe result item
	tooltip:SetRecipeResultItem(id);
	if (not tooltip:IsShown()) then
		return;
	end

	-- get recipe result item
	local name, link = tooltip:GetItem();
	if (name == "") then
		-- sometimes we don't get any item data immediately
		-- this happens for example when changing to the unlearned tab
		-- the game queues up GetItem() requests and later fires GET_ITEM_INFO_RECEIVED
		return;
	end

	-- process gems only
	local itemClassId = select(12, GetItemInfo(link));
	if (itemClassId ~= LE_ITEM_CLASS_GEM) then
		-- not a gem => cache and return
		cache[id] = false;
		return cache[id];
	end

	-- scan tooltip lines for stats
	for i=2, tooltip:NumLines() do
		local lineFrame = _G[tooltip:GetName().."TextLeft"..i];
		local lineText = lineFrame:GetText() or "";
		local lineMatch = string_match(lineText, "^%+?[0-9]+.*");
		if (lineMatch) then
			-- stats found => cache and return
			cache[id] = lineMatch;
			return cache[id];
		end
	end
end
