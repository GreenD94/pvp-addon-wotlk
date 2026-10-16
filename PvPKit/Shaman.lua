local _, ns = ...

-- Chaman. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- kick = sirve para cortar lanzamientos (¡Cortalo!)
local spells = {
    -- Ofensivas: hacen dano
    { id = 51505 },  -- Lava Burst
    { id = 17364 },  -- Stormstrike
    { id = 60103 },  -- Lava Lash
    { id = 8042 },   -- Earth Shock (los choques comparten cooldown)
    { id = 8050 },   -- Flame Shock
    { id = 8056 },   -- Frost Shock
    { id = 421 },    -- Chain Lightning
    { id = 1535 },   -- Fire Nova
    { id = 51490 },  -- Thunderstorm
    { id = 51533 },  -- Feral Spirit
    { id = 2894 },   -- Fire Elemental Totem
    { id = 2062 },   -- Earth Elemental Totem

    -- Defensivas: no hacen dano (control, curacion, totems de utilidad, potenciadores)
    { id = 57994, def = true, cond = "interrupt", kick = true },  -- Wind Shear
    { id = 8177,  def = true, cond = "castingOnMe" },  -- Grounding Totem, solo si el objetivo me castea a mi
    { id = 8143,  def = true, cond = "groupCC", cats = "fear" },  -- Tremor Totem, solo con miedo o seduccion en el grupo
    { id = 51886, def = true, cond = "dispel" },  -- Cleanse Spirit, solo si hay algo que quitar
    { id = 526,   def = true, cond = "dispel" },  -- Cure Toxins, idem
    { id = 370,   def = true, cond = "purge" },   -- Purge, solo si el objetivo tiene algo que purgar
    { id = 2484,  def = true },  -- Earthbind Totem
    { id = 5730,  def = true },  -- Stoneclaw Totem
    { id = 51514, def = true },  -- Hex
    { id = 30823, def = true },  -- Shamanistic Rage
    { id = 61295, def = true },  -- Riptide
    { id = 16188, def = true },  -- Nature's Swiftness
    { id = 16166, def = true },  -- Elemental Mastery
    { id = 55198, def = true },  -- Tidal Force
    { id = 16190, def = true },  -- Mana Tide Totem
    { id = 2825,  def = true },  -- Bloodlust (Horda)
    { id = 32182, def = true },  -- Heroism (Alianza)
}

-- minStacks = solo se muestra con al menos ese numero de acumulaciones
local procs = {
    { id = 53817, minStacks = 5 },  -- Maelstrom Weapon (5 cargas: hechizo instantaneo)
    { id = 53390 },                 -- Tidal Waves (oleadas: sanacion mas rapida)
    { id = 16246 },                 -- Clearcasting (Foco elemental: hechizos mas baratos)
}

ns.classes = ns.classes or {}
ns.classes.SHAMAN = {
    icon = "Interface\\Icons\\Spell_Nature_BloodLust",
    spells = spells,
    procs = procs,
}
