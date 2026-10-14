local _, ns = ...

-- Alertas JcJ (opcion A: iconos grandes en el centro con el nombre del jugador).
-- Aliados: datos reales (control, perjuicios importantes, vida baja) de grupo/banda/campo de batalla.
-- Enemigos: de momento solo en la demostracion (/pvpkit demo).
-- Cada alerta: nombre (color de clase) arriba; cara del jugador + icono del efecto;
-- texto y barra de duracion debajo. Sin cara disponible se usa el emblema de la clase.

local SCAN_INTERVAL = 0.1  -- segundos entre lecturas (aliados, enemigos y lanzamientos)
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
    dr      = { 0.40, 0.50, 0.70 },  -- rendimiento decreciente pendiente: gris azulado
    kick    = { 1.00, 0.50, 0.00 },  -- ¡cortalo!: naranja
}
-- orden dentro de cada fila
local KIND_ORDER = { kick = 0, cast = 0.5, cc = 1, health = 2, debuff = 3, immune = 4, dr = 5, trinket = 6 }

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

-- Inmunidades y defensivos del enemigo: [id] = texto
local IMMUNE_SPELLS = {
    [642] = "INMUNE",              -- Divine Shield
    [45438] = "INMUNE",            -- Ice Block
    [1022] = "Inmune a físico",    -- Hand of Protection
    [19263] = "Desvía ataques",    -- Deterrence
    [31224] = "Inmune a hechizos", -- Cloak of Shadows
    [48707] = "Absorbe magia",     -- Anti-Magic Shell
    [23920] = "Refleja hechizos",  -- Spell Reflection
    [46924] = "Inmune a control",  -- Bladestorm
    [34471] = "Inmune a control",  -- The Beast Within
    [47585] = "-90% daño",         -- Dispersion
}

-- Abalorio JcJ y "Cada hombre por si mismo" (humano): mismo efecto, 2 min
local TRINKETS = { [42292] = true, [59752] = true }
local TRINKET_CD = 120

-- Rendimientos decrecientes (aproximado): se reinicia 18 s despues de acabar el ultimo control
-- de ese tipo. Texto = como durara el siguiente tras N controles seguidos.
local DR_RESET = 18
local DR_NEXT = { "½", "¼", "inmune" }

local AURAS    -- [nombre localizado] = { kind, label, cat }; se construye al primer uso
local IMMUNES  -- [nombre localizado] = texto
local function BuildAuraTable()
    AURAS, IMMUNES = {}, {}
    for id, cat in pairs(CC_SPELLS) do
        local name = GetSpellInfo(id)
        if name then AURAS[name] = { kind = "cc", label = CC_LABELS[cat], cat = cat } end
    end
    for id, text in pairs(DEBUFF_SPELLS) do
        local name = GetSpellInfo(id)
        if name and not AURAS[name] then AURAS[name] = { kind = "debuff", label = name .. " (" .. text .. ")" } end
    end
    for id, text in pairs(IMMUNE_SPELLS) do
        local name = GetSpellInfo(id)
        if name then IMMUNES[name] = text end
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
    local coords = class and CLASS_ICON_TCOORDS[class]
    if coords then
        tex:SetTexture(CLASS_EMBLEMS)
        tex:SetTexCoord(unpack(coords))
    else  -- clase desconocida
        tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
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
    container:SetWidth(700); container:SetHeight(300)
    container:SetPoint("CENTER", 0, 170)

    -- Se arrastra con "Mover barras", igual que las barras
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", container.StartMoving)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local pos = ns.GetDB().alertPos
        pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
    end)
    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints()
    container.bg:SetTexture(0.78, 0.61, 0.43, 0.25)
    container.label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    container.label:SetPoint("BOTTOM", container, "TOP", 0, 2)
    container.label:SetText("PvP Kit - Alertas (arrastra para mover)")

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
        -- la vida baja y ¡cortalo! laten para llamar la atencion
        if a.kind == "health" or a.kind == "kick" then
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
-- Enemigos reales (registro de combate)
-- Controles y DR: solo los que pone tu grupo (para encadenar con el equipo).
-- Inmunidades y abalorio: solo de enemigos identificables (objetivo, foco, arena1-5).
---------------------------------------------------------------------------

local band = bit.band
local HOSTILE_PLAYER = COMBATLOG_OBJECT_REACTION_HOSTILE + COMBATLOG_OBJECT_TYPE_PLAYER
local FROM_GROUP = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY
    + COMBATLOG_OBJECT_AFFILIATION_RAID
local CC_FALLBACK = 12      -- si no llega el fin del control (fuera de rango), se borra a los N s
local IMMUNE_FALLBACK = 15

local enemies = {}  -- [guid] = { name, class, cc = {}, immune = {}, dr = {}, trinketAt }

local function IsHostilePlayer(flags) return band(flags, HOSTILE_PLAYER) == HOSTILE_PLAYER end

local function Enemy(guid, name)
    local e = enemies[guid]
    if not e then
        local class = GetPlayerInfoByGUID and select(2, GetPlayerInfoByGUID(guid))
        e = { name = name, class = class, cc = {}, immune = {}, dr = {} }
        enemies[guid] = e
    end
    return e
end

local ENEMY_UNITS = { "target", "focus", "arena1", "arena2", "arena3", "arena4", "arena5" }
local function UnitForGUID(guid)
    for _, unit in ipairs(ENEMY_UNITS) do
        if UnitGUID(unit) == guid then return unit end
    end
end

local function OnCombatLog(...)
    local _, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName = ...
    if not AURAS then BuildAuraTable() end
    local now = GetTime()

    if event == "SPELL_CAST_SUCCESS" then
        if TRINKETS[spellId] and IsHostilePlayer(srcFlags) then
            Enemy(srcGUID, srcName).trinketAt = now
            ns.Log("enemigo " .. tostring(srcName) .. ": abalorio usado")
        end
        return
    end
    if not dstFlags or not IsHostilePlayer(dstFlags) then return end

    if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
        local info = AURAS[spellName]
        if info and info.kind == "cc" and band(srcFlags, FROM_GROUP) > 0 then
            local e = Enemy(dstGUID, dstName)
            local dr = e.dr[info.cat]
            if not dr or (dr.resetAt and now > dr.resetAt) then dr = { count = 0 } end
            dr.count = dr.count + 1
            dr.resetAt = nil  -- el reinicio cuenta desde que acaba el control
            dr.icon = select(3, GetSpellInfo(spellId))
            e.dr[info.cat] = dr
            e.cc[spellName] = { cat = info.cat, label = info.label, icon = dr.icon, applied = now, caster = srcName }
            ns.Log("enemigo " .. tostring(dstName) .. ": " .. info.label .. " (" .. tostring(srcName) .. "), DR " .. dr.count)
        elseif IMMUNES[spellName] then
            Enemy(dstGUID, dstName).immune[spellName] =
                { label = IMMUNES[spellName], icon = select(3, GetSpellInfo(spellId)), applied = now }
            ns.Log("enemigo " .. tostring(dstName) .. ": " .. spellName)
        end
    elseif event == "SPELL_AURA_REMOVED" then
        local e = enemies[dstGUID]
        if not e then return end
        local c = e.cc[spellName]
        if c then
            e.cc[spellName] = nil
            if e.dr[c.cat] then e.dr[c.cat].resetAt = now + DR_RESET end
        end
        e.immune[spellName] = nil
    end
end

-- Primer corte del jugador que este listo y a rango de esa unidad (las habilidades
-- de la clase con cond = "interrupt": Golpe con escudo, Zurrar, Corte de viento...)
local function ReadyInterrupt(unit, now)
    for _, s in ipairs(ns.GetKnown()) do
        if s.cond == "interrupt" then
            local usable = IsUsableSpell(s.name)
            local start, duration = GetSpellCooldown(s.name)
            local offCooldown = start and (duration <= 1.5 or start + duration <= now)
            if usable and offCooldown and IsSpellInRange(s.name, unit) == 1 then return s end
        end
    end
end

local kicksSeen = {}  -- para anotar en el registro solo los nuevos

-- Lanzamientos de objetivo, foco y arena (tambien PNJ, util para probar en el mundo)
local function ScanCasts(list, cfg, now)
    if not (cfg.casts or cfg.kick) then return end
    local done, current = {}, {}
    for _, unit in ipairs(ENEMY_UNITS) do
        local guid = UnitGUID(unit)
        if guid and not done[guid] and UnitCanAttack("player", unit) then
            done[guid] = true
            local spell, _, _, icon, startMs, endMs, _, _, notInterruptible = UnitCastingInfo(unit)
            if not spell then
                spell, _, _, icon, startMs, endMs, _, notInterruptible = UnitChannelInfo(unit)
            end
            if spell then
                local total = (endMs - startMs) / 1000
                local value = total > 0 and (endMs / 1000 - now) / total or nil
                local _, class = UnitClass(unit)
                local base = { name = UnitName(unit), class = class, unit = unit, icon = icon, value = value }
                local kick = not notInterruptible and cfg.kick and ReadyInterrupt(unit, now)
                if kick then
                    base.kind = "kick"
                    base.label = "¡CÓRTALO! " .. spell .. " (" .. kick.name .. ")"
                    local key = guid .. spell
                    current[key] = true
                    if not kicksSeen[key] then ns.Log("córtalo: " .. tostring(base.name) .. " - " .. spell) end
                    list[#list + 1] = base
                elseif cfg.casts then
                    base.kind = "cast"
                    base.label = notInterruptible and (spell .. " (no se puede cortar)") or ("Lanzando " .. spell)
                    list[#list + 1] = base
                end
            end
        end
    end
    kicksSeen = current
end

local function ScanEnemies()
    local cfg = ns.GetDB().alerts.enemy
    local now = GetTime()
    local list = {}

    for guid, e in pairs(enemies) do
        local unit = UnitForGUID(guid)
        local base = { name = e.name, class = e.class, unit = unit }
        local function Add(fields)
            for k, v in pairs(base) do fields[k] = v end
            list[#list + 1] = fields
        end
        local activeCats = {}

        -- Controles activos (con su DR: como durara el siguiente)
        for spell, c in pairs(e.cc) do
            if now - c.applied > CC_FALLBACK then
                e.cc[spell] = nil
                if e.dr[c.cat] then e.dr[c.cat].resetAt = now + DR_RESET end
            else
                activeCats[c.cat] = true
                if cfg.cc then
                    local value
                    if unit then
                        local _, _, _, _, _, duration, expires = UnitDebuff(unit, spell)
                        if duration and duration > 0 and expires then value = (expires - now) / duration end
                    end
                    local dr = e.dr[c.cat]
                    Add({ icon = c.icon, kind = "cc", value = value,
                          label = c.label .. " (" .. tostring(c.caster) .. ")",
                          dr = dr and "DR " .. DR_NEXT[math.min(dr.count, 3)] })
                end
            end
        end

        -- DR pendiente tras acabar el control: cuanto falta para que se reinicie
        for cat, dr in pairs(e.dr) do
            if dr.resetAt and now > dr.resetAt then
                e.dr[cat] = nil
            elseif dr.resetAt and cfg.cc and not activeCats[cat] then
                Add({ icon = dr.icon, kind = "dr", value = (dr.resetAt - now) / DR_RESET,
                      label = CC_LABELS[cat] .. ": siguiente " .. DR_NEXT[math.min(dr.count, 3)] })
            end
        end

        -- Inmunidades y abalorio solo si el enemigo es identificable
        for spell, im in pairs(e.immune) do
            if now - im.applied > IMMUNE_FALLBACK then
                e.immune[spell] = nil
            elseif unit and cfg.immune then
                Add({ icon = im.icon, kind = "immune", label = im.label })
            end
        end
        if e.trinketAt then
            local left = TRINKET_CD - (now - e.trinketAt)
            if left <= 0 then
                e.trinketAt = nil
            elseif unit and cfg.trinket then
                Add({ icon = SpellIcon(42292), kind = "trinket", label = "Sin abalorio", value = left / TRINKET_CD })
            end
        end

        if not next(e.cc) and not next(e.dr) and not next(e.immune) and not e.trinketAt then
            enemies[guid] = nil
        end
    end

    ScanCasts(list, cfg, now)

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
    -- mientras se mueven las barras se ve la demostracion, para ver el tamano real
    local showDemo = demoOn or not ns.GetDB().locked
    if elapsedSince < SCAN_INTERVAL and not showDemo then return end
    elapsedSince = 0

    local size = AlertSize()
    PlaceRows(size)

    if demoOn and demoUntil and GetTime() > demoUntil then demoOn, demoUntil = false, nil end
    if showDemo then
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
    local enabled = ns.GetDB().enabled and ns.GetDB().features.alerts
    Render(rows.ally, enabled and ScanAllies() or EMPTY, GetTime(), size)
    Render(rows.enemy, enabled and ScanEnemies() or EMPTY, GetTime(), size)
end

-- Se llama al terminar de cargar (Core.lua)
function ns.InitAlerts()
    Build()
    ns.ApplyAlertsLock()
    local lastErr

    local events = CreateFrame("Frame")
    events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            wipe(enemies)  -- nueva zona / arena: se olvida lo anterior
            return
        end
        local ok, err = pcall(OnCombatLog, ...)
        if not ok and err ~= lastErr then
            lastErr = err
            ns.LogError("registro de combate: " .. tostring(err))
        end
    end)

    container:SetScript("OnUpdate", function(self, elapsed)
        local ok, err = pcall(OnUpdate, self, elapsed)
        if not ok and err ~= lastErr then
            lastErr = err
            ns.LogError("alertas: " .. tostring(err))
        end
    end)
end

-- Posicion guardada y modo mover (llamado desde ApplyLock en Core.lua)
function ns.ApplyAlertsLock()
    if not container then return end
    local db = ns.GetDB()
    local pos = db.alertPos
    container:ClearAllPoints()
    container:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    container:SetHeight(50 + 2 * (CellHeight(AlertSize()) + 12))
    container:EnableMouse(not db.locked)
    if db.locked then
        container.bg:Hide(); container.label:Hide()
    else
        container.bg:Show(); container.label:Show()
    end
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
