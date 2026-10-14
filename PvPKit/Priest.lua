local _, ns = ...

-- Sacerdote. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Penitencia y Choque Sagrado (paladin) se usan sobre todo para curar: van en defensivas.
local spells = {
    -- Ofensivas: hacen dano
    { id = 32379 },  -- Shadow Word: Death
    { id = 8092 },   -- Mind Blast
    { id = 14914 },  -- Holy Fire
    { id = 34433 },  -- Shadowfiend

    -- Defensivas: no hacen dano (control, curacion, defensivos, potenciadores)
    { id = 15487, def = true, cond = "interrupt", kick = true },  -- Silence
    { id = 8122,  def = true },  -- Psychic Scream
    { id = 64044, def = true },  -- Psychic Horror
    { id = 47585, def = true },  -- Dispersion
    { id = 33206, def = true },  -- Pain Suppression
    { id = 47788, def = true },  -- Guardian Spirit
    { id = 10060, def = true },  -- Power Infusion
    { id = 47540, def = true },  -- Penance
    { id = 33076, def = true },  -- Prayer of Mending
    { id = 34861, def = true },  -- Circle of Healing
    { id = 19236, def = true },  -- Desperate Prayer
    { id = 586,   def = true },  -- Fade
    { id = 6346,  def = true },  -- Fear Ward
    { id = 14751, def = true },  -- Inner Focus
    { id = 724,   def = true },  -- Lightwell
    { id = 64843, def = true },  -- Divine Hymn
    { id = 64901, def = true },  -- Hymn of Hope
}

local procs = {
    { id = 33151 },                 -- Surge of Light (Destello de luz instantaneo y gratis)
    { id = 63731, minStacks = 3 },  -- Serendipity (3 cargas)
    { id = 59887 },                 -- Borrowed Time
    { id = 34754 },                 -- Clearcasting (Concentracion sagrada)
}

ns.classes = ns.classes or {}
ns.classes.PRIEST = {
    icon = "Interface\\Icons\\Spell_Holy_PowerWordShield",
    spells = spells,
    procs = procs,
}
