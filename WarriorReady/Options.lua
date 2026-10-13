local _, ns = ...

local ICON = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
local MINIMAP_RADIUS = 80

local window, enableCheck, minimapButton

---------------------------------------------------------------------------
-- Ventana de opciones
---------------------------------------------------------------------------

local function CreateWindow()
    local f = CreateFrame("Frame", "WarriorReadyOptions", UIParent)
    f:SetWidth(300); f:SetHeight(130)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    tinsert(UISpecialFrames, f:GetName())  -- se cierra con Escape

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetWidth(256); header:SetHeight(64)
    header:SetPoint("TOP", 0, 12)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", header, "TOP", 0, -14)
    title:SetText("WarriorReady")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    enableCheck = CreateFrame("CheckButton", "WarriorReadyOptionsEnable", f, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", 24, -40)
    _G[enableCheck:GetName() .. "Text"]:SetText("Activar WarriorReady")
    enableCheck:SetScript("OnClick", function(self)
        ns.SetEnabled(self:GetChecked() and true or false)
    end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 22)
    hint:SetText("Arrastra el boton del minimapa para moverlo")

    f:SetScript("OnShow", function()
        enableCheck:SetChecked(ns.GetDB().enabled)
    end)

    window = f
end

function ns.ToggleOptions()
    if window:IsShown() then window:Hide() else window:Show() end
end

---------------------------------------------------------------------------
-- Boton del minimapa
---------------------------------------------------------------------------

local function UpdateMinimapPosition()
    local angle = math.rad(ns.GetDB().minimap.angle)
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * MINIMAP_RADIUS, math.sin(angle) * MINIMAP_RADIUS)
end

local function DragUpdate()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    ns.GetDB().minimap.angle = math.deg(math.atan2(py / scale - my, px / scale - mx))
    UpdateMinimapPosition()
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("WarriorReady")
    GameTooltip:AddLine(ns.GetDB().enabled and "|cff40ff40Activado|r" or "|cffff4040Desactivado|r")
    GameTooltip:AddLine("Clic izquierdo: opciones", 1, 1, 1)
    GameTooltip:AddLine("Clic derecho: activar/desactivar", 1, 1, 1)
    GameTooltip:AddLine("Arrastrar: mover", 1, 1, 1)
    GameTooltip:Show()
end

local function CreateMinimapButton()
    local b = CreateFrame("Button", "WarriorReadyMinimapButton", Minimap)
    b:SetWidth(31); b:SetHeight(31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetWidth(20); bg:SetHeight(20)
    bg:SetPoint("TOPLEFT", 7, -5)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(ICON)
    b.icon:SetWidth(17); b.icon:SetHeight(17)
    b.icon:SetPoint("TOPLEFT", 7, -6)

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(53); border:SetHeight(53)
    border:SetPoint("TOPLEFT")

    b:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            ns.SetEnabled(not ns.GetDB().enabled)
            if window:IsShown() then enableCheck:SetChecked(ns.GetDB().enabled) end
            ShowTooltip(self)
        else
            ns.ToggleOptions()
        end
    end)
    b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", DragUpdate) end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    minimapButton = b
    UpdateMinimapPosition()
end

function ns.InitOptions()
    CreateWindow()
    CreateMinimapButton()
end
