local _, ns = ...

local ICON = "Interface\\Icons\\Ability_Warrior_DefensiveStance"
local MINIMAP_RADIUS = 80

local ICON_SIZE, ICON_GAP, COLS = 32, 4, 10
local PAD = 24
local LIST_TOP = -92  -- debajo de las pestanas y el texto de ayuda
local CONTENT_TOP = -72  -- inicio del contenido de cada pestana

local window, enableCheck, minimapButton
local pages, tabs = {}, {}

local TAB_DEFS = {
    { key = "general", label = "General" },
    { key = "spells",  label = "Habilidades" },
}
local iconPool, headers = {}, {}

---------------------------------------------------------------------------
-- Lista de habilidades con iconos
---------------------------------------------------------------------------

local function UpdateIcon(b)
    local off = ns.GetDB().disabled[b.id]
    b.icon:SetDesaturated(off and true or false)
    b.icon:SetAlpha(off and 0.35 or 1)
end

local function ShowSpellTooltip(b)
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("spell:" .. b.id)
    GameTooltip:AddLine(" ")
    if ns.GetDB().disabled[b.id] then
        GameTooltip:AddLine("Desactivada - clic para activar", 1, 0.3, 0.3)
    else
        GameTooltip:AddLine("Activada - clic para desactivar", 0.3, 1, 0.3)
    end
    GameTooltip:Show()
end

local function GetIconButton(i)
    if iconPool[i] then return iconPool[i] end
    local b = CreateFrame("Button", nil, pages.spells)
    b:SetWidth(ICON_SIZE); b:SetHeight(ICON_SIZE)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints()

    b:SetScript("OnClick", function(self)
        local db = ns.GetDB()
        db.disabled[self.id] = not db.disabled[self.id] or nil
        UpdateIcon(self)
        ShowSpellTooltip(self)
    end)
    b:SetScript("OnEnter", ShowSpellTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    iconPool[i] = b
    return b
end

local function GetHeader(i)
    if not headers[i] then
        headers[i] = pages.spells:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    end
    return headers[i]
end

-- Se reconstruye cada vez que se abre la ventana (cambian talentos / hechizos aprendidos)
local function BuildSpellList()
    local sections = {
        { title = "Ofensivas", list = {} },
        { title = "Defensivas", list = {} },
        { title = "Procs (en el aviso grande mientras duran)", list = {} },
    }
    for _, s in ipairs(ns.GetKnown()) do
        table.insert(s.def and sections[2].list or sections[1].list, s)
    end
    for _, p in ipairs(ns.procs) do
        if p.name then table.insert(sections[3].list, p) end
    end

    local y, n = LIST_TOP, 0
    for si, sec in ipairs(sections) do
        local h = GetHeader(si)
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", PAD, y)
        h:SetText(sec.title)
        y = y - 18

        for i, s in ipairs(sec.list) do
            n = n + 1
            local b = GetIconButton(n)
            b.id = s.id
            b.icon:SetTexture(s.icon)
            local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", PAD + col * (ICON_SIZE + ICON_GAP), y - row * (ICON_SIZE + ICON_GAP))
            UpdateIcon(b)
            b:Show()
        end
        y = y - math.ceil(#sec.list / COLS) * (ICON_SIZE + ICON_GAP) - 10
    end
    for i = n + 1, #iconPool do iconPool[i]:Hide() end

    pages.spells.height = -y + 40
end

---------------------------------------------------------------------------
-- Ventana de opciones
---------------------------------------------------------------------------

local function CreateWindow()
    local f = CreateFrame("Frame", "WarriorReadyOptions", UIParent)
    f:SetWidth(PAD * 2 + COLS * (ICON_SIZE + ICON_GAP) - ICON_GAP); f:SetHeight(130)
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

    window = f

    -- Pestanas
    for i, def in ipairs(TAB_DEFS) do
        local page = CreateFrame("Frame", nil, f)
        page:SetAllPoints()
        page:Hide()
        pages[def.key] = page

        local t = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        t:SetWidth(110); t:SetHeight(22)
        t:SetPoint("TOPLEFT", PAD + (i - 1) * 114, -32)
        t:SetText(def.label)
        t:SetScript("OnClick", function() ns.SelectTab(def.key) end)
        t.key = def.key
        tabs[i] = t
    end

    -- Pestana General
    local general = pages.general
    general.height = 150
    enableCheck = CreateFrame("CheckButton", "WarriorReadyOptionsEnable", general, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    _G[enableCheck:GetName() .. "Text"]:SetText("Activar WarriorReady")
    enableCheck:SetScript("OnClick", function(self)
        ns.SetEnabled(self:GetChecked() and true or false)
    end)

    local hint = general:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 22)
    hint:SetText("Arrastra el boton del minimapa para moverlo")

    -- Pestana Habilidades
    local help = pages.spells:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Clic en un icono para activarlo o desactivarlo.")

    f:SetScript("OnShow", function()
        enableCheck:SetChecked(ns.GetDB().enabled)
        BuildSpellList()
        ns.SelectTab(ns.GetDB().optionsTab or "general")
    end)
end

function ns.SelectTab(key)
    if not pages[key] then key = "general" end
    ns.GetDB().optionsTab = key
    for _, t in ipairs(tabs) do
        if t.key == key then t:LockHighlight() else t:UnlockHighlight() end
    end
    for k, page in pairs(pages) do
        if k == key then page:Show() else page:Hide() end
    end
    window:SetHeight(pages[key].height)
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
