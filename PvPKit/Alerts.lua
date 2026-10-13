local _, ns = ...

-- Alertas JcJ (opcion A: iconos grandes en el centro con el nombre del jugador).
-- Por ahora solo existe el modo demostracion con datos inventados (/pvpkit demo).
-- Cada alerta: nombre (color de clase) arriba; cara del jugador + icono del efecto;
-- texto y barra de duracion debajo. Sin cara disponible se usa el emblema de la clase.

local DEMO_CYCLE = 12   -- la demo se repite cada N segundos
local CLASS_EMBLEMS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local BORDER_COLORS = {
    cc      = { 0.70, 0.30, 1.00 },  -- control: morado
    debuff  = { 1.00, 0.20, 0.20 },  -- perjuicio: rojo
    health  = { 1.00, 0.10, 0.10 },  -- vida baja: rojo intenso
    immune  = { 1.00, 0.82, 0.00 },  -- inmune: dorado
    trinket = { 0.60, 0.60, 0.60 },  -- abalorio usado: gris
    cast    = { 0.30, 0.60, 1.00 },  -- lanzando: azul
}

local function SpellIcon(id) return select(3, GetSpellInfo(id)) end

-- Datos inventados para revisar la experiencia de uso.
-- unit = token del juego (party1, arena1...) cuando exista: permite mostrar la cara real.
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

local function AlertSize() return ns.GetDB().alertSize end
local function CellWidth(size) return math.max(size * 2 + 30, 130) end
local function CellHeight(size) return size + 50 end

local function SetClassEmblem(tex, class)
    tex:SetTexture(CLASS_EMBLEMS)
    tex:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
end

local function CreateCell(parent)
    local c = CreateFrame("Frame", nil, parent)

    c.name = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    c.name:SetPoint("TOP", 0, 0)

    c.portrait = c:CreateTexture(nil, "ARTWORK")

    c.border = c:CreateTexture(nil, "BACKGROUND")
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Emblema pequeno de la clase en la esquina del icono (solo si se ve la cara)
    c.badge = c:CreateTexture(nil, "OVERLAY")

    c.dr = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    c.label = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

    -- Barra que se vacia con la duracion (sin numeros)
    c.bar = CreateFrame("StatusBar", nil, c)
    c.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    c.bar:SetHeight(4)
    c.bar:SetMinMaxValues(0, 1)
    return c
end

local function SizeCell(c, size)
    if c.size == size then return end
    c.size = size
    local w = CellWidth(size)
    c:SetWidth(w); c:SetHeight(CellHeight(size))

    -- cara a la izquierda, icono a la derecha, centrados como pareja
    c.portrait:SetWidth(size); c.portrait:SetHeight(size)
    c.portrait:ClearAllPoints()
    c.portrait:SetPoint("TOPRIGHT", c, "TOP", -2, -14)

    c.border:SetWidth(size + 6); c.border:SetHeight(size + 6)
    c.border:ClearAllPoints()
    c.border:SetPoint("TOPLEFT", c, "TOP", 2, -11)
    c.icon:SetWidth(size); c.icon:SetHeight(size)
    c.icon:ClearAllPoints()
    c.icon:SetPoint("CENTER", c.border, "CENTER")

    local badge = math.max(14, size * 0.35)
    c.badge:SetWidth(badge); c.badge:SetHeight(badge)
    c.badge:ClearAllPoints()
    c.badge:SetPoint("BOTTOMLEFT", c.icon, "BOTTOMLEFT", -2, -2)

    c.dr:ClearAllPoints()
    c.dr:SetPoint("TOPRIGHT", c.icon, "TOPRIGHT", 4, 6)

    c.label:SetWidth(w)
    c.label:ClearAllPoints()
    c.label:SetPoint("TOP", c, "TOP", 0, -size - 20)

    c.bar:SetWidth(size * 2)
    c.bar:ClearAllPoints()
    c.bar:SetPoint("TOP", c.label, "BOTTOM", 0, -2)
end

local function CreateRow(key, title, r, g, b)
    local row = CreateFrame("Frame", nil, container)
    row:SetWidth(1); row:SetHeight(1)
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

    CreateRow("ally", "Aliados", 0.3, 1, 0.3)
    CreateRow("enemy", "Enemigos", 1, 0.3, 0.3)
end

local function Render(row, list, t, size)
    local n = #list
    local w = CellWidth(size)
    local total = n * w
    row.title:ClearAllPoints()
    row.title:SetPoint("RIGHT", row, "LEFT", -total / 2 - 10, -size / 2 - 14)
    for i, a in ipairs(list) do
        local c = row.cells[i] or CreateCell(row)
        row.cells[i] = c
        SizeCell(c, size)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", row, "TOPLEFT", -total / 2 + (i - 1) * w, 0)

        local color = RAID_CLASS_COLORS[a.class]
        c.name:SetText(a.name)
        c.name:SetTextColor(color.r, color.g, color.b)

        -- Cara real si el juego conoce al jugador; si no, emblema de la clase
        if a.unit and UnitExists(a.unit) then
            c.portrait:SetTexCoord(0, 1, 0, 1)
            SetPortraitTexture(c.portrait, a.unit)
            SetClassEmblem(c.badge, a.class)
            c.badge:Show()
        else
            SetClassEmblem(c.portrait, a.class)
            c.badge:Hide()
        end

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
    local size = AlertSize()
    rows.ally:ClearAllPoints()
    rows.ally:SetPoint("TOP", container, "TOP", 0, -50)
    rows.enemy:ClearAllPoints()
    rows.enemy:SetPoint("TOP", container, "TOP", 0, -50 - CellHeight(size) - 12)
    Render(rows.ally, DEMO.ally, t, size)
    Render(rows.enemy, DEMO.enemy, t, size)
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

-- Para la vista previa al cambiar el tamano: enciende la demo si estaba apagada
function ns.ShowDemo()
    if not demoOn then ns.ToggleDemo() end
end
