local disabled = false
local button

local tip = CreateFrame('GameTooltip', 'GemStatsTip')
local line1 = tip:CreateFontString()
local line2 = tip:CreateFontString()
local line3 = tip:CreateFontString()

tip:AddFontStrings(tip:CreateFontString(), tip:CreateFontString())
tip:AddFontStrings(line1, tip:CreateFontString())
tip:AddFontStrings(line2, tip:CreateFontString())
tip:AddFontStrings(line3, tip:CreateFontString())

local JEWELCRAFTING_ID = 755
local GEM_S = '%+[0-9]+.*'

local match = string.match
local cache = {}

local function GetGemStats(id)
    if not id then return end
    if cache[id] then return cache[id] end

    tip:SetOwner(WorldFrame, 'ANCHOR_NONE')
    tip:SetRecipeResultItem(id)

    if tip:IsShown() then
        local line = match(line1:GetText() or '', GEM_S) or match(line2:GetText() or '', GEM_S) or match(line3:GetText() or '', GEM_S)
        cache[id] = line
        return line
    end
end

local function Update(self)
    local isJewelcrafting = C_TradeSkillUI.GetTradeSkillLine() == JEWELCRAFTING_ID

    if button then
        if isJewelcrafting then
            button:Show()
        else
            button:Hide()
        end
    end

    if disabled or not isJewelcrafting then
        return
    end

    for i, button in ipairs(self.buttons) do
        if button.tradeSkillInfo and button.tradeSkillInfo.type == 'recipe' then
            local stats = GetGemStats(button.tradeSkillInfo.recipeID)

            if stats then
                button.tradeSkillInfo.name = stats
                button.Text:SetText(stats) -- fix for reactivating Juwe
            end
        end
    end
end

local f = CreateFrame('Frame')
f:RegisterEvent('ADDON_LOADED')
f:SetScript('OnEvent', function(self, event, name)
    if(name == 'Blizzard_TradeSkillUI') then
        button = CreateFrame('Button', 'SomeRandomButton123', TradeSkillFrame, 'UIPanelButtonTemplate')
        button:SetPoint('TOPRIGHT', TradeSkillFrameCloseButton, 'TOPLEFT', 0, -7)
        button:SetSize(15, 15)
        button:SetText('J')
        button:SetScript('OnClick', function()
            disabled = not disabled
            TradeSkillFrame.RecipeList:Refresh()
        end)

        -- update on load via TradeSkillRecipeListMixin
        hooksecurefunc(TradeSkillFrame.RecipeList, 'RefreshDisplay', Update)

        -- update on scroll via HybridScrollFrame
        hooksecurefunc(TradeSkillFrame.RecipeList, 'update', Update)
    end
end)
