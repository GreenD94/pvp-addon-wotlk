local ADDON, ns = ...

local GCD = 1.5            -- cooldowns <= a esto se consideran el GCD y se ignoran
local THROTTLE = 0.05      -- segundos entre actualizaciones
local FLASH_TIME = 0.45    -- duracion del destello al aparecer el aviso grande
local FADE_TIME = 0.25     -- el aviso grande se desvanece en este tiempo final
local STANCE_QUIET = 0.5   -- tras cambiar de postura no se lanzan avisos grandes

-- "main" = aviso grande en el centro, "cd" = barra ofensiva, "def" = barra defensiva
local defaults = {
    locked = true,
    enabled = true,
    onlyCombat = true,
    minimap = { angle = 200 },
    popTime = 2,
    spacing = 6,
    groups = {
        main = { size = 80, max = 8,  point = "CENTER", relPoint = "CENTER", x = 0, y = -120, dir = "H", align = "center" },
        cd   = { size = 44, max = 12, point = "CENTER", relPoint = "CENTER", x = 0, y = -200, dir = "H", align = "center" },
        def  = { size = 44, max = 12, point = "CENTER", relPoint = "CENTER", x = 0, y = -252, dir = "H", align = "center" },
        fav  = { size = 44, max = 12, point = "CENTER", relPoint = "CENTER", x = 0, y = -304, dir = "H", align = "center" },
    },
    disabled = {},  -- [spellID] = true
    -- Alertas JcJ (de momento solo se usan en la demostracion)
    -- Funciones que se pueden apagar por completo (pestana General)
    features = { pop = true, procs = true, bar_cd = true, bar_def = true, bar_fav = true, alerts = true },
    alertSize = 60,
    alertPos = { point = "CENTER", relPoint = "CENTER", x = 0, y = 170 },
    alerts = {
        ally  = { cc = true, debuff = true, health = true, healthPct = 30, focus = true, selfDR = true },
        enemy = { cc = true, debuff = true, health = true, healthPct = 30, casts = true,
                  trinket = true, immune = true, killWindow = true, kick = true,
                  cooldowns = true, totems = true, purge = true, drink = true },
    },
    favorites = {}, -- [spellID] = true: va a la barra de favoritas en vez de la suya
}

local DEFAULT_PROFILE = "Default"

local GROUP_LABEL = { main = "Aviso", cd = "Ofensivas", def = "Defensivas", fav = "Favoritas" }

local root  -- PvPKitDB: perfiles, perfil de cada personaje y registro de diagnostico
local db    -- perfil activo
local known = {}
local anchors = {}
local buttons = { main = {}, cd = {}, def = {}, fav = {} }
local testMode = false
local quietUntil = 0

local TEST_TIME = 5        -- el modo prueba se apaga solo tras estos segundos
local LOG_MAX = 500        -- lineas guardadas en PvPKitDB.log

local testUntil = 0

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc79c6ePvP Kit|r: " .. msg)
end

-- Registro siempre activo (ultimas LOG_MAX lineas); se guarda en SavedVariables al hacer /reload o salir
local function Log(msg)
    if not root then return end
    local log = root.log
    log[#log + 1] = string.format("%.2f %s", GetTime(), msg)
    if #log > LOG_MAX then table.remove(log, 1) end
end
ns.Log = Log

local function LogError(msg)
    Log("ERROR " .. tostring(msg))
    Print("|cffff4040error:|r " .. tostring(msg))
end
ns.LogError = LogError

local function CopyDefaults(src, dst)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

---------------------------------------------------------------------------
-- Condiciones
---------------------------------------------------------------------------

-- Devuelve: casteando, interrumpible
local function TargetCast()
    if not UnitExists("target") or not UnitCanAttack("player", "target") then return end
    local name, _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    if name then return true, not notInterruptible end
    local cname, _, _, _, _, _, _, cNotInterruptible = UnitChannelInfo("target")
    if cname then return true, not cNotInterruptible end
end

ns.conditions = {
    interrupt = function()
        local casting, interruptible = TargetCast()
        return casting and interruptible
    end,
    castingOnMe = function()
        return TargetCast() and UnitIsUnit("targettarget", "player")
    end,
    notTanking = function()
        return UnitExists("target") and UnitCanAttack("player", "target")
            and UnitExists("targettarget") and not UnitIsUnit("targettarget", "player")
    end,
    -- Objetivo dentro del rango minimo y maximo (Cargar/Interceptar fallan si esta demasiado cerca)
    inRange = function(s)
        return IsSpellInRange(s.name, "target") == 1
    end,
}

---------------------------------------------------------------------------
-- Libro de hechizos
---------------------------------------------------------------------------

local function ScanSpellbook()
    local book = {}
    local i = 1
    while true do
        local name = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        book[name] = true
        i = i + 1
    end
    wipe(known)
    for _, s in ipairs(ns.spells) do
        local name, _, icon = GetSpellInfo(s.id)
        s.name, s.icon = name, icon
        if s.aura then s.auraName = GetSpellInfo(s.aura) end
        if name and book[name] then known[#known + 1] = s end
    end
    for _, p in ipairs(ns.procs) do
        local pname, _, picon = GetSpellInfo(p.id)
        p.name, p.icon = pname, picon
    end
    local names = {}
    for _, s in ipairs(known) do names[#names + 1] = s.name end
    Log("conocidas: " .. table.concat(names, ", "))
end

---------------------------------------------------------------------------
-- Estado de cada habilidad
---------------------------------------------------------------------------

-- Devuelve "ready" (disponible), "norage" (disponible pero falta ira) o nil (no disponible)
local function GetState(s, now)
    if db.disabled[s.id] then return end
    local usable, noRage = IsUsableSpell(s.name)
    if not usable and not noRage then return end  -- postura incorrecta o condicion reactiva no cumplida
    if s.aura and not UnitBuff("player", s.auraName) then return end
    if s.cond and not ns.conditions[s.cond](s) then return end

    local start, duration, enabled = GetSpellCooldown(s.name)
    if not start or enabled == 0 then return end
    if duration > GCD and start + duration > now then return end
    return usable and "ready" or "norage"
end

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------

local function SaveAnchor(g)
    local f = anchors[g]
    local point, _, relPoint, x, y = f:GetPoint()
    local cfg = db.groups[g]
    cfg.point, cfg.relPoint, cfg.x, cfg.y = point, relPoint, x, y
end

local function ApplyAnchor(g)
    local f, cfg = anchors[g], db.groups[g]
    f:ClearAllPoints()
    f:SetPoint(cfg.point, UIParent, cfg.relPoint, cfg.x, cfg.y)
    local long = cfg.size * 4 + db.spacing * 3
    if cfg.dir == "V" then
        f:SetWidth(cfg.size); f:SetHeight(long)
    else
        f:SetWidth(long); f:SetHeight(cfg.size)
    end
end

local function CreateAnchor(g)
    local f = CreateFrame("Frame", "PvPKitAnchor_" .. g, UIParent)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnchor(g)
    end)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture(0.78, 0.61, 0.43, 0.35)

    f.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.label:SetPoint("BOTTOM", f, "TOP", 0, 2)
    f.label:SetText("PvP Kit - " .. GROUP_LABEL[g] .. " (arrastra para mover)")

    anchors[g] = f
    ApplyAnchor(g)
end

local function ApplyLock()
    for _, f in pairs(anchors) do
        f:EnableMouse(not db.locked)
        if db.locked then
            f.bg:Hide(); f.label:Hide()
        else
            f.bg:Show(); f.label:Show()
        end
    end
    if ns.ApplyAlertsLock then ns.ApplyAlertsLock() end  -- las alertas se mueven igual que las barras
end

local function CreateButton(g)
    local b = CreateFrame("Frame", nil, anchors[g])

    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetTexture(0, 0, 0, 0.85)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.flash = b:CreateTexture(nil, "OVERLAY")
    b.flash:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.flash:SetBlendMode("ADD")
    b.flash:SetVertexColor(1, 0.85, 0.3)
    b.flash:SetPoint("CENTER", 0, 0)
    b.flash:Hide()

    return b
end

local function SizeButton(b, size)
    if b.size == size then return end
    b.size = size
    b:SetWidth(size); b:SetHeight(size)
    b.flash:SetWidth(size * 1.9); b.flash:SetHeight(size * 1.9)
end

local function GetButton(g, i)
    local list = buttons[g]
    if not list[i] then list[i] = CreateButton(g) end
    return list[i]
end

local function SetButton(b, s, state)
    b.icon:SetTexture(s.icon)
    if state == "norage" then
        b.icon:SetVertexColor(0.35, 0.35, 1)
    elseif UnitExists("target") and IsSpellInRange(s.name, "target") == 0 then
        b.icon:SetVertexColor(1, 0.25, 0.25)
    else
        b.icon:SetVertexColor(1, 1, 1)
    end
    b:Show()
end

-- Aviso grande: destello al inicio y desvanecido al final
local function Flash(b, age)
    if age < FLASH_TIME then
        b.flash:SetAlpha(1 - age / FLASH_TIME)
        b.flash:Show()
    else
        b.flash:Hide()
    end
end

local function AnimatePop(b, age)
    Flash(b, age)
    local left = db.popTime - age
    b:SetAlpha(left < FADE_TIME and left / FADE_TIME or 1)
end

local counts = { main = 0, cd = 0, def = 0, fav = 0 }

-- Procs: en el aviso grande mientras dure el buff
local function RenderProcs(now, visible)
    if not db.features.procs then return end
    for _, p in ipairs(ns.procs) do
        local name, _, icon, count
        if p.name and not db.disabled[p.id] then name, _, icon, count = UnitBuff("player", p.name) end
        if name and p.minStacks and (count or 0) < p.minStacks then name = nil end
        if name and not p.active then
            p.startT = now
            Log(p.name .. ": proc activo")
        end
        p.active = name ~= nil

        if visible and name and counts.main < db.groups.main.max then
            counts.main = counts.main + 1
            local b = GetButton("main", counts.main)
            b.icon:SetTexture(icon)
            b.icon:SetVertexColor(1, 1, 1)
            b:SetAlpha(1)
            Flash(b, now - p.startT)
            b:Show()
        end
    end
end

-- dir: "H" horizontal / "V" vertical
-- align: "start" (izquierda/arriba), "center", "end" (derecha/abajo); el orden de prioridad se mantiene
local function Layout(g, n)
    local cfg = db.groups[g]
    local size, sp = cfg.size, db.spacing
    local step = size + sp
    local total = n * size + (n - 1) * sp
    local vertical = cfg.dir == "V"
    for i = 1, n do
        local b = buttons[g][i]
        SizeButton(b, size)
        b:ClearAllPoints()
        local point, off
        if cfg.align == "start" then
            point, off = vertical and "TOP" or "LEFT", (i - 1) * step
        elseif cfg.align == "end" then
            point, off = vertical and "BOTTOM" or "RIGHT", -(n - i) * step
        else
            point, off = "CENTER", (i - 1) * step - total / 2 + size / 2
        end
        if vertical then
            b:SetPoint(point, anchors[g], point, 0, -off)
        else
            b:SetPoint(point, anchors[g], point, off, 0)
        end
    end
end

---------------------------------------------------------------------------
-- Bucle principal
---------------------------------------------------------------------------


local function Describe(s)
    local usable, noRage = IsUsableSpell(s.name)
    local start, duration, enabled = GetSpellCooldown(s.name)
    return string.format("usable=%s noRage=%s start=%s dur=%s enabled=%s inCombat=%s",
        tostring(usable), tostring(noRage), tostring(start), tostring(duration), tostring(enabled),
        tostring(UnitAffectingCombat("player")))
end

local function Render()
    local now = GetTime()
    if testMode and now > testUntil then testMode = false end
    local preview = testMode or not db.locked  -- mientras se mueven las barras se ve todo
    local visible = db.enabled
        and (testMode or not db.locked or not db.onlyCombat or UnitAffectingCombat("player"))
    counts.main, counts.cd, counts.def, counts.fav = 0, 0, 0, 0
    RenderProcs(now, visible)

    for _, s in ipairs(known) do
        local state
        if preview then state = "ready" else state = GetState(s, now) end

        -- Recien disponible: lanzar aviso grande (no en la primera lectura ni justo tras cambiar de postura)
        if state and not s.lastState and s.seen and now > quietUntil then s.popT = now end
        if not state then s.popT = nil end
        if state ~= s.lastState and s.seen then
            Log(string.format("%s: %s -> %s%s | %s", s.name, tostring(s.lastState), tostring(state),
                s.popT == now and " (aviso)" or "", Describe(s)))
        end
        s.seen, s.lastState = true, state

        if visible and state then
            local bar = db.favorites[s.id] and "fav" or (s.def and "def" or "cd")
            if db.features["bar_" .. bar] and counts[bar] < db.groups[bar].max then
                counts[bar] = counts[bar] + 1
                SetButton(GetButton(bar, counts[bar]), s, state)
            end
            local age = s.popT and now - s.popT
            if preview then age = FLASH_TIME end  -- vista previa: aviso grande fijo
            if db.features.pop and age and age < db.popTime and counts.main < db.groups.main.max then
                counts.main = counts.main + 1
                local b = GetButton("main", counts.main)
                SetButton(b, s, state)
                AnimatePop(b, age)
            end
        end
    end

    for g, list in pairs(buttons) do
        for i = counts[g] + 1, #list do list[i]:Hide() end
        Layout(g, counts[g])
    end
end

local driver = CreateFrame("Frame")
local elapsedSince = 0
local lastError
local function OnUpdate(_, elapsed)
    elapsedSince = elapsedSince + elapsed
    if elapsedSince < THROTTLE then return end
    elapsedSince = 0
    local ok, err = pcall(Render)
    if not ok and err ~= lastError then
        lastError = err
        LogError(err)
    end
end

---------------------------------------------------------------------------
-- Comandos
---------------------------------------------------------------------------

local GROUP_ALIAS = { aviso = "main", ofensivas = "cd", ofe = "cd", defensivas = "def", def = "def", favoritas = "fav", fav = "fav" }

local function Help()
    Print("comandos:")
    Print("  /pvpkit config  - abrir la ventana de opciones")
    Print("  /pvpkit demo  - demostración de las alertas JcJ on/off")
    Print("  /pvpkit unlock | lock  - mover el aviso y las barras")
    Print("  /pvpkit test  - mostrar todas las habilidades conocidas")
    Print("  /pvpkit size aviso|ofensivas|defensivas <px>  - tamano (actual: " .. db.groups.main.size
        .. " / " .. db.groups.cd.size .. " / " .. db.groups.def.size .. ")")
    Print("  /pvpkit max aviso|ofensivas|defensivas <n>  - maximo de iconos")
    Print("  /pvpkit pop <seg>  - duracion del aviso grande (actual: " .. db.popTime .. ")")
    Print("  /pvpkit combat  - solo en combate on/off (actual: " .. (db.onlyCombat and "on" or "off") .. ")")
    Print("  /pvpkit list  - lista de habilidades con su numero")
    Print("  /pvpkit toggle <n>  - activar/desactivar una habilidad")
    Print("  /pvpkit reset  - volver a la configuracion por defecto")
end

local function List()
    for i, s in ipairs(ns.spells) do
        local name = GetSpellInfo(s.id) or ("?" .. s.id)
        local isKnown = false
        for _, k in ipairs(known) do if k == s then isKnown = true break end end
        local status = db.disabled[s.id] and "|cffff4040off|r" or "|cff40ff40on|r"
        Print(string.format("%2d. %s%s|r  %s", i, isKnown and "|cffffffff" or "|cff808080", name, status))
    end
end

SLASH_PVPKIT1 = "/pvpkit"
SLASH_PVPKIT2 = "/pvk"
SlashCmdList.PVPKIT = function(msg)
    local cmd, a, b = strsplit(" ", strlower(strtrim(msg or "")))
    if cmd == "unlock" then
        db.locked = false; ApplyLock(); Print("desbloqueado, arrastra el aviso y la barra. /pvpkit lock para fijar.")
    elseif cmd == "lock" then
        db.locked = true; ApplyLock(); Print("bloqueado.")
    elseif cmd == "test" then
        testMode = true; testUntil = GetTime() + TEST_TIME
        Print("modo prueba durante " .. TEST_TIME .. " segundos.")
    elseif cmd == "size" or cmd == "max" then
        local g, v = GROUP_ALIAS[a or ""], tonumber(b or "")
        if not g or not v then Print("uso: /pvpkit " .. cmd .. " aviso|ofensivas|defensivas <numero>") return end
        db.groups[g][cmd] = v
        ApplyAnchor(g)
        Print(GROUP_LABEL[g] .. ": " .. cmd .. " = " .. v)
    elseif cmd == "pop" then
        local v = tonumber(a or "")
        if not v then Print("uso: /pvpkit pop <segundos>") return end
        db.popTime = v; Print("aviso grande: " .. v .. "s")
    elseif cmd == "combat" then
        db.onlyCombat = not db.onlyCombat; Print("solo en combate: " .. (db.onlyCombat and "on" or "off"))
    elseif cmd == "list" then
        List()
    elseif cmd == "toggle" then
        local s = ns.spells[tonumber(a or "")]
        if not s then Print("numero invalido, usa /pvpkit list") return end
        db.disabled[s.id] = not db.disabled[s.id] or nil
        Print((s.name or s.id) .. ": " .. (db.disabled[s.id] and "desactivada" or "activada"))
    elseif cmd == "demo" then
        Print("demostración de alertas " .. (ns.ToggleDemo() and "activada" or "desactivada"))
    elseif cmd == "config" then
        ns.ToggleOptions()
    elseif cmd == "reset" then
        ns.ResetDefaults()
    else
        Help()
    end
end


local GROUP_ORDER = { "main", "cd", "def", "fav" }

local function ApplyAll()
    for _, g in ipairs(GROUP_ORDER) do ApplyAnchor(g) end
end

-- API para Options.lua
function ns.GetDB() return db end
function ns.GetKnown() return known end
ns.ApplyGroup = function() ApplyAll() end

---------------------------------------------------------------------------
-- Perfiles
---------------------------------------------------------------------------

local function CharKey()
    return UnitName("player") .. " - " .. GetRealmName()
end

local function DeepCopy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = type(v) == "table" and DeepCopy(v) or v end
    return c
end

-- Actualiza opciones guardadas por versiones anteriores del addon
local function MigrateProfile(p)
    p.warn, p.groupOverride, p.optionsTab = nil, nil, nil
    if (p.version or 1) < 2 then p.popTime = 2 end
    if (p.version or 1) < 3 then p.groups.def.max = 12 end
    if (p.version or 1) < 4 then
        for _, cfg in pairs(p.groups) do cfg.zone, cfg.align = nil, "center" end
    end
    p.version = 4
end

-- Activa un perfil (lo crea vacio si no existe) y lo aplica en pantalla
local function UseProfile(name)
    if not root.profiles[name] then root.profiles[name] = { version = 4 } end
    root.chars[CharKey()] = name
    db = root.profiles[name]
    CopyDefaults(defaults, db)
    MigrateProfile(db)
    if anchors.main then
        ApplyAll()
        ApplyLock()
    end
end

-- Pasa de la version sin perfiles (todo en la raiz) a perfiles
local function InitRoot()
    PvPKitDB = PvPKitDB or {}
    root = PvPKitDB
    if not root.profiles then
        local legacy = {}
        for k, v in pairs(root) do
            if k ~= "log" and k ~= "debug" then legacy[k] = v end
        end
        for k in pairs(legacy) do root[k] = nil end
        root.profiles = { [DEFAULT_PROFILE] = legacy }
    end
    root.chars = root.chars or {}
    root.log = root.log or {}
    local name = root.chars[CharKey()]
    if not name or not root.profiles[name] then name = DEFAULT_PROFILE end
    UseProfile(name)
end

function ns.GetCurrentProfile() return root.chars[CharKey()] end

function ns.GetProfiles()
    local names = {}
    for name in pairs(root.profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function ns.SetProfile(name)
    UseProfile(name)
    Print("perfil: " .. name)
end

-- Crea un perfil nuevo (vacio o copia del actual) y lo activa. Devuelve false si el nombre no vale.
ns.MAX_PROFILES = 5

function ns.NewProfile(name, copyCurrent)
    name = strtrim(name or "")
    if name == "" or root.profiles[name] or #ns.GetProfiles() >= ns.MAX_PROFILES then return false end
    root.profiles[name] = copyCurrent and DeepCopy(db) or { version = 4 }
    ns.SetProfile(name)
    return true
end

-- Borra el perfil activo y pasa a otro. No se puede borrar el ultimo.
function ns.DeleteProfile()
    local names = ns.GetProfiles()
    if #names <= 1 then return false end
    local current = ns.GetCurrentProfile()
    root.profiles[current] = nil
    for char, p in pairs(root.chars) do
        if p == current then root.chars[char] = nil end
    end
    local fallback = root.profiles[DEFAULT_PROFILE] and DEFAULT_PROFILE or ns.GetProfiles()[1]
    ns.SetProfile(fallback)
    return true
end

-- Vuelve el perfil activo a la configuracion original
function ns.ResetDefaults()
    root.profiles[ns.GetCurrentProfile()] = { version = 4 }
    UseProfile(ns.GetCurrentProfile())
    Print("configuracion restaurada.")
end

-- Vista previa: muestra todo durante TEST_TIME segundos
function ns.StartTest()
    testMode = true
    testUntil = GetTime() + TEST_TIME
end

function ns.SetLocked(locked)
    db.locked = locked
    ApplyLock()
end

function ns.SetEnabled(on)
    db.enabled = on
    Print(on and "activado." or "desactivado.")
end

---------------------------------------------------------------------------
-- Eventos
---------------------------------------------------------------------------

driver:RegisterEvent("PLAYER_LOGIN")
driver:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        -- Deteccion de clase: cada clase registra su lista en ns.classes (Warrior.lua, Shaman.lua...)
        local classLabel, class = UnitClass("player")
        local data = ns.classes[class]
        if not data then
            local msg = "todavía no tiene habilidades para " .. classLabel .. "."
            SlashCmdList.PVPKIT = function() Print(msg) end
            Print(msg)
            return
        end
        ns.class, ns.classIcon = class, data.icon
        ns.spells, ns.procs = {}, data.procs
        for _, s in ipairs(data.spells) do ns.spells[#ns.spells + 1] = s end
        for _, s in ipairs(ns.RACIALS) do ns.spells[#ns.spells + 1] = s end
        InitRoot()

        CreateAnchor("main")
        CreateAnchor("cd")
        CreateAnchor("def")
        CreateAnchor("fav")
        ApplyAll()
        ApplyLock()
        ScanSpellbook()

        self:RegisterEvent("SPELLS_CHANGED")
        self:RegisterEvent("LEARNED_SPELL_IN_TAB")
        self:RegisterEvent("PLAYER_TALENT_UPDATE")
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        self:SetScript("OnUpdate", OnUpdate)
        if ns.InitOptions then  -- falta si el juego no se reinicio tras anadir Options.lua
            local ok, err = pcall(ns.InitOptions)
            if not ok then ns.LogError("opciones: " .. tostring(err)) end
        end
        do
            local ok, err = pcall(ns.InitAlerts)
            if not ok then ns.LogError("alertas: " .. tostring(err)) end
        end
        Print("cargado. Boton en el minimapa o /pvpkit para ver los comandos.")
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        quietUntil = GetTime() + STANCE_QUIET
    else
        ScanSpellbook()
    end
end)
