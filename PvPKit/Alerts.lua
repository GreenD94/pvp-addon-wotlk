local _, ns = ...

-- Alertas JcJ (opcion A: iconos grandes en el centro con el nombre del jugador).
-- Por ahora solo existe el modo demostracion con datos inventados (/pvpkit demo).

local ICON = 52
local CELL_W = 110      -- ancho de cada alerta (icono + textos)
local DEMO_CYCLE = 12   -- la demo se repite cada N segundos
local BORDER_COLORS = {
    cc      = { 0.70, 0.30, 1.00 },  -- control: morado
    debuff  = { 1.00, 0.20, 0.20 },  -- perjuicio: rojo
    health  = { 1.00, 0.10, 0.10 },  -- vida baja: rojo intenso
    immune  = { 1.00, 0.82, 0.00 },  -- inmune: dorado
    trinket = { 0.60, 0.60, 0.60 },  -- abalorio usado: gris
    cast    = { 0.30, 0.60, 1.00 },  -- lanzando: azul
}

local function SpellIcon(id) return select(3, GetSpellInfo(id)) end

-- Datos inventados para revisar la experiencia de uso
local DEMO = {
    ally = {
        { name = "Thrall", class = "SHAMAN", spell = 118,   label = "Polimorfia",  kind = "cc",     dur = 8 },
        { name = "Jaina",  class = "MAGE",   icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", label = "Vida 22%", kind = "health" },
        { name = "Thrall", class = "SHAMAN", spell = 12294, label = "Golpe mortal (-50% curación)", kind = "debuff", dur = 10 },
    },
    enemy = {
        { name = "Uther",  class = "PALADIN", spell = 46968, label = "Aturdido (Thrall)", kind = "cc", dur = 4, dr = "DR ½" },
        { name = "Uther",  class = "PALADIN", spell = 642,   label = "INMUNE",            kind = "immune", dur = 12 },
        { name = "Medivh", class = "MAGE",    spell = 42292, label = "Sin abalorio",      kind = "trinket", dur = 120 },
        { name = "Medivh", class = "MAGE",    spell = 118,   label = "Lanzando Polimorfia", kind = "cast", dur = 1.5 },
        { name = "Medivh", class = "MAGE",    icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", label = "Vida 18%", kind = "health" },
    },
}

local container, banner
local rows = {}
local demoOn, demoStart = false, 0

local function CreateCell(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(CELL_W); c:SetHeight(ICON + 44)

    c.name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.name:SetPoint("TOP", 0, 0)

    c.border = c:CreateTexture(nil, "BACKGROUND")
    c.border:SetWidth(ICON + 6); c.border:SetHeight(ICON + 6)
    c.border:SetPoint("TOP", 0, -12)

    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetWidth(ICON); c.icon:SetHeight(ICON)
    c.icon:SetPoint("CENTER", c.border, "CENTER")
    c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    c.dr = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.dr:SetPoint("TOPRIGHT", c.icon, "TOPRIGHT", 4, 6)

    c.label = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    c.label:SetPoint("TOP", c.border, "BOTTOM", 0, -2)
    c.label:SetWidth(CELL_W)

    -- Barra que se vacia con la duracion (sin numeros)
    c.bar = CreateFrame("StatusBar", nil, c)
    c.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    c.bar:SetWidth(ICON); c.bar:SetHeight(4)
    c.bar:SetPoint("TOP", c.label, "BOTTOM", 0, -2)
    c.bar:SetMinMaxValues(0, 1)
    return c
end

local function CreateRow(key, title, r, g, b, y)
    local row = CreateFrame("Frame", nil, container)
    row:SetWidth(1); row:SetHeight(ICON + 44)
    row:SetPoint("TOP", container, "TOP", 0, y)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetTextColor(r, g, b)
    row.title:SetText(title)
    row.cells = {}
    rows[key] = row
end

local function Build()
    container = CreateFrame("Frame", "PvPKitAlerts", UIParent)
    container:SetWidth(600); container:SetHeight(300)
    container:SetPoint("CENTER", 0, 170)
    container:Hide()

    banner = container:CreateFontString(nil, "OVERLAY")
    banner:SetFont(STANDARD_TEXT_FONT, 40, "THICKOUTLINE")
    banner:SetTextColor(1, 0.35, 0)
    banner:SetPoint("TOP", 0, 0)
    banner:SetText("¡AHORA!")

    CreateRow("ally", "Aliados", 0.3, 1, 0.3, -50)
    CreateRow("enemy", "Enemigos", 1, 0.3, 0.3, -50 - (ICON + 56))
end

local function Render(row, list, t)
    local n = #list
    local total = n * CELL_W
    row.title:ClearAllPoints()
    row.title:SetPoint("RIGHT", row, "LEFT", -total / 2 - 10, 0)
    for i, a in ipairs(list) do
        local c = row.cells[i] or CreateCell(row)
        row.cells[i] = c
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", row, "TOPLEFT", -total / 2 + (i - 1) * CELL_W, 0)

        local color = RAID_CLASS_COLORS[a.class]
        c.name:SetText(a.name)
        c.name:SetTextColor(color.r, color.g, color.b)
        c.icon:SetTexture(a.icon or SpellIcon(a.spell))
        local bc = BORDER_COLORS[a.kind]
        c.border:SetTexture(bc[1], bc[2], bc[3], 1)
        c.label:SetText(a.label)
        c.dr:SetText(a.dr or "")

        if a.dur then
            c.bar:SetValue(1 - (t % a.dur) / a.dur)
            c.bar:SetStatusBarColor(bc[1], bc[2], bc[3])
            c.bar:Show()
        else
            c.bar:Hide()
        end
        -- la vida baja late para llamar la atencion
        if a.kind == "health" then
            c:SetAlpha(0.6 + 0.4 * math.abs(math.sin(t * 4)))
        else
            c:SetAlpha(1)
        end
        c:Show()
    end
    for i = n + 1, #row.cells do row.cells[i]:Hide() end
end

local function OnUpdate()
    local t = GetTime() - demoStart
    Render(rows.ally, DEMO.ally, t)
    Render(rows.enemy, DEMO.enemy, t)
    -- "¡AHORA!" los primeros 4 s de cada ciclo, latiendo
    if t % DEMO_CYCLE < 4 then
        banner:SetAlpha(0.5 + 0.5 * math.abs(math.sin(t * 5)))
        banner:Show()
    else
        banner:Hide()
    end
end

function ns.ToggleDemo()
    if not container then Build() end
    demoOn = not demoOn
    if demoOn then
        demoStart = GetTime()
        container:SetScript("OnUpdate", OnUpdate)
        container:Show()
    else
        container:SetScript("OnUpdate", nil)
        container:Hide()
    end
    return demoOn
end
