local _, Juwe = ...;

local Item = Item;

Juwe.OnAddonLoaded("Blizzard_Professions", function()
	local math = math;
	local Professions = Professions;

	local isJewelcrafting = false;

	local toggleButton = Juwe.CreateToggleButton(ProfessionsFrame, function()
		ProfessionsFrame.CraftingPage:Init(ProfessionsFrame:GetProfessionInfo());
		ProfessionsFrame.OrdersPage:Init(ProfessionsFrame:GetProfessionInfo());
	end);

	local function updateToggleButton()
		local tabID = ProfessionsFrame:GetTab();
		toggleButton:ClearAllPoints();
		toggleButton:SetPoint("TOPRIGHT", tabID == 1 and ProfessionsFrame.MaximizeMinimize or ProfessionsFrame.CloseButton, "TOPLEFT", 0, 1);
		toggleButton:SetShown(isJewelcrafting and tabID ~= 2 and not Professions.IsCraftingMinimized());
	end

	-- executes after ProfessionsRecipeListRecipeMixin:Init
	local function recipeInitHook(self, node, hideCraftableCount)
		local elementData = node:GetData();
		local recipeInfo = Professions.GetHighestLearnedRecipe(elementData.recipeInfo) or elementData.recipeInfo;

		if (not recipeInfo.hyperlink) then
			return;
		end

		Juwe.GetGemStats(Item:CreateFromItemLink(recipeInfo.hyperlink), function(item, stats)
			self.Label:SetText(stats);

			-- see original function
			local padding = 10;
			local rightFramesWidth = self.LockedIcon:IsShown() and self.LockedIcon:GetWidth() or 0; -- there is only one right now
			local countWidth = self.Count:IsShown() and self.Count:GetStringWidth() or 0;
			local width = self:GetWidth() - (rightFramesWidth + countWidth + padding + self.SkillUps:GetWidth());
			self.Label:SetWidth(self:GetWidth());
			self.Label:SetWidth(math.min(width, self.Label:GetStringWidth()));
		end);
	end

	-- executes after ProfessionsCraftingPageMixin:Init or ProfessionsCraftingOrderPageMixin:Init
	local function initHook(self, professionInfo)
		isJewelcrafting = professionInfo.profession == 12;
		updateToggleButton();
	end

	hooksecurefunc(ProfessionsRecipeListRecipeMixin, "Init", recipeInitHook);
	hooksecurefunc(ProfessionsFrame.OrdersPage, "Init", initHook);

	EventRegistry:RegisterCallback("ProfessionsFrame.TabSet", updateToggleButton);
	EventRegistry:RegisterCallback("ProfessionsFrame.Minimized", updateToggleButton);
	EventRegistry:RegisterCallback("ProfessionsFrame.Maximized", updateToggleButton);
end);
