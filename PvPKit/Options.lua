local _, ns = ...

local MINIMAP_RADIUS = 80

local ICON_SIZE, ICON_GAP, COLS = 32, 4, 10
local PAD = 24
local SIDEBAR_W = 130    -- ancho de la columna de pestanas verticales
local CONTENT_TOP = -40  -- inicio del contenido de cada pestana
local LIST_TOP = -60     -- debajo del texto de ayuda de Habilidades

local window, enableCheck, minimapButton
local pages, tabs = {}, {}

local TAB_DEFS = {
    { key = "general", label = "General" },
    { key = "spells",  label = "Habilidades" },
    { key = "sizes",   label = "Tamaños" },
    { key = "position", label = "Posición" },
    { key = "alerts",   label = "Alertas" },
}

local ALERT_SECTIONS = {
    { key = "ally", title = "Aliados", color = { 0.3, 1, 0.3 }, options = {
        { key = "cc",     label = "Control (CC)" },
        { key = "debuff", label = "Perjuicios importantes" },
        { key = "health", label = "Vida baja" },
        { key = "focus",  label = "Lo están enfocando" },
    } },
    { key = "enemy", title = "Enemigos", color = { 1, 0.3, 0.3 }, options = {
        { key = "cc",         label = "Control (CC) y DR" },
        { key = "debuff",     label = "Perjuicios" },
        { key = "health",     label = "Vida baja" },
        { key = "casts",      label = "Hechizo que lanza" },
        { key = "trinket",    label = "Abalorio JcJ" },
        { key = "immune",     label = "Inmunidades" },
        { key = "killWindow", label = "¡AHORA! (ventana)" },
    } },
}
local alertControls = {}  -- { check o slider, seccion, opcion }

local profileTabs, createProfileButtons = {}, {}  -- pestanas de perfil y botones Nuevo/Copiar
local currentProfileLabel, deleteProfileButton, countLabel
-- Modo perfiles: las pestanas se ocultan y la barra lateral muestra "Volver"
local changeProfileButton, sidebarProfileLabel, backButton
local lastTab = "general"

local positionControls = {}  -- [grupo] = casilla Vertical
local moveButton
local RefreshWindow, UpdateMinimapPosition  -- definidas mas abajo

local SIZE_PRESETS = {
    { label = "XS", name = "Extra pequeño", size = 32 },
    { label = "S",  name = "Pequeño",       size = 44 },
    { label = "M",  name = "Mediano",       size = 60 },
    { label = "L",  name = "Grande",        size = 80 },
}

local SIZE_GROUPS = {
    { key = "main", label = "Aviso grande" },
    { key = "cd",   label = "Barra ofensiva" },
    { key = "def",  label = "Barra defensiva" },
    { key = "fav",  label = "Barra favoritas" },
}
local sizeButtons = {}  -- [grupo] = slider
local iconPool, headers, sectionButtons = {}, {}, {}
local UpdateSectionButton

---------------------------------------------------------------------------
-- Lista de habilidades con iconos
---------------------------------------------------------------------------

local function UpdateIcon(b)
    local db = ns.GetDB()
    local off = db.disabled[b.id]
    b.icon:SetDesaturated(off and true or false)
    b.icon:SetAlpha(off and 0.35 or 1)
    if b.canFav and db.favorites[b.id] then
        b.star:Show(); b.favBorder:Show()
    else
        b.star:Hide(); b.favBorder:Hide()
    end
end

local function ShowSpellTooltip(b)
    GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("spell:" .. b.id)
    GameTooltip:AddLine(" ")
    local db = ns.GetDB()
    if db.disabled[b.id] then
        GameTooltip:AddLine("Desactivada - clic para activar", 1, 0.3, 0.3)
    else
        GameTooltip:AddLine("Activada - clic para desactivar", 0.3, 1, 0.3)
    end
    if b.canFav then
        if db.favorites[b.id] then
            GameTooltip:AddLine("Favorita - clic derecho para quitarla", 1, 0.82, 0)
        else
            GameTooltip:AddLine("Clic derecho: marcar como favorita", 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:Show()
end

local function AnyEnabled(list)
    local disabled = ns.GetDB().disabled
    for _, s in ipairs(list) do
        if not disabled[s.id] then return true end
    end
    return false
end

-- "Deseleccionar todos" si hay al menos una activa, "Seleccionar todos" si no hay ninguna
function UpdateSectionButton(btn)
    btn:SetText(AnyEnabled(btn.list) and "Deseleccionar todos" or "Seleccionar todos")
end

local function GetSectionButton(i)
    if sectionButtons[i] then return sectionButtons[i] end
    local btn = CreateFrame("Button", nil, pages.spells, "UIPanelButtonTemplate")
    btn:SetWidth(140); btn:SetHeight(20)
    btn:SetScript("OnClick", function(self)
        local disabled = ns.GetDB().disabled
        local turnOff = AnyEnabled(self.list)
        for _, s in ipairs(self.list) do
            disabled[s.id] = turnOff or nil
        end
        for _, b in ipairs(iconPool) do
            if b.sectionButton == self then UpdateIcon(b) end
        end
        UpdateSectionButton(self)
    end)
    sectionButtons[i] = btn
    return btn
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

    -- Favorita: marco dorado alrededor + estrella (icono de banda) en la esquina
    b.favBorder = b:CreateTexture(nil, "BACKGROUND")
    b.favBorder:SetTexture(1, 0.82, 0, 1)
    b.favBorder:SetPoint("TOPLEFT", -3, 3)
    b.favBorder:SetPoint("BOTTOMRIGHT", 3, -3)
    b.favBorder:Hide()

    b.star = b:CreateTexture(nil, "OVERLAY")
    b.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    b.star:SetWidth(16); b.star:SetHeight(16)
    b.star:SetPoint("TOPRIGHT", 5, 5)
    b.star:Hide()

    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(self, button)
        local db = ns.GetDB()
        if button == "RightButton" then
            if not self.canFav then return end
            db.favorites[self.id] = not db.favorites[self.id] or nil
        else
            db.disabled[self.id] = not db.disabled[self.id] or nil
            UpdateSectionButton(self.sectionButton)
        end
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
        { title = "Procs (aviso grande)", list = {} },
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

        local sb = GetSectionButton(si)
        sb.list = sec.list
        sb:ClearAllPoints()
        sb:SetPoint("TOPRIGHT", -PAD, y + 3)
        UpdateSectionButton(sb)
        if #sec.list > 0 then sb:Show() else sb:Hide() end
        y = y - 24

        for i, s in ipairs(sec.list) do
            n = n + 1
            local b = GetIconButton(n)
            b.id = s.id
            b.sectionButton = sb
            b.canFav = si < 3  -- los procs van siempre al aviso grande
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
-- Pestana Tamanos
---------------------------------------------------------------------------

local function PresetIndex(size)
    local best, bestDiff = 1, math.huge
    for i, p in ipairs(SIZE_PRESETS) do
        local diff = math.abs(p.size - size)
        if diff < bestDiff then best, bestDiff = i, diff end
    end
    return best
end

local function SetSliderText(slider, i)
    local p = SIZE_PRESETS[i]
    _G[slider:GetName() .. "Text"]:SetText(p.label .. " - " .. p.name .. " (" .. p.size .. " px)")
end

-- Filas de la pestana Tamanos: las barras y ademas las alertas JcJ
local SIZE_ROWS = {}
for _, grp in ipairs(SIZE_GROUPS) do SIZE_ROWS[#SIZE_ROWS + 1] = grp end
SIZE_ROWS[#SIZE_ROWS + 1] = { key = "alerts", label = "Alertas JcJ" }

local function GetSize(key)
    local db = ns.GetDB()
    if key == "alerts" then return db.alertSize end
    return db.groups[key].size
end

local function SetSize(key, size)
    local db = ns.GetDB()
    if key == "alerts" then
        db.alertSize = size
        ns.ApplyAlertsLock()
        ns.ShowDemo()  -- vista previa con la demostracion
    else
        db.groups[key].size = size
        ns.ApplyGroup()
        ns.StartTest()
    end
end

local function UpdateSizeButtons()
    for key, slider in pairs(sizeButtons) do
        local i = PresetIndex(GetSize(key))
        slider.updating = true
        slider:SetValue(i)
        slider.updating = false
        SetSliderText(slider, i)
    end
end

local function BuildSizesPage(page)
    local help = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Al elegir un tamaño se muestra una vista previa durante 5 segundos.")

    local y = CONTENT_TOP - 40
    for _, grp in ipairs(SIZE_ROWS) do
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", PAD, y - 2)
        label:SetText(grp.label)

        local s = CreateFrame("Slider", "PvPKitSizeSlider_" .. grp.key, page, "OptionsSliderTemplate")
        s:SetWidth(200)
        s:SetPoint("TOPLEFT", PAD + 140, y)
        s:SetMinMaxValues(1, #SIZE_PRESETS)
        s:SetValueStep(1)
        _G[s:GetName() .. "Low"]:SetText(SIZE_PRESETS[1].label)
        _G[s:GetName() .. "High"]:SetText(SIZE_PRESETS[#SIZE_PRESETS].label)
        s:SetScript("OnValueChanged", function(self, value)
            local i = math.floor(value + 0.5)
            SetSliderText(self, i)
            if self.updating then return end
            if GetSize(grp.key) ~= SIZE_PRESETS[i].size then
                SetSize(grp.key, SIZE_PRESETS[i].size)
            end
        end)
        sizeButtons[grp.key] = s
        y = y - 54
    end
    page.height = -y + 20
end

---------------------------------------------------------------------------
-- Pestana Posicion
---------------------------------------------------------------------------

local function UpdatePositionControls()
    local db = ns.GetDB()
    for g, check in pairs(positionControls) do
        check:SetChecked(db.groups[g].dir == "V")
    end
    moveButton:SetText(db.locked and "Mover barras" or "Fijar barras")
end

local function BuildPositionPage(page)
    local help = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Pulsa Mover barras, arrástralas con el ratón y pulsa Fijar barras.")

    moveButton = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    moveButton:SetWidth(140); moveButton:SetHeight(22)
    moveButton:SetPoint("TOPLEFT", PAD, CONTENT_TOP - 20)
    moveButton:SetScript("OnClick", function()
        ns.SetLocked(not ns.GetDB().locked)
        UpdatePositionControls()
    end)

    local y = CONTENT_TOP - 60
    for _, grp in ipairs(SIZE_GROUPS) do
        local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", PAD, y - 6)
        label:SetText(grp.label)

        local check = CreateFrame("CheckButton", "PvPKitVertical_" .. grp.key, page, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", PAD + 140, y)
        _G[check:GetName() .. "Text"]:SetText("Vertical")
        check:SetScript("OnClick", function(self)
            ns.GetDB().groups[grp.key].dir = self:GetChecked() and "V" or "H"
            ns.ApplyGroup()
            ns.StartTest()
        end)

        positionControls[grp.key] = check
        y = y - 32
    end
    page.height = -y + 20
end

---------------------------------------------------------------------------
-- Pestana Alertas (de momento solo afecta a la demostracion)
---------------------------------------------------------------------------

local function UpdateAlertControls()
    local alerts = ns.GetDB().alerts
    for _, c in ipairs(alertControls) do
        local value = alerts[c.section][c.option]
        if c.isSlider then
            c.widget.updating = true
            c.widget:SetValue(value)
            c.widget.updating = false
            _G[c.widget:GetName() .. "Text"]:SetText("Vida baja: " .. value .. "%")
        else
            c.widget:SetChecked(value)
        end
    end
end

local function BuildAlertsPage(page)
    local help = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Aliados: grupo, banda y campo de batalla. Enemigos: controles de tu\ngrupo con DR, abalorio e inmunidades (objetivo, foco o arena).")

    local lowest = 0
    for col, sec in ipairs(ALERT_SECTIONS) do
        local x = PAD + (col - 1) * 190
        local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", x, CONTENT_TOP - 56)
        title:SetText(sec.title)
        title:SetTextColor(unpack(sec.color))

        local y = CONTENT_TOP - 74
        for _, opt in ipairs(sec.options) do
            local check = CreateFrame("CheckButton", "PvPKitAlert_" .. sec.key .. "_" .. opt.key, page, "UICheckButtonTemplate")
            check:SetWidth(24); check:SetHeight(24)
            check:SetPoint("TOPLEFT", x - 4, y)
            _G[check:GetName() .. "Text"]:SetText(opt.label)
            check:SetScript("OnClick", function(self)
                ns.GetDB().alerts[sec.key][opt.key] = self:GetChecked() and true or false
            end)
            alertControls[#alertControls + 1] = { widget = check, section = sec.key, option = opt.key }
            y = y - 24
        end

        -- Umbral de vida baja
        local s = CreateFrame("Slider", "PvPKitAlertHealth_" .. sec.key, page, "OptionsSliderTemplate")
        s:SetWidth(150)
        s:SetPoint("TOPLEFT", x, y - 22)
        s:SetMinMaxValues(10, 50)
        s:SetValueStep(5)
        _G[s:GetName() .. "Low"]:SetText("10%")
        _G[s:GetName() .. "High"]:SetText("50%")
        s:SetScript("OnValueChanged", function(self, value)
            value = math.floor(value / 5 + 0.5) * 5
            _G[self:GetName() .. "Text"]:SetText("Vida baja: " .. value .. "%")
            if not self.updating then ns.GetDB().alerts[sec.key].healthPct = value end
        end)
        alertControls[#alertControls + 1] = { widget = s, section = sec.key, option = "healthPct", isSlider = true }
        lowest = math.min(lowest, y - 60)
    end
    page.height = -lowest + 20
end

---------------------------------------------------------------------------
-- Pestana Perfiles
---------------------------------------------------------------------------

local function AfterProfileChange()
    UpdateMinimapPosition()
    RefreshWindow("profiles")
end

-- Los perfiles se muestran como pestanas en la barra lateral, debajo de Volver
local function BuildProfileList()
    local current = ns.GetCurrentProfile()
    local names = ns.GetProfiles()
    currentProfileLabel:SetText("Perfil activo: |cffffffff" .. current .. "|r")

    for i, t in ipairs(profileTabs) do
        local name = names[i]
        t.profileName = name
        if name then
            t.text:SetText(name)
            local selected = name == current
            if selected then t.sel:Show() else t.sel:Hide() end
            t.text:SetFontObject(selected and GameFontHighlight or GameFontNormal)
        end
    end

    local full = #names >= ns.MAX_PROFILES
    for _, b in ipairs(createProfileButtons) do
        if full then b:Disable() else b:Enable() end
    end
    if #names > 1 then deleteProfileButton:Enable() else deleteProfileButton:Disable() end
    countLabel:SetText(#names .. " de " .. ns.MAX_PROFILES .. " perfiles")
end

local function BuildProfilesPage(page)
    local help = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Elige un perfil a la izquierda. Cada personaje recuerda qué perfil usa.")

    currentProfileLabel = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currentProfileLabel:SetPoint("TOPLEFT", PAD, CONTENT_TOP - 22)

    local actions = {
        { label = "Nuevo",  popup = "PVPKIT_NEW_PROFILE" },
        { label = "Copiar", popup = "PVPKIT_COPY_PROFILE" },
        { label = "Borrar", popup = "PVPKIT_DELETE_PROFILE" },
    }
    for i, act in ipairs(actions) do
        local b = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
        b:SetWidth(100); b:SetHeight(22)
        b:SetPoint("TOPLEFT", PAD + (i - 1) * 106, CONTENT_TOP - 48)
        b:SetText(act.label)
        b:SetScript("OnClick", function()
            StaticPopup_Show(act.popup, ns.GetCurrentProfile())
        end)
        if act.label == "Borrar" then
            deleteProfileButton = b
        else
            createProfileButtons[#createProfileButtons + 1] = b
        end
    end

    countLabel = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    countLabel:SetPoint("TOPLEFT", PAD, CONTENT_TOP - 80)

    page.height = 150
end

-- Ventanas emergentes con caja de texto para el nombre del perfil
local function NameDialog(text, copyCurrent)
    local function accept(popup)
        local name = _G[popup:GetName() .. "EditBox"]:GetText()
        if ns.NewProfile(name, copyCurrent) then
            AfterProfileChange()
        else
            UIErrorsFrame:AddMessage("Nombre vacío, repetido o ya hay 5 perfiles.", 1, 0.2, 0.2)
        end
    end
    return {
        text = text,
        button1 = ACCEPT,
        button2 = CANCEL,
        hasEditBox = 1,
        maxLetters = 32,
        OnShow = function(self)
            local box = _G[self:GetName() .. "EditBox"]
            box:SetText("")
            box:SetFocus()
        end,
        OnAccept = accept,
        EditBoxOnEnterPressed = function(self)
            local popup = self:GetParent()
            accept(popup)
            popup:Hide()
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
end

StaticPopupDialogs["PVPKIT_NEW_PROFILE"] = NameDialog("Nombre del nuevo perfil (empieza con la configuración original):", false)
StaticPopupDialogs["PVPKIT_COPY_PROFILE"] = NameDialog("Copiar el perfil %s con el nombre:", true)
StaticPopupDialogs["PVPKIT_DELETE_PROFILE"] = {
    text = "¿Borrar el perfil %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if ns.DeleteProfile() then AfterProfileChange() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

---------------------------------------------------------------------------
-- Ventana de opciones
---------------------------------------------------------------------------

local function CreateTab(sidebar, i, def)
    local t = CreateFrame("Button", nil, sidebar)
    t:SetWidth(SIDEBAR_W - 22); t:SetHeight(22)
    t:SetPoint("TOPLEFT", 6, -8 - (i - 1) * 24)

    t.sel = t:CreateTexture(nil, "BACKGROUND")
    t.sel:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    t.sel:SetBlendMode("ADD")
    t.sel:SetAllPoints()
    t.sel:Hide()

    local hl = t:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints()

    t.text = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.text:SetPoint("LEFT", 8, 0)
    t.text:SetText(def.label)

    t.key = def.key
    t:SetScript("OnClick", function() ns.SelectTab(def.key) end)
    return t
end

local function CreateWindow()
    local f = CreateFrame("Frame", "PvPKitOptions", UIParent)
    f:SetWidth(SIDEBAR_W + PAD * 2 + COLS * (ICON_SIZE + ICON_GAP) - ICON_GAP); f:SetHeight(130)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")  -- por debajo de las ventanas emergentes (DIALOG)
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
    title:SetText("PvP Kit")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    window = f

    -- Pestanas verticales a la izquierda
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", 16, -32)
    sidebar:SetPoint("BOTTOMLEFT", 16, 16)
    sidebar:SetWidth(SIDEBAR_W - 10)
    sidebar:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    sidebar:SetBackdropColor(0, 0, 0, 0.4)
    sidebar:SetBackdropBorderColor(0.6, 0.6, 0.6)

    for i, def in ipairs(TAB_DEFS) do
        local page = CreateFrame("Frame", nil, f)
        page:SetPoint("TOPLEFT", SIDEBAR_W, 0)
        page:SetPoint("BOTTOMRIGHT")
        page:Hide()
        pages[def.key] = page
        tabs[i] = CreateTab(sidebar, i, def)
    end

    -- Perfiles: pagina aparte, se entra con "Cambiar perfil" y se sale con "Volver"
    pages.profiles = CreateFrame("Frame", nil, f)
    pages.profiles:SetPoint("TOPLEFT", SIDEBAR_W, 0)
    pages.profiles:SetPoint("BOTTOMRIGHT")
    pages.profiles:Hide()

    changeProfileButton = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    changeProfileButton:SetWidth(SIDEBAR_W - 26); changeProfileButton:SetHeight(22)
    changeProfileButton:SetPoint("BOTTOM", 0, 10)
    changeProfileButton:SetText("Cambiar perfil")
    changeProfileButton:SetScript("OnClick", function() ns.SelectTab("profiles") end)

    sidebarProfileLabel = sidebar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sidebarProfileLabel:SetPoint("BOTTOM", changeProfileButton, "TOP", 0, 6)
    sidebarProfileLabel:SetWidth(SIDEBAR_W - 24)

    backButton = CreateFrame("Button", nil, sidebar, "UIPanelButtonTemplate")
    backButton:SetWidth(SIDEBAR_W - 26); backButton:SetHeight(22)
    backButton:SetPoint("TOP", 0, -10)
    backButton:SetText("« Volver")
    backButton:SetScript("OnClick", function() ns.SelectTab(lastTab) end)
    backButton:Hide()

    for i = 1, ns.MAX_PROFILES do
        local t = CreateTab(sidebar, i, { key = "profile" .. i, label = "" })
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", 6, -40 - (i - 1) * 24)
        t:SetScript("OnClick", function(self)
            if self.profileName then
                ns.SetProfile(self.profileName)
                AfterProfileChange()
            end
        end)
        t:Hide()
        profileTabs[i] = t
    end

    -- Pestana General
    local general = pages.general
    general.height = 150
    enableCheck = CreateFrame("CheckButton", "PvPKitOptionsEnable", general, "UICheckButtonTemplate")
    enableCheck:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    _G[enableCheck:GetName() .. "Text"]:SetText("Activar PvP Kit")
    enableCheck:SetScript("OnClick", function(self)
        ns.SetEnabled(self:GetChecked() and true or false)
    end)

    local reset = CreateFrame("Button", nil, general, "UIPanelButtonTemplate")
    reset:SetWidth(200); reset:SetHeight(22)
    reset:SetPoint("TOPLEFT", PAD, CONTENT_TOP - 40)
    reset:SetText("Restaurar configuración")
    reset:SetScript("OnClick", function() StaticPopup_Show("PVPKIT_RESET") end)

    local hint = general:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOM", 0, 22)
    hint:SetText("Arrastra el botón del minimapa para moverlo")

    -- Pestana Habilidades
    local help = pages.spells:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", PAD, CONTENT_TOP)
    help:SetText("Clic: activar o desactivar.  Clic derecho: favorita (va a su propia barra).")

    BuildSizesPage(pages.sizes)
    BuildPositionPage(pages.position)
    BuildProfilesPage(pages.profiles)
    BuildAlertsPage(pages.alerts)

    f:SetScript("OnShow", function()
        local ok, err = pcall(RefreshWindow)
        if not ok then ns.LogError("ventana de opciones: " .. tostring(err)) end
    end)
end

-- Refresca todo con el perfil activo. Al abrir la ventana empieza siempre en General.
function RefreshWindow(tab)
    enableCheck:SetChecked(ns.GetDB().enabled)
    BuildSpellList()
    UpdateSizeButtons()
    UpdatePositionControls()
    BuildProfileList()
    UpdateAlertControls()
    sidebarProfileLabel:SetText("Perfil:\n|cffffd100" .. ns.GetCurrentProfile() .. "|r")
    ns.SelectTab(tab or "general")
end

StaticPopupDialogs["PVPKIT_RESET"] = {
    text = "¿Restaurar la configuración del perfil actual a los valores originales?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns.ResetDefaults()
        UpdateMinimapPosition()
        if window:IsShown() then RefreshWindow() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function ns.SelectTab(key)
    if not pages[key] then key = "general" end
    local profileMode = key == "profiles"
    if not profileMode then lastTab = key end

    for _, t in ipairs(tabs) do
        local selected = t.key == key
        if selected then t.sel:Show() else t.sel:Hide() end
        t.text:SetFontObject(selected and GameFontHighlight or GameFontNormal)
        if profileMode then t:Hide() else t:Show() end
    end
    if profileMode then
        backButton:Show(); changeProfileButton:Hide(); sidebarProfileLabel:Hide()
    else
        backButton:Hide(); changeProfileButton:Show(); sidebarProfileLabel:Show()
    end
    for _, t in ipairs(profileTabs) do
        if profileMode and t.profileName then t:Show() else t:Hide() end
    end

    for k, page in pairs(pages) do
        if k == key then page:Show() else page:Hide() end
    end
    -- alto minimo: lo que ocupa la barra lateral en cada modo
    local sidebarHeight = profileMode and (40 + ns.MAX_PROFILES * 24 + 40) or (#TAB_DEFS * 24 + 110)
    window:SetHeight(math.max(pages[key].height, sidebarHeight))
end

function ns.ToggleOptions()
    if window:IsShown() then window:Hide() else window:Show() end
end

---------------------------------------------------------------------------
-- Boton del minimapa
---------------------------------------------------------------------------

function UpdateMinimapPosition()
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
    GameTooltip:AddLine("PvP Kit")
    local color = RAID_CLASS_COLORS[ns.class]
    GameTooltip:AddLine("Clase: " .. UnitClass("player"), color.r, color.g, color.b)
    GameTooltip:AddLine(ns.GetDB().enabled and "|cff40ff40Activado|r" or "|cffff4040Desactivado|r")
    GameTooltip:AddLine("Clic izquierdo: opciones", 1, 1, 1)
    GameTooltip:AddLine("Clic derecho: activar/desactivar", 1, 1, 1)
    GameTooltip:AddLine("Arrastrar: mover", 1, 1, 1)
    GameTooltip:Show()
end

local function CreateMinimapButton()
    local b = CreateFrame("Button", "PvPKitMinimapButton", Minimap)
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
    -- Emblema de la clase detectada (el mismo de la pantalla de crear personaje)
    local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[ns.class]
    if coords then
        b.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        b.icon:SetTexCoord(unpack(coords))
    else
        b.icon:SetTexture(ns.classIcon)
    end
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
