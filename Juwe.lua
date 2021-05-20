--[[ * Juwe (Burning Crusade Classic) * ]]--

local _G = _G;
local select = select;
local string_match = string.match;
local GetItemInfoInstant = GetItemInfoInstant;
local GetTradeSkillLine = GetTradeSkillLine;
local LE_ITEM_CLASS_GEM = LE_ITEM_CLASS_GEM;
local JEWELCRAFTING = GetSpellInfo(25229);

local Juwe = CreateFrame("Frame", "Juwe");
Juwe:RegisterEvent("ADDON_LOADED");
Juwe:RegisterEvent("GET_ITEM_INFO_RECEIVED");
Juwe:SetScript("OnEvent", function(self, event, ...)
	if (self[event]) then
		self[event](self, ...);
	end
end);

Juwe.isDisabled = false;

local cache = {};
Juwe.cache = cache;

local tooltip = CreateFrame("GameTooltip", "JuweTooltip", nil, "GameTooltipTemplate");
tooltip:SetOwner(UIParent, "ANCHOR_NONE");
Juwe.tooltip = tooltip;

--[[ Hooks ]]--

-- executes after TradeSkillFrame_Update
local function UpdateHook()
	local isJewelcrafting = GetTradeSkillLine() == JEWELCRAFTING;

	if (self.toggleButton) then
		self.toggleButton:SetShown(isJewelcrafting);
	end

	if (self.isDisabled or not isJewelcrafting or not TradeSkillFrame:IsShown()) then
		return;
	end

	local numTradeSkills = GetNumTradeSkills();
	local skillOffset = FauxScrollFrame_GetOffset(TradeSkillListScrollFrame);

	for i = 1, TRADE_SKILLS_DISPLAYED, 1 do
		local skillIndex = i + skillOffset;
		local skillName, skillType = GetTradeSkillInfo(skillIndex);
		if (skillType ~= "header" and skillIndex <= numTradeSkills) then
			local button = _G["TradeSkillSkill" .. i];
			local id = button:GetID();
			if (button and id ~= 0) then
				local stats = self:GetGemStats(id);
				if (stats and stats.valid) then
					button:SetText(stats.text);
				end
			end
		end
	end
end

--[[ Event Handler ]]--

function Juwe:ADDON_LOADED(name)
	if (name ~= "Blizzard_TradeSkillUI") then
		return;
	end

	self:UnregisterEvent("ADDON_LOADED");

	local toggleButton = CreateFrame("Button", "JuweToggleButton", TradeSkillFrame, "UIPanelButtonTemplate");
	self.toggleButton = toggleButton;
	toggleButton:SetPoint("TOPRIGHT", TradeSkillFrameCloseButton, "TOPLEFT", 0, -8);
	toggleButton:SetSize(15, 15);
	toggleButton:SetText("J");
	toggleButton:SetScript("OnClick", function()
		self.isDisabled = not self.isDisabled;
		TradeSkillFrame_Update();
	end);

	hooksecurefunc("TradeSkillFrame_Update", UpdateHook);
end

function Juwe:GET_ITEM_INFO_RECEIVED(itemID, success)
	if (success and cache[itemID] and not cache[itemID].valid) then
		cache[itemID].retries = 0;
	end
end

--[[ Juwe Functions ]]--

function Juwe:GetGemStats(index)
	if (not index) then
		return;
	end

	local link = GetTradeSkillItemLink(index);
	if (not link) then
		return;
	end

	local id, _, _, _, _, itemClassId = GetItemInfoInstant(link);
	if (not id or itemClassId ~= LE_ITEM_CLASS_GEM) then
		return;
	end

	-- return valid cached info
	if (cache[id] and cache[id].valid) then
		return cache[id];
	end

	-- get or create cached recipe
	cache[id] = cache[id] or {
		retries = 0,
		valid = nil,
		text = nil
	};

	-- return if gem has no stats or tried multiple times to get info
	if (cache[id].valid == false or cache[id].retries > 3) then
		return cache[id];
	end

	cache[id].retries = cache[id].retries + 1;

	-- request recipe result item
	tooltip:SetTradeSkillItem(index);
	if (not tooltip:IsShown()) then
		return cache[id];
	end

	-- scan tooltip lines for stats
	for i=2, tooltip:NumLines() do
		local lineFrame = _G[tooltip:GetName().."TextLeft"..i];
		local lineText = lineFrame:GetText() or "";
		local lineMatch = string_match(lineText, "^%+?[0-9]+.*");
		if (lineMatch) then
			cache[id].text = lineMatch; -- stats found
			cache[id].valid = true;
			return cache[id];
		end
	end

	-- invalidate if no stats found (example: Brilliant Scarlet Ruby)
	cache[id].valid = false;
	return cache[id];
end
