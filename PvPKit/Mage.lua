local _, ns = ...

-- Mago. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
local spells = {
    -- Ofensivas: hacen dano
    { id = 44572 },  -- Deep Freeze
    { id = 2136 },   -- Fire Blast
    { id = 44425 },  -- Arcane Barrage
    { id = 120 },    -- Cone of Cold
    { id = 122 },    -- Frost Nova
    { id = 11113 },  -- Blast Wave
    { id = 31661 },  -- Dragon's Breath
    { id = 55342 },  -- Mirror Image
    { id = 31687 },  -- Summon Water Elemental

    -- Defensivas: no hacen dano (cortes, escapes, escudos, potenciadores)
    { id = 2139,  def = true, cond = "interrupt", kick = true },  -- Counterspell
    { id = 1953,  def = true },  -- Blink
    { id = 45438, def = true },  -- Ice Block
    { id = 11426, def = true },  -- Ice Barrier
    { id = 543,   def = true },  -- Fire Ward
    { id = 6143,  def = true },  -- Frost Ward
    { id = 66,    def = true },  -- Invisibility
    { id = 11958, def = true },  -- Cold Snap
    { id = 12472, def = true },  -- Icy Veins
    { id = 12042, def = true },  -- Arcane Power
    { id = 12043, def = true },  -- Presence of Mind
    { id = 11129, def = true },  -- Combustion
    { id = 12051, def = true },  -- Evocation
}

local procs = {
    { id = 57761 },  -- Brain Freeze (Bola de Fuego / Descarga de Escarcha de fuego instantanea)
    { id = 44544 },  -- Fingers of Frost
    { id = 48108 },  -- Hot Streak (Piroexplosion instantanea)
    { id = 44401 },  -- Missile Barrage
    { id = 12536 },  -- Clearcasting (Concentracion arcana)
    { id = 64343 },  -- Impact (proxima Explosion de fuego aturde)
    { id = 54741 },  -- Firestarter (Ola explosiva/Aliento de dragon -> Fogonazo instantaneo)
}

ns.classes = ns.classes or {}
ns.classes.MAGE = {
    icon = "Interface\\Icons\\Spell_Frost_IceStorm",
    spells = spells,
    procs = procs,
}
