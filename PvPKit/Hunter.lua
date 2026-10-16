local _, ns = ...

-- Cazador. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Las habilidades de la mascota no estan en el libro del jugador y no se rastrean.
local spells = {
    -- Ofensivas: hacen dano
    { id = 53351 },  -- Kill Shot (objetivo < 20%)
    { id = 53209 },  -- Chimera Shot
    { id = 53301 },  -- Explosive Shot
    { id = 19434 },  -- Aimed Shot
    { id = 3044 },   -- Arcane Shot
    { id = 2643 },   -- Multi-Shot
    { id = 3674 },   -- Black Arrow
    { id = 34026 },  -- Kill Command
    { id = 19503 },  -- Scatter Shot
    { id = 13813 },  -- Explosive Trap (las trampas de fuego comparten cooldown)
    { id = 13795 },  -- Immolation Trap
    { id = 2973 },   -- Raptor Strike
    { id = 1495 },   -- Mongoose Bite (tras esquivar)
    { id = 19306 },  -- Counterattack (tras parar)

    -- Defensivas: no hacen dano (control, escapes, potenciadores)
    { id = 34490, def = true, cond = "interrupt", kick = true },  -- Silencing Shot
    { id = 1499,  def = true },  -- Freezing Trap (las trampas de escarcha comparten cooldown)
    { id = 13809, def = true },  -- Frost Trap
    { id = 34600, def = true },  -- Snake Trap
    { id = 19386, def = true },  -- Wyvern Sting
    { id = 5116,  def = true },  -- Concussive Shot
    { id = 19577, def = true },  -- Intimidation
    { id = 1513,  def = true },  -- Scare Beast
    { id = 19263, def = true },  -- Deterrence
    { id = 5384,  def = true },  -- Feign Death
    { id = 781,   def = true },  -- Disengage
    { id = 53271, def = true, cond = "groupCC", cats = "root" },  -- Master's Call, solo con raices o frenados en el grupo
    { id = 19801, def = true, cond = "purge" },  -- Tranquilizing Shot, solo si el objetivo tiene algo que quitar
    { id = 34477, def = true },  -- Misdirection
    { id = 1543,  def = true },  -- Flare
    { id = 3045,  def = true },  -- Rapid Fire
    { id = 19574, def = true },  -- Bestial Wrath
    { id = 23989, def = true },  -- Readiness
}

local procs = {
    { id = 56453 },  -- Lock and Load (Disparo explosivo / Disparo arcano sin cooldown)
    { id = 53220 },  -- Improved Steady Shot
}

ns.classes = ns.classes or {}
ns.classes.HUNTER = {
    icon = "Interface\\Icons\\INV_Weapon_Bow_07",
    spells = spells,
    procs = procs,
}
