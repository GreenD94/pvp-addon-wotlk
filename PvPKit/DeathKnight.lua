local _, ns = ...

-- Caballero de la Muerte. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Excepcion (como Cargar): Atracción letal va en la ofensiva.
-- Ojo: los hechizos con runas muestran como "no disponible" el tiempo de recarga de las runas.
local spells = {
    -- Ofensivas: hacen dano
    { id = 49576 },  -- Death Grip
    { id = 56815 },  -- Rune Strike (tras esquivar/parar)
    { id = 49184 },  -- Howling Blast
    { id = 43265 },  -- Death and Decay
    { id = 49158 },  -- Corpse Explosion
    { id = 49206 },  -- Summon Gargoyle
    { id = 49028 },  -- Dancing Rune Weapon
    { id = 46584 },  -- Raise Dead
    { id = 42650 },  -- Army of the Dead

    -- Defensivas: no hacen dano (cortes, control, defensivos, potenciadores)
    { id = 47528, def = true, cond = "interrupt", kick = true },  -- Mind Freeze
    { id = 47476, def = true, kick = true },                      -- Strangulate (silencia siempre)
    { id = 49203, def = true },  -- Hungering Cold
    { id = 48707, def = true },  -- Anti-Magic Shell
    { id = 51052, def = true },  -- Anti-Magic Zone
    { id = 48792, def = true },  -- Icebound Fortitude
    { id = 51271, def = true },  -- Unbreakable Armor
    { id = 55233, def = true },  -- Vampiric Blood
    { id = 48982, def = true },  -- Rune Tap
    { id = 49039, def = true },  -- Lichborne
    { id = 49222, def = true },  -- Bone Shield
    { id = 48743, def = true },  -- Death Pact
    { id = 49005, def = true },  -- Mark of Blood
    { id = 49796, def = true },  -- Deathchill
    { id = 49016, def = true },  -- Hysteria
    { id = 47568, def = true },  -- Empower Rune Weapon
    { id = 45529, def = true },  -- Blood Tap
    { id = 57330, def = true },  -- Horn of Winter
    { id = 56222, def = true, cond = "notTanking" },  -- Dark Command
}

local procs = {
    { id = 51124 },  -- Killing Machine
    { id = 59052 },  -- Freezing Fog (Rime: Explosion aullante gratis)
}

ns.classes = ns.classes or {}
ns.classes.DEATHKNIGHT = {
    icon = "Interface\\Icons\\Spell_Deathknight_ClassIcon",
    spells = spells,
    procs = procs,
}
