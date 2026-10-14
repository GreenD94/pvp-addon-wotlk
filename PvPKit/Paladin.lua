local _, ns = ...

-- Paladin. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Choque Sagrado se usa sobre todo para curar: va en defensivas.
local spells = {
    -- Ofensivas: hacen dano
    { id = 24275 },  -- Hammer of Wrath (objetivo < 20%)
    { id = 35395 },  -- Crusader Strike
    { id = 53385 },  -- Divine Storm
    { id = 20271 },  -- Judgement of Light (los Juicios comparten cooldown)
    { id = 53408 },  -- Judgement of Wisdom
    { id = 53407 },  -- Judgement of Justice
    { id = 879 },    -- Exorcism
    { id = 26573 },  -- Consecration
    { id = 31935 },  -- Avenger's Shield
    { id = 53595 },  -- Hammer of the Righteous
    { id = 53600 },  -- Shield of Righteousness
    { id = 2812 },   -- Holy Wrath

    -- Defensivas: no hacen dano (control, curacion, manos, defensivos, potenciadores)
    { id = 853,   def = true },  -- Hammer of Justice
    { id = 20066, def = true },  -- Repentance
    { id = 642,   def = true },  -- Divine Shield
    { id = 498,   def = true },  -- Divine Protection
    { id = 633,   def = true },  -- Lay on Hands
    { id = 1022,  def = true },  -- Hand of Protection
    { id = 1044,  def = true },  -- Hand of Freedom
    { id = 6940,  def = true },  -- Hand of Sacrifice
    { id = 1038,  def = true },  -- Hand of Salvation
    { id = 20473, def = true },  -- Holy Shock
    { id = 20925, def = true },  -- Holy Shield
    { id = 64205, def = true },  -- Divine Sacrifice
    { id = 31821, def = true },  -- Aura Mastery
    { id = 31842, def = true },  -- Divine Illumination
    { id = 20216, def = true },  -- Divine Favor
    { id = 31884, def = true },  -- Avenging Wrath
    { id = 54428, def = true },  -- Divine Plea
    { id = 62124, def = true, cond = "notTanking" },  -- Hand of Reckoning
    { id = 31789, def = true },  -- Righteous Defense
}

local procs = {
    { id = 59578 },  -- The Art of War (Destello de luz / Exorcismo instantaneo)
    { id = 53672 },  -- Infusion of Light
    { id = 31834 },  -- Light's Grace
}

ns.classes = ns.classes or {}
ns.classes.PALADIN = {
    icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
    spells = spells,
    procs = procs,
}
