-----------------------------
-- Lanacan XP Top Bar
-- WoW Addon to display a slim experience bar anchored to the top of the screen.
-- Shows level, XP progress, rested bonus.
-- Updated for Midnight – removed kill XP tracking.
-----------------------------

-- === CONFIGURATION OPTIONS ===
local TEXT_CENTERED = false
local TEXT_MOUSEOVER_ONLY = false

-- === Hide Blizzard XP and Reputation Bars ===
local function HideDefaultXPAndRepBars()

    local frames = {
        MainMenuExpBar,
        MainMenuBarMaxLevelBar,
        ReputationWatchBar,
        ReputationWatchStatusBar,
        ReputationWatchBarOverlayFrame,
    }

    for _, frame in ipairs(frames) do
        if frame then
            frame:Hide()

            -- Prevent Blizzard from re-showing it
            frame:HookScript("OnShow", function(self)
                self:Hide()
            end)
        end
    end
end

C_Timer.After(1, HideDefaultXPAndRepBars)

-- === Do not load addon if player is max level ===
local maxLevel = GetMaxPlayerLevel()
local currentLevel = UnitLevel("player")
if currentLevel >= maxLevel then
    return
end

-- === CLASS COLOR ===
local _, playerClass = UnitClass("player")
local classColor = RAID_CLASS_COLORS[playerClass]

-- === CREATE BAR ===
local bar = CreateFrame("StatusBar", "XPTopStatusBar", UIParent)
bar:SetHeight(4)
bar:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
bar:SetPoint("RIGHT", UIParent, "RIGHT", 0, 0)
bar:SetPoint("TOP", UIParent, "TOP", 0, 0)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
bar:SetMinMaxValues(0, UnitXPMax("player"))
bar:SetValue(UnitXP("player"))
bar:Show()

-- === SPARK ===
local spark = bar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetSize(6, 6)
spark:SetBlendMode("ADD")

-- === TEXT FRAME ===
local f = CreateFrame("Frame", "XPTimeTrackerFrame", UIParent)
f:SetHeight(15)
f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -6)

local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetAllPoints(true)
text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

if TEXT_CENTERED then text:SetJustifyH("CENTER") else text:SetJustifyH("LEFT") end
text:SetWordWrap(false)

if TEXT_MOUSEOVER_ONLY then
    text:SetAlpha(0)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function()
        UIFrameFadeIn(text, 0.2, text:GetAlpha(), 1)
    end)
    bar:SetScript("OnLeave", function()
        UIFrameFadeOut(text, 0.2, text:GetAlpha(), 0)
    end)
end

-- === COLOR PIPE ===
local coloredPipe = string.format("|cff%02x%02x%02x | |r",
    classColor.r * 255, classColor.g * 255, classColor.b * 255)

-- === FORMAT XP TEXT ===
local function FormatXP()
    local maxLevel = GetMaxPlayerLevel()
    local currentLevel = UnitLevel("player")

    if currentLevel == maxLevel then
        return string.format("Level %d (Max)", currentLevel)
    end

    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local percent = (maxXP > 0) and (currentXP / maxXP * 100) or 0

    local restedXP = GetXPExhaustion()
    local restedPercent = restedXP and (maxXP > 0 and restedXP / maxXP * 100 or 0) or 0

    local baseText = string.format(
        "Level %d%s%s/%s (%.1f%%)",
        currentLevel,
        coloredPipe,
        BreakUpLargeNumbers(currentXP),
        BreakUpLargeNumbers(maxXP),
        percent
    )

    if restedXP and restedPercent > 1 then
        return string.format("%s%sRested %.1f%%", baseText, coloredPipe, restedPercent)
    end

    return baseText
end

-- === UPDATE FUNCTION ===
local function UpdateDisplay()
    local currentXP = UnitXP("player")
    local maxXP = UnitXPMax("player")
    local restedXP = GetXPExhaustion()

    if restedXP and restedXP > 0 then
        bar:SetStatusBarColor(0.6, 0.4, 0.8)
    else
        bar:SetStatusBarColor(classColor.r, classColor.g, classColor.b)
    end

    bar:SetMinMaxValues(0, maxXP)
    bar:SetValue(currentXP)

    -- Fix division-by-zero
    local barWidth = bar:GetRight() - bar:GetLeft()
    local percent = (maxXP > 0) and (currentXP / maxXP) or 0

    spark:ClearAllPoints()
    spark:SetPoint("CENTER", bar, "LEFT", barWidth * percent, 0)

    local xpText = FormatXP()
    text:SetText("|cFFFFFFFF" .. xpText .. "|r")

    local textWidth = text:GetStringWidth()
    local finalWidth = math.min(math.max(textWidth, 200), 600)
    f:SetWidth(finalWidth)

    if TEXT_CENTERED then
        f:ClearAllPoints()
        f:SetPoint("TOP", UIParent, "TOP", 0, -6)
    else
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, -6)
    end
end

-- === UPDATE LOOP ===
f:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer >= 0.2 then
        UpdateDisplay()
        self.timer = 0
    end
end)
