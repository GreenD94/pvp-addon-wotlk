local _, ns = ...

-- Druida. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Excepcion (como Cargar): las Cargas salvajes van en la ofensiva.
local spells = {
    -- Ofensivas: hacen dano
    { id = 48505 },                                -- Starfall
    { id = 50516 },                                -- Typhoon
    { id = 33831 },                                -- Force of Nature
    { id = 33878 },                                -- Mangle (Bear)
    { id = 22570 },                                -- Maim
    { id = 16857 },                                -- Faerie Fire (Feral)
    { id = 16979, cond = "inRange", kick = true }, -- Feral Charge - Bear (tambien corta)
    { id = 49376, cond = "inRange" },              -- Feral Charge - Cat

    -- Defensivas: no hacen dano (control, curacion, defensivos, potenciadores)
    { id = 5211,  def = true },  -- Bash
    { id = 22812, def = true },  -- Barkskin
    { id = 61336, def = true },  -- Survival Instincts
    { id = 22842, def = true },  -- Frenzied Regeneration
    { id = 29166, def = true },  -- Innervate
    { id = 2782,  def = true, cond = "dispel" },  -- Remove Curse
    { id = 2893,  def = true, cond = "dispel" },  -- Abolish Poison
    { id = 8946,  def = true, cond = "dispel" },  -- Cure Poison
    { id = 17116, def = true },  -- Nature's Swiftness
    { id = 18562, def = true },  -- Swiftmend
    { id = 48438, def = true },  -- Wild Growth
    { id = 740,   def = true },  -- Tranquility
    { id = 16689, def = true },  -- Nature's Grasp
    { id = 20484, def = true },  -- Rebirth
    { id = 1850,  def = true },  -- Dash
    { id = 5215,  def = true },  -- Prowl
    { id = 6795,  def = true, cond = "notTanking" },  -- Growl
    { id = 5209,  def = true },  -- Challenging Roar
    { id = 5229,  def = true },  -- Enrage
    { id = 5217,  def = true },  -- Tiger's Fury
    { id = 50334, def = true },  -- Berserk
}

local procs = {
    { id = 16870 },  -- Clearcasting (Presagio de claridad)
    { id = 48517 },  -- Eclipse (Solar)
    { id = 48518 },  -- Eclipse (Lunar)
    { id = 69369 },  -- Predator's Swiftness (hechizo de naturaleza instantaneo)
    { id = 16886 },  -- Nature's Grace
}

ns.classes = ns.classes or {}
ns.classes.DRUID = {
    icon = "Interface\\Icons\\Ability_Druid_Maul",
    spells = spells,
    procs = procs,
}
