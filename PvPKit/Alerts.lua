local _, ns = ...

-- Alertas JcJ (opcion A: iconos grandes en el centro con el nombre del jugador).
-- Aliados: datos reales (control, perjuicios importantes, vida baja) de grupo/banda/campo de batalla.
-- Enemigos: de momento solo en la demostracion (/pvpkit demo).
-- Cada alerta: nombre (color de clase) arriba; cara del jugador + icono del efecto;
-- texto y barra de duracion debajo. Sin cara disponible se usa el emblema de la clase.

local SCAN_INTERVAL = 0.2  -- segundos entre lecturas de los aliados
local MAX_ALERTS = 6       -- alertas como maximo por fila
local DEMO_CYCLE = 12      -- la demo se repite cada N segundos
local HEALTH_ICON = "Interface\\Icons\\Spell_Holy_AshesToAshes"
local CLASS_EMBLEMS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local BORDER_COLORS = {
    cc      = { 0.70, 0.30, 1.00 },  -- control: morado
    debuff  = { 1.00, 0.20, 0.20 },  -- perjuicio: rojo
    health  = { 1.00, 0.10, 0.10 },  -- vida baja: rojo intenso
    immune  = { 1.00, 0.82, 0.00 },  -- inmune: dorado
    trinket = { 0.60, 0.60, 0.60 },  -- abalorio usado: gris
    cast    = { 0.30, 0.60, 1.00 },  -- lanzando: azul
}
local KIND_ORDER = { cc = 1, health = 2, debuff = 3 }  -- orden dentro de la fila de aliados

---------------------------------------------------------------------------
-- Controles y perjuicios de JcJ (todas las clases). Se comparan por nombre
-- localizado, asi sirve cualquier rango del hechizo. Clave = spell ID de rango 1.
-- cat: tipo de control (servira para los rendimientos decrecientes)
---------------------------------------------------------------------------

local CC_LABELS = {
    stun = "Aturdido", fear = "Miedo", incap = "Incapacitado", silence = "Silenciado",
    root = "Enraizado", disarm = "Desarmado", horror = "Horror", cyclone = "Ciclón",
    charm = "Controlado", banish = "Desterrado",
}

local CC_SPELLS = {
    -- Aturdimientos
    [853] = "stun",    -- Hammer of Justice
    [1833] = "stun",   -- Cheap Shot
    [408] = "stun",    -- Kidney Shot
    [5211] = "stun",   -- Bash
    [22570] = "stun",  -- Maim
    [9005] = "stun",   -- Pounce
    [7922] = "stun",   -- Charge Stun
    [20253] = "stun",  -- Intercept
    [12809] = "stun",  -- Concussion Blow
    [46968] = "stun",  -- Shockwave
    [20549] = "stun",  -- War Stomp
    [24394] = "stun",  -- Intimidation
    [44572] = "stun",  -- Deep Freeze
    [47481] = "stun",  -- Gnaw (necrofago)
    [30283] = "stun",  -- Shadowfury
    [12355] = "stun",  -- Impact
    [20170] = "stun",  -- Seal of Justice
    [39796] = "stun",  -- Stoneclaw Stun
    [50518] = "stun",  -- Ravage (mascota)
    -- Miedos
    [5782] = "fear",   -- Fear
    [5484] = "fear",   -- Howl of Terror
    [8122] = "fear",   -- Psychic Scream
    [5246] = "fear",   -- Intimidating Shout
    [2094] = "fear",   -- Blind
    [1513] = "fear",   -- Scare Beast
    [10326] = "fear",  -- Turn Evil
    -- Horror
    [6789] = "horror", -- Death Coil
    [64044] = "horror", -- Psychic Horror
    -- Incapacitar / desorientar
    [118] = "incap",   -- Polymorph
    [6770] = "incap",  -- Sap
    [1776] = "incap",  -- Gouge
    [51514] = "incap", -- Hex
    [20066] = "incap", -- Repentance
    [3355] = "incap",  -- Freezing Trap
    [19386] = "incap", -- Wyvern Sting
    [19503] = "incap", -- Scatter Shot
    [2637] = "incap",  -- Hibernate
    [31661] = "incap", -- Dragon's Breath
    [33786] = "cyclone", -- Cyclone
    [605] = "charm",   -- Mind Control
    [6358] = "charm",  -- Seduction
    [710] = "banish",  -- Banish
    -- Silencios
    [15487] = "silence", -- Silence
    [18469] = "silence", -- Counterspell - Silenced
    [1330] = "silence",  -- Garrote - Silence
    [47476] = "silence", -- Strangulate
    [34490] = "silence", -- Silencing Shot
    [24259] = "silence", -- Spell Lock
    [28730] = "silence", -- Arcane Torrent
    [18425] = "silence", -- Kick - Silenced
    [18498] = "silence", -- Gag Order
    -- Raices
    [339] = "root",    -- Entangling Roots
    [122] = "root",    -- Frost Nova
    [33395] = "root",  -- Freeze (elemental de agua)
    [55080] = "root",  -- Shattered Barrier
    [23694] = "root",  -- Improved Hamstring
    [12494] = "root",  -- Frostbite
    [19185] = "root",  -- Entrapment
    [64695] = "root",  -- Earthgrab
    -- Desarmes
    [676] = "disarm",   -- Disarm
    [51722] = "disarm", -- Dismantle
    [64058] = "disarm", -- Psychic Horror (desarme)
    [53359] = "disarm", -- Chimera Shot - Scorpid
}

-- Perjuicios importantes: [id] = texto
local DEBUFF_SPELLS = {
    [12294] = "-50% curación",  -- Mortal Strike
    [13218] = "-50% curación",  -- Wound Poison
    [19434] = "-50% curación",  -- Aimed Shot
    [46910] = "-50% curación",  -- Furious Attacks
    [48301] = "-50% curación",  -- Mind Trauma
    [30108] = "no disipar",     -- Unstable Affliction
}

local AURAS  -- [nombre localizado] = { kind, label }; se construye al primer uso
local function BuildAuraTable()
    AURAS = {}
    for id, cat in pairs(CC_SPELLS) do
        local name = GetSpellInfo(id)
        if name then AURAS[name] = { kind = "cc", label = CC_LABELS[cat], cat = cat } end
    end
    for id, text in pairs(DEBUFF_SPELLS) do
        local name = GetSpellInfo(id)
        if name and not AURAS[name] then AURAS[name] = { kind = "debuff", label = name .. " (" .. text .. ")" } end
    end
end

local function SpellIcon(id) return select(3, GetSpellInfo(id)) end

---------------------------------------------------------------------------
-- Demostracion: datos inventados
---------------------------------------------------------------------------

local DEMO = {
    ally = {
        { name = "Thrall", class = "SHAMAN", spell = 118,   label = "Polimorfia",  kind = "cc",     dur = 8 },
        { name = "Jaina",  class = "MAGE",   icon = HEALTH_ICON, label = "Vida 22%", kind = "health" },
        { name = "Thrall", class = "SHAMAN", spell = 12294, label = "Golpe mortal (-50% curación)", kind = "debuff", dur = 10 },
    },
    enemy = {
        { name = "Uther",  class = "PALADIN", spell = 46968, label = "Aturdido (Thrall)", kind = "cc", dur = 4, dr = "DR ½" },
        { name = "Uther",  class = "PALADIN", spell = 642,   label = "INMUNE",            kind = "immune", dur = 12 },
        { name = "Medivh", class = "MAGE",    spell = 42292, label = "Sin abalorio",      kind = "trinket", dur = 120 },
        { name = "Medivh", class = "MAGE",    spell = 118,   label = "Lanzando Polimorfia", kind = "cast", dur = 1.5 },
        { name = "Medivh", class = "MAGE",    icon = HEALTH_ICON, label = "Vida 18%", kind = "health" },
    },
}

---------------------------------------------------------------------------
-- Dibujo
---------------------------------------------------------------------------

local container, banner
local rows = {}
local demoOn, demoStart, demoUntil = false, 0, nil

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

    banner = container:CreateFontString(nil, "OVERLAY")
    banner:SetFont(STANDARD_TEXT_FONT, 40, "THICKOUTLINE")
    banner:SetTextColor(1, 0.35, 0)
    banner:SetPoint("TOP", 0, 0)
    banner:SetText("¡AHORA!")
    banner:Hide()

    CreateRow("ally", "Aliados", 0.3, 1, 0.3)
    CreateRow("enemy", "Enemigos", 1, 0.3, 0.3)
end

-- a.value = parte que queda de la duracion (0..1) o nil si no tiene duracion
local function Render(row, list, t, size)
    local n = #list
    local w = CellWidth(size)
    local total = n * w
    row.title:ClearAllPoints()
    row.title:SetPoint("RIGHT", row, "LEFT", -total / 2 - 10, -size / 2 - 14)
    if n > 0 then row.title:Show() else row.title:Hide() end

    for i, a in ipairs(list) do
        local c = row.cells[i] or CreateCell(row)
        row.cells[i] = c
        SizeCell(c, size)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", row, "TOPLEFT", -total / 2 + (i - 1) * w, 0)

        local color = RAID_CLASS_COLORS[a.class] or NORMAL_FONT_COLOR
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

        if a.value then
            c.bar:SetValue(a.value)
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

local function PlaceRows(size)
    rows.ally:ClearAllPoints()
    rows.ally:SetPoint("TOP", container, "TOP", 0, -50)
    rows.enemy:ClearAllPoints()
    rows.enemy:SetPoint("TOP", container, "TOP", 0, -50 - CellHeight(size) - 12)
end

---------------------------------------------------------------------------
-- Aliados reales
---------------------------------------------------------------------------

local function GroupUnits()
    local units = {}
    local raid = GetNumRaidMembers()
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    else
        for i = 1, GetNumPartyMembers() do units[#units + 1] = "party" .. i end
    end
    return units
end

local seen = {}  -- alertas ya registradas en el log, para anotar solo las nuevas

local function ScanAllies()
    if not AURAS then BuildAuraTable() end
    local cfg = ns.GetDB().alerts.ally
    local now = GetTime()
    local list, current = {}, {}

    for _, unit in ipairs(GroupUnits()) do
        if UnitExists(unit) and not UnitIsUnit(unit, "player") and not UnitIsDeadOrGhost(unit) then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)

            if cfg.cc or cfg.debuff then
                for i = 1, 40 do
                    local aura, _, icon, _, _, duration, expires, caster = UnitDebuff(unit, i)
                    if not aura then break end
                    local info = AURAS[aura]
                    if info and cfg[info.kind] then
                        local label = info.label
                        local casterName = caster and UnitName(caster)
                        if info.kind == "cc" and casterName then label = label .. " (" .. casterName .. ")" end
                        local value
                        if duration and duration > 0 and expires then value = (expires - now) / duration end
                        list[#list + 1] = { name = name, class = class, unit = unit, icon = icon,
                                            label = label, kind = info.kind, value = value }
                        current[unit .. aura] = name .. ": " .. aura
                    end
                end
            end

            if cfg.health then
                local pct = math.floor(UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100)
                if pct <= cfg.healthPct then
                    list[#list + 1] = { name = name, class = class, unit = unit, icon = HEALTH_ICON,
                                        label = "Vida " .. pct .. "%", kind = "health" }
                    current[unit .. "health"] = name .. ": vida baja"
                end
            end
        end
    end

    for key, text in pairs(current) do
        if not seen[key] then ns.Log("alerta aliado: " .. text) end
    end
    seen = current

    table.sort(list, function(a, b) return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end)
    for i = #list, MAX_ALERTS + 1, -1 do list[i] = nil end
    return list
end

---------------------------------------------------------------------------
-- Bucle
---------------------------------------------------------------------------

local EMPTY = {}
local elapsedSince = 0

local function OnUpdate(_, elapsed)
    elapsedSince = elapsedSince + elapsed
    if elapsedSince < SCAN_INTERVAL and not demoOn then return end
    elapsedSince = 0

    local size = AlertSize()
    PlaceRows(size)

    if demoOn and demoUntil and GetTime() > demoUntil then demoOn, demoUntil = false, nil end
    if demoOn then
        local t = GetTime() - demoStart
        for _, list in pairs(DEMO) do
            for _, a in ipairs(list) do
                if a.dur then a.value = 1 - (t % a.dur) / a.dur end
            end
        end
        Render(rows.ally, DEMO.ally, t, size)
        Render(rows.enemy, DEMO.enemy, t, size)
        -- "¡AHORA!" los primeros 4 s de cada ciclo, latiendo
        if t % DEMO_CYCLE < 4 then
            banner:SetAlpha(0.5 + 0.5 * math.abs(math.sin(t * 5)))
            banner:Show()
        else
            banner:Hide()
        end
        return
    end

    banner:Hide()
    local allies = ns.GetDB().enabled and ScanAllies() or EMPTY
    Render(rows.ally, allies, GetTime(), size)
    Render(rows.enemy, EMPTY, 0, size)
end

-- Se llama al terminar de cargar (Core.lua)
function ns.InitAlerts()
    Build()
    local lastErr
    container:SetScript("OnUpdate", function(self, elapsed)
        local ok, err = pcall(OnUpdate, self, elapsed)
        if not ok and err ~= lastErr then
            lastErr = err
            ns.LogError("alertas: " .. tostring(err))
        end
    end)
end

-- /pvpkit demo: demostracion fija hasta volver a escribirlo
function ns.ToggleDemo()
    demoOn = not demoOn
    demoStart, demoUntil = GetTime(), nil
    return demoOn
end

-- Vista previa al cambiar el tamano: demostracion durante 5 segundos
function ns.ShowDemo()
    if demoOn and not demoUntil then return end  -- ya esta fija
    demoOn = true
    demoStart = demoStart > 0 and demoStart or GetTime()
    demoUntil = GetTime() + 5
end
