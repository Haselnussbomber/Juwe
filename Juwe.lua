--[[ * Juwe * ]]--
local _, Juwe = ...;

local C_TooltipInfo = C_TooltipInfo;
local RETRIEVING_ITEM_INFO = RETRIEVING_ITEM_INFO;

local cache = {};

Juwe.isDisabled = false;

function Juwe.GetGemStats(item, callback)
	if (Juwe.isDisabled or not item) then
		return;
	end

	local classID = select(6, GetItemInfoInstant(item:GetStaticBackingItem()));
	if (classID ~= Enum.ItemClass.Gem) then
		return;
	end

	local itemID = item:GetItemID();
	if (cache[itemID] ~= nil and cache[itemID] == false) then
		return;
	end

	item:ContinueOnItemLoad(function()
		local itemData = C_TooltipInfo.GetItemByID(itemID);
		if (not itemData) then
			return;
		end

		-- scan tooltip lines
		for i, lineData in ipairs(itemData.lines) do
			if (lineData.leftText) then
				if (lineData.leftText == RETRIEVING_ITEM_INFO) then
					return;
				end

				local lineMatch = lineData.leftText:match("^(%+?[0-9]+.*) |A") or lineData.leftText:match("^%+?[0-9]+.*");
				if (lineMatch) then
					cache[itemID] = lineMatch;
					return callback(item, lineMatch);
				end
			end
		end

		-- no stats were found
		cache[itemID] = false;
	end);
end

function Juwe.CreateToggleButton(parent, onClickCallback)
	local button = CreateFrame("Button", "JuweToggleButton" .. parent:GetName(), parent, "UIPanelButtonTemplate");
	button:SetPoint("TOPRIGHT", parent.MaximizeMinimize or parent.CloseButton, "TOPLEFT", 0, 1);
	button:SetFrameLevel(parent.TitleContainer:GetFrameLevel() + 10);
	button:SetSize(24, 24);
	button:SetText("J");
	local function buttonOnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip_SetTitle(GameTooltip, Juwe.isDisabled and "Juwe disabled" or "Juwe enabled");
		GameTooltip:Show();
	end
	button:SetScript("OnClick", function(self)
		Juwe.isDisabled = not Juwe.isDisabled;
		button.Left:SetDesaturated(Juwe.isDisabled);
		button.Right:SetDesaturated(Juwe.isDisabled);
		button.Middle:SetDesaturated(Juwe.isDisabled);
		buttonOnEnter(self);
		onClickCallback();
	end);
	button:SetScript("OnEnter", buttonOnEnter);
	button:SetScript("OnLeave", function()
		GameTooltip:Hide();
	end);
	return button;
end
