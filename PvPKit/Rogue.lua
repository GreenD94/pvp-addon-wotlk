local _, ns = ...

-- Picaro. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Excepcion (como Cargar): Paso de las Sombras va en la ofensiva.
local spells = {
    -- Ofensivas: hacen dano
    { id = 51690 },                     -- Killing Spree
    { id = 14251 },                     -- Riposte (tras parar)
    { id = 14278 },                     -- Ghostly Strike
    { id = 1776 },                      -- Gouge
    { id = 36554, cond = "inRange" },   -- Shadowstep

    -- Defensivas: no hacen dano (control, escapes, potenciadores)
    { id = 1766,  def = true, cond = "interrupt", kick = true },  -- Kick
    { id = 408,   def = true },  -- Kidney Shot
    { id = 2094,  def = true },  -- Blind
    { id = 51722, def = true },  -- Dismantle
    { id = 31224, def = true },  -- Cloak of Shadows
    { id = 5277,  def = true },  -- Evasion
    { id = 1856,  def = true },  -- Vanish
    { id = 2983,  def = true },  -- Sprint
    { id = 1966,  def = true },  -- Feint
    { id = 14185, def = true },  -- Preparation
    { id = 1725,  def = true },  -- Distract
    { id = 1784,  def = true },  -- Stealth
    { id = 14183, def = true },  -- Premeditation
    { id = 14177, def = true },  -- Cold Blood
    { id = 13750, def = true },  -- Adrenaline Rush
    { id = 13877, def = true },  -- Blade Flurry
    { id = 51713, def = true },  -- Shadow Dance
    { id = 57934, def = true },  -- Tricks of the Trade
}

local procs = {}

ns.classes = ns.classes or {}
ns.classes.ROGUE = {
    icon = "Interface\\Icons\\Ability_Stealth",
    spells = spells,
    procs = procs,
}
