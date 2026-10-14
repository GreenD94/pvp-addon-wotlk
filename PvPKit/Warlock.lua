local _, ns = ...

-- Brujo. Mismo formato que Warrior.lua (las raciales estan en Racials.lua).
-- Regla: si hace dano es ofensiva; si no, defensiva (def = true).
-- Bloqueo de hechizo es del manafago (libro de la mascota) y no se rastrea.
-- Excepcion (como Cargar): Carga demoniaca va en la ofensiva.
local spells = {
    -- Ofensivas: hacen dano
    { id = 17877 },                    -- Shadowburn
    { id = 17962 },                    -- Conflagrate
    { id = 50796 },                    -- Chaos Bolt
    { id = 48181 },                    -- Haunt
    { id = 30283 },                    -- Shadowfury
    { id = 6789 },                     -- Death Coil
    { id = 603 },                      -- Curse of Doom
    { id = 50589 },                    -- Immolation Aura (Metamorfosis)
    { id = 54785, cond = "inRange" },  -- Demon Charge (Metamorfosis)
    { id = 1122 },                     -- Inferno

    -- Defensivas: no hacen dano (control, escapes, defensivos, potenciadores)
    { id = 5484,  def = true },  -- Howl of Terror
    { id = 48020, def = true },  -- Demonic Circle: Teleport
    { id = 6229,  def = true },  -- Shadow Ward
    { id = 29858, def = true },  -- Soulshatter
    { id = 18708, def = true },  -- Fel Domination
    { id = 47193, def = true },  -- Demonic Empowerment
    { id = 47241, def = true },  -- Metamorphosis
}

local procs = {
    { id = 17941 },  -- Shadow Trance (Ocaso: Descarga de las Sombras instantanea)
    { id = 34936 },  -- Backlash
    { id = 47383 },  -- Molten Core
    { id = 63165 },  -- Decimation
    { id = 64368 },  -- Eradication
    { id = 47283 },  -- Empowered Imp
}

ns.classes = ns.classes or {}
ns.classes.WARLOCK = {
    icon = "Interface\\Icons\\Spell_Shadow_DeathCoil",
    spells = spells,
    procs = procs,
}
