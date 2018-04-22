local JuweFrame = CreateFrame("Frame", "Juwe");
JuweFrame:RegisterEvent("ADDON_LOADED");
JuweFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED");

local JuweTooltip = CreateFrame("GameTooltip", "JuweGemStatsTooltip", nil, "GameTooltipTemplate");
JuweTooltip:SetOwner(UIParent, "ANCHOR_NONE");

local JuweToggleButton;
local isDisabled = false;
local isJewelcrafting = false;
local cache = {};

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

local function GetGemStats(id)
	-- request recipe result item
	JuweTooltip:SetRecipeResultItem(id);
	if (not JuweTooltip:IsShown()) then
		return;
	end

	-- get recipe result item
	local name, link = JuweTooltip:GetItem();
	if (name == "") then
		-- sometimes we don't get any item data
		-- this happens for example when changing to the unlearned tab
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
	for i=2, JuweTooltip:NumLines() do
		local lineFrame = _G["JuweGemStatsTooltipTextLeft"..i];
		local lineText = lineFrame:GetText() or "";
		local lineMatch = string.match(lineText, "%+[0-9]+.*");
		if (lineMatch) then
			-- stats found => cache and return
			cache[id] = lineMatch;
			return cache[id];
		end
	end
end

local function SetUpRecipe(self, textWidth, tradeSkillInfo)
	if (isDisabled or not isJewelcrafting or not tradeSkillInfo or not tradeSkillInfo.recipeID) then
		return;
	end

	local cachedStats = cache[tradeSkillInfo.recipeID];
	if (cachedStats == false) then
		-- not a gem => skip
		return;
	end

	local stats = cachedStats or GetGemStats(tradeSkillInfo.recipeID);
	if (not stats) then
		-- no stats => skip
		return;
	end

	-- replace name with gem stats
	tradeSkillInfo.name = stats;

	-- call original function to correctly set new name
	TradeSkillRecipeButtonMixin.SetUpRecipe(self, textWidth, tradeSkillInfo);
end

JuweFrame:SetScript("OnEvent", function(self, event, name)
	if (event == "ADDON_LOADED" and name == "Blizzard_TradeSkillUI") then
		self:Initialize();
	end

	if (event == "TRADE_SKILL_DATA_SOURCE_CHANGED") then
		self:OnDataSourceChanged();
	end
end);

function JuweFrame:Initialize()
	JuweToggleButton = CreateFrame("Button", "JuweToggleButton", TradeSkillFrame, "UIPanelButtonTemplate");
	JuweToggleButton:SetPoint("TOPRIGHT", TradeSkillFrameCloseButton, "TOPLEFT", 0, -8);
	JuweToggleButton:SetSize(15, 15);
	JuweToggleButton:SetText("J");
	JuweToggleButton:SetScript("OnClick", function()
		isDisabled = not isDisabled;
		TradeSkillFrame.RecipeList:Refresh();
	end);

	-- buttons are being reused, so we only need to hook them once
	for i, btn in ipairs(TradeSkillFrame.RecipeList.buttons) do
		hooksecurefunc(btn, "SetUpRecipe", SetUpRecipe);
	end
end

-- used to update state when switching professions
function JuweFrame:OnDataSourceChanged()
	local tradeSkillID = C_TradeSkillUI.GetTradeSkillLine();
	isJewelcrafting = tContains(JEWELCRAFTING_SKILL_IDS, tradeSkillID);

	if (not JuweToggleButton) then
		return;
	end

	JuweToggleButton:SetShown(isJewelcrafting);
end
