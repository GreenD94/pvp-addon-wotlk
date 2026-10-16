local _, ns = ...

-- Alertas JcJ de aliados y enemigos, agrupadas por jugador: su cara una sola vez y,
-- a continuacion, sus alertas una al lado de la otra.
-- Una alerta nueva sale 1,5 s en grande en el centro y despues pasa al panel lateral
-- (uno de aliados y otro de enemigos). Sin cara disponible se usa el emblema de la clase.
-- Modo simple: en vez del hechizo concreto se muestra el efecto (Aturdido, Frenado, Lanzando...).

local SCAN_INTERVAL = 0.1  -- segundos entre lecturas (aliados, enemigos y lanzamientos)
local POP_TIME = 1.5       -- segundos en grande en el centro antes de pasar al panel
local MAX_PER_PLAYER = 8   -- alertas como maximo por jugador
local MAX_CENTER = 4       -- jugadores como maximo en cada fila del centro
local MAX_PANEL = 8        -- jugadores como maximo en cada panel
local DEMO_CYCLE = 16      -- la demo se repite cada N segundos
local HEALTH_ICON = "Interface\\Icons\\Spell_Holy_AshesToAshes"
local FOCUS_ICON = "Interface\\Icons\\Ability_Hunter_SniperShot"
local CLASS_EMBLEMS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local SIDE_COLORS = { ally = { 0.2, 0.9, 0.2 }, enemy = { 0.9, 0.2, 0.2 } }  -- marco de la cara
-- Cara por defecto si el juego no tiene la del jugador: una cara de tu facción para los aliados
-- y de la contraria para los enemigos (humano / orco)
local FACTION_FACES = {
    Alliance = "Interface\\Icons\\Achievement_Character_Human_Male",
    Horde    = "Interface\\Icons\\Achievement_Character_Orc_Male",
}
local function SideIcon(sideKey)
    local mine = UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
    local other = mine == "Horde" and "Alliance" or "Horde"
    return FACTION_FACES[sideKey == "ally" and mine or other]
end
local BORDER_COLORS = {
    tip     = { 1.00, 1.00, 1.00 },  -- consejo (que hacer ahora): blanco, late
    snare   = { 0.40, 0.75, 1.00 },  -- frenado: azul claro
    cc      = { 0.70, 0.30, 1.00 },  -- control: morado
    debuff  = { 1.00, 0.20, 0.20 },  -- perjuicio: rojo
    health  = { 1.00, 0.10, 0.10 },  -- vida baja: rojo intenso
    immune  = { 1.00, 0.82, 0.00 },  -- inmune: dorado
    trinket = { 0.60, 0.60, 0.60 },  -- abalorio usado: gris
    cast    = { 0.30, 0.60, 1.00 },  -- lanzando: azul
    dr      = { 0.40, 0.50, 0.70 },  -- rendimiento decreciente pendiente: gris azulado
    kick    = { 1.00, 0.50, 0.00 },  -- ¡cortalo!: naranja
    focus   = { 1.00, 0.40, 0.10 },  -- lo enfocan: rojo anaranjado
    ecd     = { 0.20, 0.70, 0.70 },  -- cooldown del enemigo usado: turquesa
    purge   = { 0.40, 0.80, 1.00 },  -- purgable: celeste
    drink   = { 0.30, 0.40, 1.00 },  -- bebiendo: azul
    totem   = { 0.20, 0.80, 0.30 },  -- totem enemigo: verde
}
-- orden dentro de cada fila
local KIND_ORDER = { tip = -1, kick = 0, cast = 0.5, cc = 1, snare = 1.2, focus = 1.5, health = 2, debuff = 3, immune = 4,
    purge = 4.5, ecd = 4.6, drink = 4.7, totem = 4.8, dr = 5, trinket = 6 }

-- Modo simple: icono y texto de cada efecto. gray = algo que el enemigo ya gasto (icono en gris).
local function Icon(name) return "Interface\\Icons\\" .. name end
local EFFECTS = {
    stun        = { icon = Icon("Spell_Frost_Stun"),                  label = "Aturdido" },
    fear        = { icon = Icon("Spell_Shadow_Possession"),           label = "Miedo" },
    horror      = { icon = Icon("Spell_Shadow_Possession"),           label = "Miedo" },
    incap       = { icon = Icon("Spell_Nature_Polymorph"),            label = "Incapacitado" },
    cyclone     = { icon = Icon("Spell_Nature_EarthBind"),            label = "Intocable" },
    banish      = { icon = Icon("Spell_Nature_EarthBind"),            label = "Intocable" },
    charm       = { icon = Icon("Spell_Shadow_ShadowWordDominate"),   label = "Controlado" },
    silence     = { icon = Icon("Spell_Shadow_ImpPhaseShift"),        label = "Silenciado" },
    root        = { icon = Icon("Spell_Nature_StrangleVines"),        label = "Enraizado" },
    disarm      = { icon = Icon("Ability_Warrior_Disarm"),            label = "Desarmado" },
    snare       = { icon = Icon("Spell_Nature_Slow"),                 label = "Frenado" },
    healcut     = { icon = Icon("Ability_Warrior_SavageBlow"),        label = "-50% curación" },
    nodispel    = { icon = Icon("Spell_Shadow_UnstableAffliction_3"), label = "No disipar" },
    health      = { icon = HEALTH_ICON,                               label = "Vida baja" },
    focus       = { icon = FOCUS_ICON,                                label = "Lo enfocan" },
    cast        = { icon = Icon("Spell_Holy_MagicalSentry"),          label = "Lanzando" },
    castcc      = { icon = Icon("Spell_Nature_Polymorph"),            label = "Lanza control" },
    kick        = { icon = Icon("Ability_Kick"),                      label = "¡Córtalo!" },
    immune      = { icon = Icon("Spell_Holy_DivineIntervention"),     label = "Inmune" },
    immunePhys  = { icon = Icon("Spell_Holy_SealOfProtection"),       label = "Inmune a físico" },
    immuneMagic = { icon = Icon("Spell_Shadow_NetherCloak"),          label = "Inmune a magia" },
    reflect     = { icon = Icon("Ability_Warrior_ShieldReflection"),  label = "Refleja hechizos" },
    immuneCC    = { icon = Icon("Ability_Warrior_Bladestorm"),        label = "Inmune a control" },
    defensive   = { icon = Icon("Ability_Warrior_ShieldWall"),        label = "Defensivo" },
    trinket     = { icon = Icon("INV_Jewelry_TrinketPVP_01"),         label = "Sin abalorio", gray = true },
    nokick      = { icon = Icon("Ability_Kick"),                      label = "Sin corte", gray = true },
    nodef       = { icon = Icon("Ability_Warrior_ShieldWall"),        label = "Sin defensivo", gray = true },
    nocc        = { icon = Icon("Spell_Frost_Stun"),                  label = "Sin control", gray = true },
    purge       = { icon = Icon("Spell_Nature_Purge"),                label = "Purgar" },
    drink       = { icon = Icon("INV_Drink_07"),                      label = "Bebiendo" },
}

---------------------------------------------------------------------------
-- Controles y perjuicios de JcJ (todas las clases). Se comparan por nombre
-- localizado, asi sirve cualquier rango del hechizo. Clave = spell ID de rango 1.
-- cat: tipo de control (servira para los rendimientos decrecientes)
---------------------------------------------------------------------------

local CC_LABELS = {
    stun = "Aturdido", fear = "Miedo", incap = "Incapacitado", silence = "Silenciado",
    root = "Enraizado", disarm = "Desarmado", horror = "Horror", cyclone = "Ciclón",
    charm = "Controlado", banish = "Desterrado",
}

local CC_SPELLS = {
    -- Aturdimientos
    [853] = "stun",    -- Hammer of Justice
    [1833] = "stun",   -- Cheap Shot
    [408] = "stun",    -- Kidney Shot
    [5211] = "stun",   -- Bash
    [22570] = "stun",  -- Maim
    [9005] = "stun",   -- Pounce
    [7922] = "stun",   -- Charge Stun
    [20253] = "stun",  -- Intercept
    [12809] = "stun",  -- Concussion Blow
    [46968] = "stun",  -- Shockwave
    [20549] = "stun",  -- War Stomp
    [24394] = "stun",  -- Intimidation
    [44572] = "stun",  -- Deep Freeze
    [47481] = "stun",  -- Gnaw (necrofago)
    [30283] = "stun",  -- Shadowfury
    [12355] = "stun",  -- Impact
    [20170] = "stun",  -- Seal of Justice
    [39796] = "stun",  -- Stoneclaw Stun
    [50518] = "stun",  -- Ravage (mascota)
    -- Miedos
    [5782] = "fear",   -- Fear
    [5484] = "fear",   -- Howl of Terror
    [8122] = "fear",   -- Psychic Scream
    [5246] = "fear",   -- Intimidating Shout
    [2094] = "fear",   -- Blind
    [1513] = "fear",   -- Scare Beast
    [10326] = "fear",  -- Turn Evil
    -- Horror
    [6789] = "horror", -- Death Coil
    [64044] = "horror", -- Psychic Horror
    -- Incapacitar / desorientar
    [118] = "incap",   -- Polymorph
    [6770] = "incap",  -- Sap
    [1776] = "incap",  -- Gouge
    [51514] = "incap", -- Hex
    [20066] = "incap", -- Repentance
    [3355] = "incap",  -- Freezing Trap
    [19386] = "incap", -- Wyvern Sting
    [19503] = "incap", -- Scatter Shot
    [2637] = "incap",  -- Hibernate
    [31661] = "incap", -- Dragon's Breath
    [33786] = "cyclone", -- Cyclone
    [605] = "charm",   -- Mind Control
    [6358] = "charm",  -- Seduction
    [710] = "banish",  -- Banish
    -- Silencios
    [15487] = "silence", -- Silence
    [18469] = "silence", -- Counterspell - Silenced
    [1330] = "silence",  -- Garrote - Silence
    [47476] = "silence", -- Strangulate
    [34490] = "silence", -- Silencing Shot
    [24259] = "silence", -- Spell Lock
    [28730] = "silence", -- Arcane Torrent
    [18425] = "silence", -- Kick - Silenced
    [18498] = "silence", -- Gag Order
    -- Raices
    [339] = "root",    -- Entangling Roots
    [122] = "root",    -- Frost Nova
    [33395] = "root",  -- Freeze (elemental de agua)
    [55080] = "root",  -- Shattered Barrier
    [23694] = "root",  -- Improved Hamstring
    [12494] = "root",  -- Frostbite
    [19185] = "root",  -- Entrapment
    [64695] = "root",  -- Earthgrab
    -- Desarmes
    [676] = "disarm",   -- Disarm
    [51722] = "disarm", -- Dismantle
    [64058] = "disarm", -- Psychic Horror (desarme)
    [53359] = "disarm", -- Chimera Shot - Scorpid
}

-- Perjuicios importantes: [id] = efecto (ver EFFECTS)
local DEBUFF_SPELLS = {
    [12294] = "healcut",   -- Mortal Strike
    [13218] = "healcut",   -- Wound Poison
    [19434] = "healcut",   -- Aimed Shot
    [46910] = "healcut",   -- Furious Attacks
    [48301] = "healcut",   -- Mind Trauma
    [30108] = "nodispel",  -- Unstable Affliction
}

-- Inmunidades y defensivos del enemigo: [id] = { efecto, texto del modo detallado }
local IMMUNE_SPELLS = {
    [642]   = { "immune", "INMUNE" },                -- Divine Shield
    [45438] = { "immune", "INMUNE" },                -- Ice Block
    [1022]  = { "immunePhys", "Inmune a físico" },   -- Hand of Protection
    [19263] = { "defensive", "Desvía ataques" },     -- Deterrence
    [31224] = { "immuneMagic", "Inmune a hechizos" },-- Cloak of Shadows
    [48707] = { "immuneMagic", "Absorbe magia" },    -- Anti-Magic Shell
    [23920] = { "reflect", "Refleja hechizos" },     -- Spell Reflection
    [46924] = { "immuneCC", "Inmune a control" },    -- Bladestorm
    [34471] = { "immuneCC", "Inmune a control" },    -- The Beast Within
    [47585] = { "defensive", "-90% daño" },          -- Dispersion
}

-- Abalorio JcJ y "Cada hombre por si mismo" (humano): mismo efecto, 2 min
local TRINKETS = { [42292] = true, [59752] = true }
local TRINKET_CD = 120

-- Rendimientos decrecientes (aproximado): se reinicia 18 s despues de acabar el ultimo control
-- de ese tipo. Texto = como durara el siguiente tras N controles seguidos.
local DR_RESET = 18
local DR_NEXT = { "½", "¼", "inmune" }

-- Cooldowns del enemigo que conviene saber si ya uso: [efecto] = { [id] = segundos de cooldown }
local ENEMY_COOLDOWN_SPELLS = {
    nokick = {  -- Cortes
        [6552] = 10, [72] = 12, [1766] = 10, [2139] = 24, [57994] = 6, [47528] = 10,
        [47476] = 120, [34490] = 20, [15487] = 45, [16979] = 15,
    },
    nodef = {   -- Defensivos y escapes
        [642] = 300, [45438] = 300, [31224] = 90, [33206] = 180, [1022] = 300, [1044] = 25,
        [19263] = 90, [5277] = 180, [1856] = 180, [48707] = 45, [48792] = 120, [22812] = 60,
        [871] = 300, [12975] = 180, [47585] = 120, [498] = 180, [633] = 1200, [47788] = 180,
        [46924] = 90, [23920] = 10, [1953] = 15, [5384] = 30, [2983] = 180, [36554] = 30,
        [48020] = 30,
    },
    nocc = {    -- Controles con cooldown largo
        [853] = 60, [2094] = 180, [8122] = 30, [5484] = 40, [46968] = 20, [5246] = 120,
        [44572] = 30, [408] = 20, [51514] = 45, [20066] = 60, [5211] = 60, [6789] = 120,
        [64044] = 120, [1499] = 30, [19503] = 30, [19386] = 60, [31661] = 20, [49203] = 60,
        [30283] = 20, [12809] = 30,
    },
}

-- Totems enemigos que cambian la pelea: [id] = { texto, duracion maxima, texto corto (modo simple) }
local TOTEM_SPELLS = {
    [8143]  = { "Temblor: miedo y sueño no sirven", 300, "Temblor" },      -- Tremor Totem
    [8177]  = { "Derribador: no lances hechizos", 45, "Derribador" },      -- Grounding Totem
    [8170]  = { "Purificación: quita venenos", 300, "Purificación" },      -- Cleansing Totem
    [16190] = { "Marea de maná: mátalo", 12, "Marea de maná" },            -- Mana Tide Totem
}

-- Beneficios del enemigo que merece la pena purgar/disipar/robar: [id] = texto
local PURGE_BUFFS = {
    [17] = "Escudo",          -- Power Word: Shield
    [11426] = "Escudo",       -- Ice Barrier
    [1044] = "Sin raíces",    -- Hand of Freedom
    [1022] = "Inmune a físico", -- Hand of Protection
    [29166] = "Maná",         -- Innervate
    [10060] = "+20% celeridad", -- Power Infusion
    [12472] = "Celeridad",    -- Icy Veins
    [12042] = "+20% daño",    -- Arcane Power
    [974] = "Curación",       -- Earth Shield
    [6346] = "Sin miedo",     -- Fear Ward
}
-- Hechizos del jugador que permiten purgar (si no tiene ninguno, no se muestran purgables)
local PURGE_SPELLS = { 370, 527, 30449 }  -- Purge, Dispel Magic, Spellsteal

-- Bebidas (todas se llaman igual en cada idioma, pero hay varias versiones)
local DRINK_SPELLS = { 430, 431, 432, 1133, 1135, 1137, 22734, 27089, 34291, 43182, 43183, 46755, 57073 }

-- Frenados (alerta "Frenado" y condicion de Mano de libertad, Llamada del maestro, Artista del escape)
local SNARE_SPELLS = {
    1715, 116, 3409, 2974, 45524, 12323, 120, 3600, 8056, 58179, 5116, 15407, 31589, 13810,
    -- Hamstring, Frostbolt, Crippling Poison, Wing Clip, Chains of Ice, Piercing Howl, Cone of Cold,
    -- Earthbind, Frost Shock, Infected Wounds, Concussive Shot, Mind Flay, Slow, Frost Trap Aura
}
-- Inmunidades que rompen Lanzamiento destrozador y Disipacion en masa
local SHATTER_SPELLS = { 642, 45438, 1022 }  -- Divine Shield, Ice Block, Hand of Protection

---------------------------------------------------------------------------
-- Consejos: que hacer ahora. Modo simple = icono fijo y titulo corto (para aprenderse el icono);
-- detallado = icono de tu hechizo y la explicacion. class = solo esa clase; classes = solo esas.
---------------------------------------------------------------------------

ns.TIPS = {
    -- Generales
    { key = "defend",        icon = Icon("Ability_Warrior_DefensiveStance"), short = "¡Defiéndete!",
      label = "¡Defiéndete! (poca vida o te enfocan)" },
    { key = "stealth",       icon = Icon("Ability_Stealth"), short = "Se ocultó",
      label = "Un enemigo se oculta (Esfumarse, Sigilo...)" },
    { key = "targetSwitch",  icon = Icon("Ability_TownWatch"), short = "Te apunta",
      label = "Un enemigo te cambia de objetivo" },
    { key = "killWindow",    icon = Icon("INV_Misc_Bone_HumanSkull_01"), short = "¡A por él!",
      label = "Sanador enemigo controlado: a por el de poca vida" },
    { key = "kickImportant", icon = Icon("Ability_Kick"), short = "¡Córtalo!",
      label = "¡Córtalo! solo para curaciones y controles" },
    { key = "purgeHot",      icon = Icon("Spell_Nature_Purge"), short = "Purgar",
      label = "Purgar: resaltar lo más importante",
      classes = { SHAMAN = true, PRIEST = true, MAGE = true, HUNTER = true } },
    -- Guerrero
    { key = "disarm",        class = "WARRIOR", icon = Icon("Ability_Warrior_Disarm"), short = "Desármalo",
      label = "Desármalo (Temeridad, Deseo de muerte...)" },
    { key = "hamstring",     class = "WARRIOR", icon = Icon("Ability_ShockWave"), short = "Frénalo",
      label = "Frénalo (cuerpo a cuerpo y sin frenar)" },
    { key = "msRefresh",     class = "WARRIOR", icon = Icon("Ability_Warrior_SavageBlow"), short = "Golpe mortal",
      label = "Golpe mortal: falta o se acaba" },
    { key = "reflectCC",     class = "WARRIOR", icon = Icon("Ability_Warrior_ShieldReflection"), short = "Refléjalo",
      label = "Refleja el control que te lanzan" },
    { key = "berserkerFear", class = "WARRIOR", icon = Icon("Spell_Nature_AncestralGuardian"), short = "Anti-miedo",
      label = "Ira rabiosa: te lanzan Miedo" },
    -- Mago
    { key = "frozen",        class = "MAGE", icon = Icon("Spell_Frost_FrostBlast"), short = "Congelado",
      label = "Congelado: Ultracongelación o Lanza de hielo" },
    { key = "polyFocus",     class = "MAGE", icon = Icon("Spell_Nature_Polymorph"), short = "Oveja al foco",
      label = "Polimorfia al foco (libre y sin DR)" },
    { key = "nova",          class = "MAGE", icon = Icon("Spell_Frost_FrostNova"), short = "Nova",
      label = "Nova: un enemigo te tiene encima" },
    { key = "barrier",       class = "MAGE", icon = Icon("Spell_Ice_Lament"), short = "Barrera",
      label = "Te falta Barrera de hielo en combate" },
    -- Chaman
    { key = "grounding",     class = "SHAMAN", icon = Icon("Spell_Nature_GroundingTotem"), short = "Derribador",
      label = "Derribador: te lanzan un control o algo fuerte" },
    { key = "tremor",        class = "SHAMAN", icon = Icon("Spell_Nature_TremorTotem"), short = "Temblor",
      label = "Temblor: miedo lanzado o puesto" },
    { key = "totemDown",     class = "SHAMAN", icon = Icon("Spell_Nature_StoneClawTotem"), short = "Recolócalo",
      label = "Tótem destruido: recolócalo" },
    { key = "shield",        class = "SHAMAN", icon = Icon("Ability_Shaman_WaterShield"), short = "Escudo",
      label = "Te falta el escudo (agua o relámpagos)" },
    { key = "nsHeal",        classes = { SHAMAN = true, DRUID = true }, icon = Icon("Spell_Nature_RavenForm"),
      short = "PN + cura", label = "Presteza de la naturaleza + curación", own = true },
    -- Sacerdote
    { key = "psyScream",     class = "PRIEST", icon = Icon("Spell_Shadow_PsychicScream"), short = "Grito",
      label = "Grito psíquico: un enemigo te tiene encima" },
    { key = "shieldAlly",    class = "PRIEST", icon = Icon("Spell_Holy_PowerWordShield"), short = "Escudo",
      label = "Escudo a un aliado con poca vida" },
    { key = "painSup",       class = "PRIEST", icon = Icon("Spell_Holy_PainSupression"), short = "Salvar",
      label = "Supresión de dolor o Espíritu guardián" },
    { key = "fearWard",      class = "PRIEST", icon = Icon("Spell_Holy_Excorcism"), short = "Custodia",
      label = "Custodia de miedo: te lanzan Miedo" },
    { key = "shadowfiend",   class = "PRIEST", icon = Icon("Spell_Shadow_Shadowfiend"), short = "Maná",
      label = "Maligno de las Sombras: te falta maná" },
    -- Picaro
    { key = "cloak",         class = "ROGUE", icon = Icon("Spell_Shadow_NetherCloak"), short = "Capa",
      label = "Capa de las Sombras: te lanzan un control" },
    { key = "kidney",        class = "ROGUE", icon = Icon("Ability_Rogue_KidneyShot"), short = "Riñonazo",
      label = "Golpe en los riñones: 4+ puntos y sin DR" },
    { key = "blindHealer",   class = "ROGUE", icon = Icon("Spell_Shadow_MindSteal"), short = "Ciega",
      label = "Ceguera al sanador (libre y a rango)" },
    { key = "dismantle",     class = "ROGUE", icon = Icon("Ability_Rogue_Dismantle"), short = "Desmantela",
      label = "Desmantelar (Temeridad, Deseo de muerte...)" },
    -- Druida
    { key = "cycloneFocus",  class = "DRUID", icon = Icon("Spell_Nature_EarthBind"), short = "Ciclón al foco",
      label = "Ciclón al foco (libre y sin DR)" },
    { key = "shiftRoot",     class = "DRUID", icon = Icon("Ability_Racial_BearForm"), short = "Cambia forma",
      label = "Cambia de forma: te enraízan o frenan" },
    { key = "innervate",     class = "DRUID", icon = Icon("Spell_Nature_Lightning"), short = "Inervar",
      label = "Inervar: te falta maná" },
    -- Paladin
    { key = "bopAlly",       class = "PALADIN", icon = Icon("Spell_Holy_SealOfProtection"), short = "Protección",
      label = "Mano de protección a un aliado con poca vida" },
    { key = "freedom",       class = "PALADIN", icon = Icon("Spell_Holy_SealOfValor"), short = "Libertad",
      label = "Mano de libertad: enraizado o frenado" },
    { key = "hojKill",       class = "PALADIN", icon = Icon("Spell_Holy_SealOfMight"), short = "Martillo",
      label = "Martillo de justicia: objetivo con poca vida" },
    -- Cazador
    { key = "scatter",       class = "HUNTER", icon = Icon("Ability_GolemStormBolt"), short = "Dispersa",
      label = "Disparo de dispersión: te tienen encima" },
    { key = "aimed",         class = "HUNTER", icon = Icon("INV_Spear_07"), short = "-50% curación",
      label = "Disparo apuntado: falta -50% curación" },
    { key = "wyvernFocus",   class = "HUNTER", icon = Icon("INV_Spear_02"), short = "Picadura al foco",
      label = "Picadura de dracoleón al foco (sin DR)" },
    -- Brujo
    { key = "fearFocus",     class = "WARLOCK", icon = Icon("Spell_Shadow_Possession"), short = "Miedo al foco",
      label = "Miedo al foco (libre y sin DR)" },
    { key = "deathCoil",     class = "WARLOCK", icon = Icon("Spell_Shadow_DeathCoil"), short = "Espiral",
      label = "Espiral de la muerte: te pegan y vas mal" },
    { key = "howl",          class = "WARLOCK", icon = Icon("Spell_Shadow_DeathScream"), short = "Aullido",
      label = "Aullido de terror: te tienen encima" },
    { key = "uaKeep",        class = "WARLOCK", icon = Icon("Spell_Shadow_UnstableAffliction_3"), short = "Aflicción",
      label = "Aflicción inestable: tu objetivo no la tiene" },
    -- Caballero de la Muerte
    { key = "strangulate",   class = "DEATHKNIGHT", icon = Icon("Spell_Shadow_SoulLeech_3"), short = "Estrangula",
      label = "Estrangular al sanador (libre y a rango)" },
    { key = "chains",        class = "DEATHKNIGHT", icon = Icon("Spell_Frost_ChainsOfIce"), short = "Cadenas",
      label = "Cadenas de hielo: se escapa sin frenar" },
    { key = "grip",          class = "DEATHKNIGHT", icon = Icon("Spell_DeathKnight_Strangulate"), short = "Agarre",
      label = "Atracción letal: se aleja" },
    { key = "lichborne",     class = "DEATHKNIGHT", icon = Icon("Spell_Shadow_Raisedead"), short = "Anti-miedo",
      label = "Exánime: te lanzan Miedo o Seducción" },
    { key = "amsCast",       class = "DEATHKNIGHT", icon = Icon("Spell_Shadow_AntiMagicShell"), short = "Caparazón",
      label = "Caparazón antimagia: te lanzan algo fuerte" },
}
local TIP_BY_KEY = {}
for _, t in ipairs(ns.TIPS) do TIP_BY_KEY[t.key] = t end

-- ¿Este consejo es para la clase del personaje?
function ns.TipForClass(t)
    if t.class then return t.class == ns.class end
    if t.classes then return t.classes[ns.class] or false end
    return true
end

local function TipOn(key)
    local db = ns.GetDB()
    return db.features.tips and db.tips[key] and ns.TipForClass(TIP_BY_KEY[key])
end

local TIP_SHOW = { stealth = 6, targetSwitch = 3, totemDown = 4 }  -- segundos que se ven
local DEFEND_PCT = 35  -- vida para ¡Defiéndete! (60 % si te enfocan)

-- Defensivos de todas las clases (el primero listo que conozcas)
local DEFENSIVES = {
    871, 12975, 55694,          -- Shield Wall, Last Stand, Enraged Regeneration
    45438, 11426,               -- Ice Block, Ice Barrier
    30823,                      -- Shamanistic Rage
    642, 498, 33206, 47585,     -- Divine Shield, Divine Protection, Pain Suppression, Dispersion
    31224, 5277, 22812, 61336,  -- Cloak of Shadows, Evasion, Barkskin, Survival Instincts
    19263, 48792, 48707,        -- Deterrence, Icebound Fortitude, Anti-Magic Shell
    20594,                      -- Stoneform
}
-- Ocultarse: Stealth, Vanish (2 rangos), Prowl, Shadowmeld, Invisibility
local STEALTH_SPELLS = { 1784, 1856, 26889, 5215, 58984, 66 }
-- Potenciadores cuerpo a cuerpo que conviene desarmar
local DISARM_BUFF_SPELLS = { 1719, 12292, 31884, 13750, 51690, 49016, 3045 }
-- Beneficios que hay que purgar ya: Power Word: Shield, Hand of Freedom, Innervate, Hand of Protection, Power Infusion
local PURGE_HOT_SPELLS = { 17, 1044, 29166, 1022, 10060 }
-- Congelado (Lanza de hielo y Ultracongelacion hacen mas): Frost Nova, Freeze, Frostbite, Shattered Barrier
local FROZEN_SPELLS = { 122, 33395, 12494, 55080 }
-- Curaciones con tiempo de lanzamiento (para "¡Córtalo! solo curaciones y controles")
local HEAL_SPELLS = { 2061, 2060, 2054, 2050, 47540, 596, 635, 19750, 331, 8004, 1064, 5185, 8936, 50464 }
-- Hechizos fuertes que merece la pena comerse con el Derribador: Pyroblast, Chaos Bolt, Haunt, Unstable Affliction, Vampiric Touch
local BIG_SPELLS = { 11366, 50796, 48181, 30108, 34914 }
-- Totems propios que conviene recolocar: Tremor, Grounding, Cleansing, Earthbind, Mana Tide
local MY_TOTEM_SPELLS = { 8143, 8177, 8170, 2484, 16190 }
-- Clases que pueden ser sanador (aproximado: no se sabe la especializacion)
local HEALER_CLASSES = { PRIEST = true, DRUID = true, SHAMAN = true, PALADIN = true }

local AURAS    -- [nombre localizado] = { kind, label, cat }; se construye al primer uso
local IMMUNES  -- [nombre localizado] = texto
local ENEMY_COOLDOWNS, TOTEMS, PURGEABLE, DRINKS  -- [nombre localizado] = datos
local SNARES, SHATTERABLE  -- [nombre localizado] = true
local NO_DISPEL            -- nombre localizado de Aflicción inestable
-- Consejos: [nombre localizado] = true
local STEALTHS, DISARM_BUFFS, PURGE_HOT, FROZEN, HEALS, BIGS, MY_TOTEMS

local function NameSet(ids)
    local set = {}
    for _, id in ipairs(ids) do
        local name = GetSpellInfo(id)
        if name then set[name] = true end
    end
    return set
end

local function BuildAuraTable()
    STEALTHS, DISARM_BUFFS = NameSet(STEALTH_SPELLS), NameSet(DISARM_BUFF_SPELLS)
    PURGE_HOT, FROZEN, HEALS = NameSet(PURGE_HOT_SPELLS), NameSet(FROZEN_SPELLS), NameSet(HEAL_SPELLS)
    BIGS, MY_TOTEMS = NameSet(BIG_SPELLS), NameSet(MY_TOTEM_SPELLS)
    AURAS, IMMUNES = {}, {}
    SNARES, SHATTERABLE = {}, {}
    for _, id in ipairs(SNARE_SPELLS) do
        local name = GetSpellInfo(id)
        if name then SNARES[name] = true end
    end
    for _, id in ipairs(SHATTER_SPELLS) do
        local name = GetSpellInfo(id)
        if name then SHATTERABLE[name] = true end
    end
    NO_DISPEL = GetSpellInfo(30108)  -- Unstable Affliction: disiparla te silencia
    for id, cat in pairs(CC_SPELLS) do
        local name = GetSpellInfo(id)
        if name then AURAS[name] = { kind = "cc", label = CC_LABELS[cat], cat = cat, effect = cat } end
    end
    for id, effect in pairs(DEBUFF_SPELLS) do
        local name = GetSpellInfo(id)
        if name and not AURAS[name] then
            AURAS[name] = { kind = "debuff", label = name .. " (" .. EFFECTS[effect].label .. ")", effect = effect }
        end
    end
    for id, im in pairs(IMMUNE_SPELLS) do
        local name = GetSpellInfo(id)
        if name then IMMUNES[name] = { effect = im[1], label = im[2] } end
    end
    ENEMY_COOLDOWNS, TOTEMS, PURGEABLE, DRINKS = {}, {}, {}, {}
    for effect, list in pairs(ENEMY_COOLDOWN_SPELLS) do
        for id, cd in pairs(list) do
            local name = GetSpellInfo(id)
            if name then ENEMY_COOLDOWNS[name] = { cd = cd, effect = effect } end
        end
    end
    for id, t in pairs(TOTEM_SPELLS) do
        local name = GetSpellInfo(id)
        if name then TOTEMS[name] = { label = t[1], dur = t[2], short = t[3] } end
    end
    for id, text in pairs(PURGE_BUFFS) do
        local name = GetSpellInfo(id)
        if name then PURGEABLE[name] = name .. " (" .. text .. ")" end
    end
    for _, id in ipairs(DRINK_SPELLS) do
        local name = GetSpellInfo(id)
        if name then DRINKS[name] = true end
    end
end

local function SpellIcon(id) return select(3, GetSpellInfo(id)) end

---------------------------------------------------------------------------
-- Consultas para las condiciones de Core.lua (habilidades que saltan solo cuando hacen falta)
---------------------------------------------------------------------------

local GROUP = { "player", "party1", "party2", "party3", "party4" }

-- cats: { stun = true, ... } o "snare"; nil = cualquier control o perjuicio importante.
-- onlyDispellable: solo los que el jugador puede quitar (y nunca Aflicción inestable).
function ns.UnitHasCC(unit, cats, onlyDispellable)
    if not AURAS then BuildAuraTable() end
    if not UnitExists(unit) or UnitIsDeadOrGhost(unit) then return end
    local filter = onlyDispellable and "HARMFUL|RAID" or "HARMFUL"
    for i = 1, 40 do
        local name = UnitAura(unit, i, filter)
        if not name then return end
        local a = AURAS[name]
        if cats then
            if (a and a.cat and cats[a.cat]) or (SNARES[name] and cats.snare) then return true end
        elseif a and not (onlyDispellable and name == NO_DISPEL) then
            return true
        end
    end
end

function ns.GroupHasCC(cats, onlyDispellable)
    for _, unit in ipairs(GROUP) do
        if ns.UnitHasCC(unit, cats, onlyDispellable) then return true end
    end
end

-- Enemigo con un beneficio que merece la pena purgar/robar
function ns.UnitHasPurgeable(unit)
    if not AURAS then BuildAuraTable() end
    if not UnitExists(unit) or not UnitCanAttack("player", unit) then return end
    for i = 1, 40 do
        local name = UnitBuff(unit, i)
        if not name then return end
        if PURGEABLE[name] then return true end
    end
end

-- Enemigo con Escudo divino, Bloque de hielo o Mano de protección
function ns.UnitIsShatterable(unit)
    if not AURAS then BuildAuraTable() end
    if not UnitExists(unit) or not UnitCanAttack("player", unit) then return end
    for name in pairs(SHATTERABLE) do
        if UnitBuff(unit, name) then return true end
    end
end

---------------------------------------------------------------------------
-- Demostracion: datos inventados
---------------------------------------------------------------------------

-- start = segundo del ciclo en que aparece (sale en el centro y a los 1,5 s pasa al panel)
local DEMO = {
    ally = {
        { name = "Thrall", class = "SHAMAN", spell = 118,   label = "Polimorfia (Medivh)", kind = "cc", effect = "incap", dur = 8, start = 0 },
        { name = "Jaina",  class = "MAGE",   icon = HEALTH_ICON, label = "Vida 22%", kind = "health", effect = "health", start = 1.5 },
        { name = "Thrall", class = "SHAMAN", spell = 12294, label = "Golpe mortal (-50% curación)", kind = "debuff", effect = "healcut", dur = 10, start = 3 },
        { name = "Thrall", class = "SHAMAN", spell = 116,   label = "Frenado (Descarga de escarcha)", kind = "snare", effect = "snare", dur = 6, start = 4.5 },
        { name = "Jaina",  class = "MAGE",   icon = FOCUS_ICON, label = "Lo enfocan 2 enemigos", kind = "focus", effect = "focus", start = 6 },
    },
    enemy = {
        { name = "Uther",  class = "PALADIN", spell = 46968, label = "Aturdido (Thrall)", kind = "cc", effect = "stun", dur = 4, dr = "DR ½", start = 0.7 },
        { name = "Medivh", class = "MAGE",    spell = 118,   label = "Lanzando Polimorfia", kind = "cast", effect = "castcc", sIcon = EFFECTS.incap.icon, dur = 1.5, start = 2.2 },
        { name = "Uther",  class = "PALADIN", spell = 642,   label = "INMUNE", kind = "immune", effect = "immune", dur = 12, start = 3.7 },
        { name = "Medivh", class = "MAGE",    spell = 42292, label = "Sin abalorio", kind = "trinket", effect = "trinket", dur = 120, start = 5.2 },
        { name = "Uther",  class = "PALADIN", spell = 1044,  label = "Mano de libertad usado", kind = "ecd", effect = "nodef", dur = 25, start = 6.7 },
        { name = "Medivh", class = "MAGE",    icon = HEALTH_ICON, label = "Vida 18%", kind = "health", effect = "health", start = 8.2 },
    },
}

-- Consejos de la demostracion: los generales y los de la clase del personaje.
-- me = tu fila ("Tú", con tu cara); spell = icono del modo detallado (si no, el del consejo).
local DEMO_TIPS = {
    ALL = {
        { tip = "defend",       side = "ally",  me = true, spell = 45438, label = "Usa Bloque de hielo", start = 9 },
        { tip = "stealth",      side = "enemy", name = "Valeera", class = "ROGUE", spell = 1856, label = "Esfumarse: se ocultó", start = 9.6 },
        { tip = "targetSwitch", side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Te ha cambiado de objetivo", start = 10.2 },
        { tip = "killWindow",   side = "enemy", name = "Medivh", class = "MAGE", label = "Uther controlado: ¡a por él!", start = 10.8 },
    },
    WARRIOR = {
        { tip = "disarm",        side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Desarmar: tiene Temeridad", start = 11.4 },
        { tip = "hamstring",     side = "enemy", name = "Valeera", class = "ROGUE", label = "Seccionar: no va frenado", start = 12 },
        { tip = "reflectCC",     side = "enemy", name = "Medivh", class = "MAGE", label = "Reflejo de hechizos: te lanza Polimorfia", start = 12.6 },
        { tip = "berserkerFear", side = "enemy", name = "Gul'dan", class = "WARLOCK", label = "Ira rabiosa: te lanza Miedo", start = 13.2 },
        { tip = "msRefresh",     side = "enemy", name = "Uther", class = "PALADIN", label = "Golpe mortal: se acaba", start = 13.8 },
    },
    MAGE = {
        { tip = "frozen",    side = "enemy", name = "Garrosh", class = "WARRIOR", spell = 44572, label = "Ultracongelación: está congelado", start = 11.4 },
        { tip = "nova",      side = "enemy", name = "Valeera", class = "ROGUE", label = "Nova de escarcha: te tiene encima", start = 12 },
        { tip = "polyFocus", side = "enemy", name = "Uther", class = "PALADIN", label = "Polimorfia a tu foco", start = 12.6 },
        { tip = "barrier",   side = "ally",  me = true, label = "Barrera de hielo: no la tienes puesta", start = 13.2 },
        { tip = "purgeHot",  side = "enemy", name = "Uther", class = "PALADIN", spell = 1044, label = "Robar: Mano de libertad", start = 13.8 },
    },
    SHAMAN = {
        { tip = "grounding", side = "enemy", name = "Medivh", class = "MAGE", label = "Tótem derribador: te lanza Polimorfia", start = 11.4 },
        { tip = "tremor",    side = "ally",  me = true, label = "Tótem de temblor: hay miedo en tu grupo", start = 12 },
        { tip = "totemDown", side = "ally",  me = true, spell = 8177, sIcon = true, label = "Tótem derribador destruido: recolócalo", start = 12.6 },
        { tip = "shield",    side = "ally",  me = true, spell = 52127, label = "Te falta Escudo de agua o de relámpagos", start = 13.2 },
        { tip = "nsHeal",    side = "ally",  name = "Jaina", class = "MAGE", label = "Presteza de la naturaleza + curación", start = 13.8 },
    },
    PRIEST = {
        { tip = "psyScream",   side = "enemy", name = "Valeera", class = "ROGUE", label = "Grito psíquico: te tiene encima", start = 11.4 },
        { tip = "shieldAlly",  side = "ally",  name = "Jaina", class = "MAGE", label = "Palabra de poder: escudo", start = 12 },
        { tip = "painSup",     side = "ally",  name = "Thrall", class = "SHAMAN", spell = 33206, label = "Supresión de dolor: está a punto de morir", start = 12.6 },
        { tip = "fearWard",    side = "enemy", name = "Gul'dan", class = "WARLOCK", label = "Custodia de miedo: te lanza Miedo", start = 13.2 },
        { tip = "shadowfiend", side = "ally",  me = true, label = "Maligno de las Sombras: te falta maná", start = 13.8 },
        { tip = "purgeHot",    side = "enemy", name = "Uther", class = "PALADIN", spell = 1044, label = "Disipar: Mano de libertad", start = 14.4 },
    },
    ROGUE = {
        { tip = "cloak",       side = "enemy", name = "Medivh", class = "MAGE", label = "Capa de las Sombras: te lanza Polimorfia", start = 11.4 },
        { tip = "kidney",      side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Golpe en los riñones: tienes puntos y no tiene DR", start = 12 },
        { tip = "blindHealer", side = "enemy", name = "Uther", class = "PALADIN", label = "Ceguera al sanador", start = 12.6 },
        { tip = "dismantle",   side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Desmantelar: tiene Temeridad", start = 13.2 },
    },
    DRUID = {
        { tip = "cycloneFocus", side = "enemy", name = "Uther", class = "PALADIN", label = "Ciclón a tu foco", start = 11.4 },
        { tip = "shiftRoot",    side = "ally",  me = true, label = "Cambia de forma: quita raíces y frenados", start = 12 },
        { tip = "innervate",    side = "ally",  me = true, label = "Inervar: te falta maná", start = 12.6 },
        { tip = "nsHeal",       side = "ally",  name = "Jaina", class = "MAGE", spell = 17116, label = "Presteza de la naturaleza + curación", start = 13.2 },
    },
    PALADIN = {
        { tip = "bopAlly", side = "ally",  name = "Jaina", class = "MAGE", label = "Mano de protección: le pegan y va mal", start = 11.4 },
        { tip = "freedom", side = "ally",  name = "Thrall", class = "SHAMAN", label = "Mano de libertad: va enraizado o frenado", start = 12 },
        { tip = "hojKill", side = "enemy", name = "Medivh", class = "MAGE", label = "Martillo de justicia: que no se escape", start = 12.6 },
    },
    HUNTER = {
        { tip = "scatter",     side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Disparo de dispersión: te tiene encima", start = 11.4 },
        { tip = "aimed",       side = "enemy", name = "Uther", class = "PALADIN", label = "Disparo apuntado: no tiene -50% curación", start = 12 },
        { tip = "wyvernFocus", side = "enemy", name = "Medivh", class = "MAGE", label = "Picadura de dracoleón a tu foco", start = 12.6 },
        { tip = "purgeHot",    side = "enemy", name = "Uther", class = "PALADIN", spell = 1044, label = "Disparo tranquilizante: Mano de libertad", start = 13.2 },
    },
    WARLOCK = {
        { tip = "fearFocus", side = "enemy", name = "Uther", class = "PALADIN", label = "Miedo a tu foco", start = 11.4 },
        { tip = "deathCoil", side = "enemy", name = "Garrosh", class = "WARRIOR", label = "Espiral de la muerte: te pega y vas mal", start = 12 },
        { tip = "howl",      side = "enemy", name = "Valeera", class = "ROGUE", label = "Aullido de terror: te tiene encima", start = 12.6 },
        { tip = "uaKeep",    side = "enemy", name = "Medivh", class = "MAGE", label = "Aflicción inestable: no la tiene", start = 13.2 },
    },
    DEATHKNIGHT = {
        { tip = "strangulate", side = "enemy", name = "Uther", class = "PALADIN", label = "Estrangular al sanador", start = 11.4 },
        { tip = "chains",      side = "enemy", name = "Valeera", class = "ROGUE", label = "Cadenas de hielo: se escapa", start = 12 },
        { tip = "grip",        side = "enemy", name = "Medivh", class = "MAGE", label = "Atracción letal: se aleja", start = 12.6 },
        { tip = "lichborne",   side = "enemy", name = "Gul'dan", class = "WARLOCK", label = "Exánime: te lanza Miedo", start = 13.2 },
        { tip = "amsCast",     side = "enemy", name = "Medivh", class = "MAGE", label = "Caparazón antimagia: te lanza Piroexplosión", start = 13.8 },
    },
}

---------------------------------------------------------------------------
-- Dibujo: un bloque por jugador. Cara (con marco verde aliado / rojo enemigo) y a su lado
-- (o debajo, en vertical) sus alertas: icono con borde del color del tipo, barra y texto.
---------------------------------------------------------------------------

local NAME_H = 14   -- alto del nombre encima de la cara
local GAP = 4
local BAR_H = 4
local LABEL_H = 24  -- texto de dos lineas debajo de cada alerta
local BLOCK_GAP = 10

local container
local rows, panels = {}, {}
local demoOn, demoStart, demoUntil = false, 0, nil

local function AlertSize() return ns.GetDB().alertSize end
local function CenterLabelWidth(size) return math.max(size + 24, 90) end
local function PanelLabelWidth(size) return math.max(size + 16, 60) end

local function SetClassEmblem(tex, class)
    local coords = class and CLASS_ICON_TCOORDS[class]
    if coords then
        tex:SetTexture(CLASS_EMBLEMS)
        tex:SetTexCoord(unpack(coords))
    else  -- clase desconocida
        tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
end

-- Icono, texto y gris segun el modo: simple = el efecto, detallado = el hechizo concreto
local function Look(a, simple)
    local e = a.effect and EFFECTS[a.effect]
    local gray = e and e.gray
    if simple then
        return a.sIcon or (e and e.icon) or a.icon or SpellIcon(a.spell),
               a.sLabel or (e and e.label) or a.label, gray
    end
    return a.icon or SpellIcon(a.spell), a.label, gray
end

-- Ancho y alto de un bloque con n alertas. labelW = nil: sin texto debajo de cada alerta.
local function BlockSize(n, size, dir, labelW)
    local colW = labelW and math.max(labelW, size) or size
    local slotH = size + BAR_H + 2 + (labelW and LABEL_H or 0)
    if dir == "V" then
        return colW, NAME_H + size + GAP * 2 + n * (slotH + GAP)
    end
    return size + GAP * 2 + n * (colW + GAP), NAME_H + math.max(size, slotH)
end

local function CreateSlot(parent)
    local s = CreateFrame("Frame", nil, parent)
    s.border = s:CreateTexture(nil, "BACKGROUND")
    s.border:SetAllPoints()
    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.icon:SetPoint("TOPLEFT", 2, -2)
    s.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    s.dr = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.dr:SetPoint("TOPRIGHT", 4, 6)

    -- Barra que se vacia con la duracion (sin numeros)
    s.bar = CreateFrame("StatusBar", nil, s)
    s.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    s.bar:SetHeight(BAR_H)
    s.bar:SetMinMaxValues(0, 1)
    s.bar:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -1)
    s.bar:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, -1)

    s.label = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.label:SetPoint("TOP", s, "BOTTOM", 0, -BAR_H - 2)
    s.label:SetJustifyV("TOP")
    return s
end

local function CreateBlock(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.name = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.name:SetJustifyH("LEFT")
    b.side = b:CreateTexture(nil, "BACKGROUND")
    b.portrait = b:CreateTexture(nil, "ARTWORK")
    -- Emblema pequeno de la clase en la esquina de la cara (solo si se ve la cara)
    b.badge = b:CreateTexture(nil, "OVERLAY")
    b.slots = {}
    return b
end

-- Dibuja el bloque de un jugador; devuelve su ancho y alto
local function DrawBlock(b, g, size, dir, labelW, sideKey, simple, t)
    local side = SIDE_COLORS[sideKey]
    local n = math.min(#g.items, MAX_PER_PLAYER)
    local w, h = BlockSize(n, size, dir, labelW)
    b:SetWidth(w); b:SetHeight(h)
    local colW = labelW and math.max(labelW, size) or size
    local slotH = size + BAR_H + 2 + (labelW and LABEL_H or 0)

    local color = RAID_CLASS_COLORS[g.class] or NORMAL_FONT_COLOR
    b.name:SetText(g.name)
    b.name:SetTextColor(color.r, color.g, color.b)
    b.name:ClearAllPoints()
    b.name:SetPoint("TOPLEFT", 0, 0)
    b.name:SetWidth(dir == "V" and w or math.max(w, 120))
    b.name:SetHeight(NAME_H)

    local px = dir == "V" and (w - size) / 2 or 0
    b.portrait:SetWidth(size); b.portrait:SetHeight(size)
    b.portrait:ClearAllPoints()
    b.portrait:SetPoint("TOPLEFT", px, -NAME_H - 2)
    b.side:ClearAllPoints()
    b.side:SetPoint("TOPLEFT", b.portrait, "TOPLEFT", -2, 2)
    b.side:SetPoint("BOTTOMRIGHT", b.portrait, "BOTTOMRIGHT", 2, -2)
    b.side:SetTexture(side[1], side[2], side[3], 1)

    -- Cara real si el juego conoce al jugador; si no, una cara de tu facción (aliado) o de la contraria (enemigo).
    -- El emblema de la clase va en la esquina.
    if g.unit and UnitExists(g.unit) then
        b.portrait:SetTexCoord(0, 1, 0, 1)
        SetPortraitTexture(b.portrait, g.unit)
    else
        b.portrait:SetTexture(SideIcon(sideKey))
        b.portrait:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    if g.class then
        local badge = math.max(12, size * 0.35)
        b.badge:SetWidth(badge); b.badge:SetHeight(badge)
        b.badge:ClearAllPoints()
        b.badge:SetPoint("BOTTOMRIGHT", b.portrait, "BOTTOMRIGHT", 2, -2)
        SetClassEmblem(b.badge, g.class)
        b.badge:Show()
    else
        b.badge:Hide()
    end

    for i = 1, n do
        local a = g.items[i]
        local s = b.slots[i] or CreateSlot(b)
        b.slots[i] = s
        s:SetWidth(size); s:SetHeight(size)
        s:ClearAllPoints()
        if dir == "V" then
            s:SetPoint("TOPLEFT", (w - size) / 2, -(NAME_H + size + GAP * 2 + (i - 1) * (slotH + GAP)))
        else
            s:SetPoint("TOPLEFT", size + GAP * 2 + (i - 1) * (colW + GAP) + (colW - size) / 2, -NAME_H - 2)
        end

        local icon, label, gray = Look(a, simple)
        s.icon:SetTexture(icon)
        s.icon:SetDesaturated(gray and true or false)
        local bc = BORDER_COLORS[a.kind]
        s.border:SetTexture(bc[1], bc[2], bc[3], 1)
        s.dr:SetText(a.dr or "")
        if labelW then
            s.label:SetWidth(colW); s.label:SetHeight(LABEL_H)
            s.label:SetText(label)
            s.label:Show()
        else
            s.label:Hide()
        end
        if a.value then
            s.bar:SetValue(a.value)
            s.bar:SetStatusBarColor(bc[1], bc[2], bc[3])
            s.bar:Show()
        else
            s.bar:Hide()
        end
        -- la vida baja, ¡cortalo!, los consejos y lo que hay que purgar ya laten
        if a.kind == "health" or a.kind == "kick" or a.kind == "tip" or a.hot then
            s:SetAlpha(0.6 + 0.4 * math.abs(math.sin(t * 4)))
        else
            s:SetAlpha(1)
        end
        s:Show()
    end
    for i = n + 1, #b.slots do b.slots[i]:Hide() end
    b:Show()
    return w, h
end

-- Orden estable: tipo de alerta, luego jugador y alerta (para que no bailen los iconos)
local function ByKind(a, b)
    local ka, kb = KIND_ORDER[a.kind], KIND_ORDER[b.kind]
    if ka ~= kb then return ka < kb end
    local pa, pb = tostring(a.pkey or a.name), tostring(b.pkey or b.name)
    if pa ~= pb then return pa < pb end
    return tostring(a.key or a.label) < tostring(b.key or b.label)
end

-- Agrupa las alertas por jugador; en modo simple cada efecto sale una sola vez por jugador
local function GroupByPlayer(list, simple)
    table.sort(list, ByKind)
    local groups, index = {}, {}
    for _, a in ipairs(list) do
        local k = a.pkey or a.name
        local g = index[k]
        if not g then
            g = { name = a.name, class = a.class, unit = a.unit, items = {}, effects = {} }
            index[k] = g
            groups[#groups + 1] = g
        end
        if not g.unit and a.unit then g.unit = a.unit end
        local dup = simple and a.effect and (a.kind .. a.effect)
        if not (dup and g.effects[dup]) then
            if dup then g.effects[dup] = true end
            g.items[#g.items + 1] = a
        end
    end
    return groups
end

local function CreateRow(key, title, r, g, b)
    local row = CreateFrame("Frame", nil, container)
    row:SetWidth(1); row:SetHeight(1)
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetTextColor(r, g, b)
    row.title:SetText(title)
    row.sideKey = key
    row.blocks = {}
    rows[key] = row
end

-- Panel lateral (uno de aliados y otro de enemigos): se mueve con "Mover barras"
local PANEL_TITLES = { ally = "Aliados", enemy = "Enemigos" }

local function CreatePanel(key)
    local p = CreateFrame("Frame", "PvPKitPanel_" .. key, UIParent)
    p:SetMovable(true)
    p:SetClampedToScreen(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local cfg = ns.GetDB().panels[key]
        cfg.point, cfg.relPoint, cfg.x, cfg.y = point, relPoint, x, y
    end)
    p.bg = p:CreateTexture(nil, "BACKGROUND")
    p.bg:SetAllPoints()
    p.bg:SetTexture(0.78, 0.61, 0.43, 0.25)
    p.header = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    p.header:SetPoint("BOTTOMLEFT", p, "TOPLEFT", 0, 2)
    local c = SIDE_COLORS[key]
    p.header:SetTextColor(c[1], c[2], c[3])
    p.key = key
    p.blocks = {}
    panels[key] = p
end

local function DrawRow(row, groups, size, simple, t)
    local labelW = CenterLabelWidth(size)
    local n = math.min(#groups, MAX_CENTER)
    local widths, total = {}, 0
    for i = 1, n do
        widths[i] = BlockSize(math.min(#groups[i].items, MAX_PER_PLAYER), size, "H", labelW)
        total = total + widths[i] + (i > 1 and BLOCK_GAP or 0)
    end
    row.title:ClearAllPoints()
    row.title:SetPoint("RIGHT", row, "LEFT", -total / 2 - 10, -NAME_H - size / 2)
    if n > 0 then row.title:Show() else row.title:Hide() end

    local x = -total / 2
    for i = 1, n do
        local b = row.blocks[i] or CreateBlock(row)
        row.blocks[i] = b
        DrawBlock(b, groups[i], size, "H", labelW, row.sideKey, simple, t)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0)
        x = x + widths[i] + BLOCK_GAP
    end
    for i = n + 1, #row.blocks do row.blocks[i]:Hide() end
end

-- Horizontal: un jugador por fila (alertas a la derecha). Vertical: un jugador por columna.
local function DrawPanel(p, groups, simple, t)
    local cfg = ns.GetDB().panels[p.key]
    local labelW = simple and PanelLabelWidth(cfg.size) or nil
    local n = math.min(#groups, MAX_PANEL)
    local off = 0
    for i = 1, n do
        local b = p.blocks[i] or CreateBlock(p)
        p.blocks[i] = b
        local w, h = DrawBlock(b, groups[i], cfg.size, cfg.dir, labelW, p.key, simple, t)
        b:ClearAllPoints()
        if cfg.dir == "V" then
            b:SetPoint("TOPLEFT", p, "TOPLEFT", off, 0)
            off = off + w + BLOCK_GAP
        else
            b:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -off)
            off = off + h + BLOCK_GAP
        end
    end
    for i = n + 1, #p.blocks do p.blocks[i]:Hide() end
    if n > 0 or not ns.GetDB().locked then p.header:Show() else p.header:Hide() end
end

local function Build()
    container = CreateFrame("Frame", "PvPKitAlerts", UIParent)
    container:SetWidth(700); container:SetHeight(300)
    container:SetPoint("CENTER", 0, 170)

    -- Se arrastra con "Mover barras", igual que las barras
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    container:RegisterForDrag("LeftButton")
    container:SetScript("OnDragStart", container.StartMoving)
    container:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        local pos = ns.GetDB().alertPos
        pos.point, pos.relPoint, pos.x, pos.y = point, relPoint, x, y
    end)
    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints()
    container.bg:SetTexture(0.78, 0.61, 0.43, 0.25)
    container.label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    container.label:SetPoint("BOTTOM", container, "TOP", 0, 2)
    container.label:SetText("PvP Kit - Alertas (arrastra para mover)")

    CreateRow("ally", "Aliados", 0.3, 1, 0.3)
    CreateRow("enemy", "Enemigos", 1, 0.3, 0.3)
    CreatePanel("ally")
    CreatePanel("enemy")
end

local function CenterRowHeight(size)
    local _, h = BlockSize(1, size, "H", CenterLabelWidth(size))
    return h
end

local function PlaceRows(size)
    rows.ally:ClearAllPoints()
    rows.ally:SetPoint("TOP", container, "TOP", 0, -50)
    rows.enemy:ClearAllPoints()
    rows.enemy:SetPoint("TOP", container, "TOP", 0, -50 - CenterRowHeight(size) - 12)
end

---------------------------------------------------------------------------
-- Aliados reales
---------------------------------------------------------------------------

local function GroupUnits()
    local units = {}
    local raid = GetNumRaidMembers()
    if raid > 0 then
        for i = 1, raid do units[#units + 1] = "raid" .. i end
    else
        for i = 1, GetNumPartyMembers() do units[#units + 1] = "party" .. i end
    end
    return units
end

local seen = {}  -- alertas ya registradas en el log, para anotar solo las nuevas

local function ScanAllies()
    if not AURAS then BuildAuraTable() end
    local cfg = ns.GetDB().alerts.ally
    local now = GetTime()
    local list, current = {}, {}

    for _, unit in ipairs(GroupUnits()) do
        if UnitExists(unit) and not UnitIsUnit(unit, "player") and not UnitIsDeadOrGhost(unit) then
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            local guid = UnitGUID(unit)

            if cfg.cc or cfg.debuff or cfg.snare then
                for i = 1, 40 do
                    local aura, _, icon, _, _, duration, expires, caster = UnitDebuff(unit, i)
                    if not aura then break end
                    local info = AURAS[aura]
                    local value
                    if duration and duration > 0 and expires then value = (expires - now) / duration end
                    if info and cfg[info.kind] then
                        local label = info.label
                        local casterName = caster and UnitName(caster)
                        if info.kind == "cc" and casterName then label = label .. " (" .. casterName .. ")" end
                        list[#list + 1] = { name = name, class = class, unit = unit, pkey = guid, key = aura,
                                            icon = icon, label = label, kind = info.kind, effect = info.effect,
                                            value = value }
                        current[unit .. aura] = name .. ": " .. aura
                    elseif not info and cfg.snare and SNARES[aura] then
                        list[#list + 1] = { name = name, class = class, unit = unit, pkey = guid, key = aura,
                                            icon = icon, label = "Frenado (" .. aura .. ")", kind = "snare",
                                            effect = "snare", value = value }
                    end
                end
            end

            if cfg.health then
                local pct = math.floor(UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100)
                if pct <= cfg.healthPct then
                    list[#list + 1] = { name = name, class = class, unit = unit, pkey = guid, key = "health",
                                        icon = HEALTH_ICON, label = "Vida " .. pct .. "%", kind = "health",
                                        effect = "health", sLabel = "Vida " .. pct .. "%" }
                    current[unit .. "health"] = name .. ": vida baja"
                end
            end
        end
    end

    for key, text in pairs(current) do
        if not seen[key] then ns.Log("alerta aliado: " .. text) end
    end
    seen = current
    return list  -- se ordena y recorta en OnUpdate, tras anadir tu DR y "lo enfocan"
end

---------------------------------------------------------------------------
-- Enemigos reales (registro de combate)
-- Controles y DR: solo los que pone tu grupo (para encadenar con el equipo).
-- Inmunidades y abalorio: solo de enemigos identificables (objetivo, foco, arena1-5).
---------------------------------------------------------------------------

local band = bit.band
local HOSTILE_PLAYER = COMBATLOG_OBJECT_REACTION_HOSTILE + COMBATLOG_OBJECT_TYPE_PLAYER
local FROM_GROUP = COMBATLOG_OBJECT_AFFILIATION_MINE + COMBATLOG_OBJECT_AFFILIATION_PARTY
    + COMBATLOG_OBJECT_AFFILIATION_RAID
local CC_FALLBACK = 12      -- si no llega el fin del control (fuera de rango), se borra a los N s
local IMMUNE_FALLBACK = 15

local enemies = {}  -- [guid] = { name, class, cc = {}, immune = {}, dr = {}, cds = {}, trinketAt }
local totems = {}   -- [guid del totem] = { owner, class, label, icon, dur, expires }
local selfDR = {}   -- [categoria] = { count, resetAt, icon, active }: controles que recibes tu
local stealthed = {}   -- [guid] = { name, class, spell, icon, at }: enemigos que se acaban de ocultar
local myTotems = {}    -- [guid del totem] = { spell, icon }: tus totems importantes
local totemsDown = {}  -- [guid del totem] = { spell, icon, at }: tus totems que han matado

local function IsHostilePlayer(flags) return band(flags, HOSTILE_PLAYER) == HOSTILE_PLAYER end

local function ClassOfGUID(guid)
    return GetPlayerInfoByGUID and select(2, GetPlayerInfoByGUID(guid))
end

local function Enemy(guid, name)
    local e = enemies[guid]
    if not e then
        e = { name = name, class = ClassOfGUID(guid), cc = {}, immune = {}, dr = {}, cds = {} }
        enemies[guid] = e
    end
    return e
end

-- Suma un control a un estado de DR (se reinicia DR_RESET s despues de acabar el ultimo)
local function AddDR(drTable, cat, icon, now)
    local dr = drTable[cat]
    if not dr or (dr.resetAt and now > dr.resetAt) then dr = { count = 0 } end
    dr.count = dr.count + 1
    dr.resetAt = nil
    dr.icon = icon
    dr.at = now
    drTable[cat] = dr
    return dr
end

local ENEMY_UNITS = { "target", "focus", "arena1", "arena2", "arena3", "arena4", "arena5" }
local function UnitForGUID(guid)
    for _, unit in ipairs(ENEMY_UNITS) do
        if UnitGUID(unit) == guid then return unit end
    end
end

local function OnCombatLog(...)
    local _, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName = ...
    if not AURAS then BuildAuraTable() end
    local now = GetTime()

    if event == "SPELL_CAST_SUCCESS" then
        if srcFlags and IsHostilePlayer(srcFlags) then
            if STEALTHS[spellName] then
                stealthed[srcGUID] = { name = srcName, class = ClassOfGUID(srcGUID), spell = spellName,
                                       icon = select(3, GetSpellInfo(spellId)), at = now }
                ns.Log("enemigo " .. tostring(srcName) .. ": se oculta (" .. spellName .. ")")
            end
            if TRINKETS[spellId] then
                Enemy(srcGUID, srcName).trinketAt = now
                ns.Log("enemigo " .. tostring(srcName) .. ": abalorio usado")
            elseif ENEMY_COOLDOWNS[spellName] then
                local c = ENEMY_COOLDOWNS[spellName]
                Enemy(srcGUID, srcName).cds[spellName] =
                    { usedAt = now, cd = c.cd, effect = c.effect, icon = select(3, GetSpellInfo(spellId)) }
            end
        end
        return
    end

    -- Totems enemigos: aparecen al invocarlos y se quitan al morir
    if event == "SPELL_SUMMON" then
        if srcGUID == UnitGUID("player") and MY_TOTEMS[spellName] then
            myTotems[dstGUID] = { spell = spellName, icon = select(3, GetSpellInfo(spellId)) }
            return
        end
        local t = TOTEMS[spellName]
        if t and srcFlags and IsHostilePlayer(srcFlags) then
            totems[dstGUID] = { owner = srcName, ownerGUID = srcGUID, class = ClassOfGUID(srcGUID) or "SHAMAN",
                                label = t.label, short = t.short, icon = select(3, GetSpellInfo(spellId)),
                                dur = t.dur, expires = now + t.dur }
            ns.Log("tótem enemigo: " .. spellName)
        end
        return
    end
    if event == "UNIT_DIED" or event == "UNIT_DESTROYED" then
        totems[dstGUID] = nil
        local mine = myTotems[dstGUID]
        if mine then
            myTotems[dstGUID] = nil
            -- solo si lo matan (UNIT_DIED); si se acaba solo no hace falta avisar
            if event == "UNIT_DIED" then
                mine.at = now
                totemsDown[dstGUID] = mine
                ns.Log("tótem destruido: " .. mine.spell)
            end
        end
        return
    end

    -- Tu propio DR: controles que te ponen a ti
    if dstGUID == UnitGUID("player") then
        local info = AURAS[spellName]
        if info and info.kind == "cc" then
            if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
                local dr = AddDR(selfDR, info.cat, select(3, GetSpellInfo(spellId)), now)
                dr.active = true
            elseif event == "SPELL_AURA_REMOVED" and selfDR[info.cat] then
                selfDR[info.cat].active = nil
                selfDR[info.cat].resetAt = now + DR_RESET
            end
        end
        return
    end

    if not dstFlags or not IsHostilePlayer(dstFlags) then return end

    if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" then
        local info = AURAS[spellName]
        if info and info.kind == "cc" and band(srcFlags, FROM_GROUP) > 0 then
            local e = Enemy(dstGUID, dstName)
            local dr = AddDR(e.dr, info.cat, select(3, GetSpellInfo(spellId)), now)
            e.cc[spellName] = { cat = info.cat, label = info.label, icon = dr.icon, applied = now, caster = srcName }
            ns.Log("enemigo " .. tostring(dstName) .. ": " .. info.label .. " (" .. tostring(srcName) .. "), DR " .. dr.count)
        elseif IMMUNES[spellName] then
            local im = IMMUNES[spellName]
            Enemy(dstGUID, dstName).immune[spellName] =
                { label = im.label, effect = im.effect, icon = select(3, GetSpellInfo(spellId)), applied = now }
            ns.Log("enemigo " .. tostring(dstName) .. ": " .. spellName)
        end
    elseif event == "SPELL_AURA_REMOVED" then
        local e = enemies[dstGUID]
        if not e then return end
        local c = e.cc[spellName]
        if c then
            e.cc[spellName] = nil
            if e.dr[c.cat] then e.dr[c.cat].resetAt = now + DR_RESET end
        end
        e.immune[spellName] = nil
    end
end

-- Primer corte del jugador que este listo y a rango de esa unidad (habilidades con kick = true
-- o cond = "interrupt": Golpe con escudo, Zurrar, Corte de viento, Contrahechizo...)
local function ReadyInterrupt(unit, now)
    for _, s in ipairs(ns.GetKnown()) do
        if s.kick or s.cond == "interrupt" then
            local usable = IsUsableSpell(s.name)
            local start, duration = GetSpellCooldown(s.name)
            local offCooldown = start and (duration <= 1.5 or start + duration <= now)
            if usable and offCooldown and IsSpellInRange(s.name, unit) == 1 then return s end
        end
    end
end

local kicksSeen = {}  -- para anotar en el registro solo los nuevos

-- Lanzamientos de objetivo, foco y arena (tambien PNJ, util para probar en el mundo)
local function ScanCasts(list, cfg, now)
    if not (cfg.casts or cfg.kick) then return end
    local done, current = {}, {}
    for _, unit in ipairs(ENEMY_UNITS) do
        local guid = UnitGUID(unit)
        if guid and not done[guid] and UnitCanAttack("player", unit) then
            done[guid] = true
            local spell, _, _, icon, startMs, endMs, _, _, notInterruptible = UnitCastingInfo(unit)
            if not spell then
                spell, _, _, icon, startMs, endMs, _, notInterruptible = UnitChannelInfo(unit)
            end
            if spell then
                local total = (endMs - startMs) / 1000
                local value = total > 0 and (endMs / 1000 - now) / total or nil
                local _, class = UnitClass(unit)
                local base = { name = UnitName(unit), class = class, unit = unit, pkey = guid, icon = icon,
                               value = value }
                -- con "¡Córtalo! solo para lo importante": curaciones y controles
                local cc = AURAS[spell]
                local important = not TipOn("kickImportant") or HEALS[spell] or (cc and cc.kind == "cc")
                local kick = important and not notInterruptible and cfg.kick and ReadyInterrupt(unit, now)
                if kick then
                    base.kind, base.key, base.effect = "kick", "kick", "kick"
                    base.label = "¡CÓRTALO! " .. spell .. " (" .. kick.name .. ")"
                    base.sLabel = "¡Córtalo! (" .. kick.name .. ")"
                    local key = guid .. spell
                    current[key] = true
                    if not kicksSeen[key] then ns.Log("córtalo: " .. tostring(base.name) .. " - " .. spell) end
                    list[#list + 1] = base
                elseif cfg.casts then
                    base.kind, base.key, base.effect = "cast", "cast", "cast"
                    base.label = notInterruptible and (spell .. " (no se puede cortar)") or ("Lanzando " .. spell)
                    -- si lo que lanza es un control (Polimorfia, Miedo, Maleficio...), icono de ese control
                    local info = AURAS[spell]
                    if info and info.kind == "cc" then
                        base.effect, base.sIcon = "castcc", EFFECTS[info.cat].icon
                    end
                    list[#list + 1] = base
                end
            end
        end
    end
    kicksSeen = current
end

-- Libro de hechizos del jugador (se vuelve a leer al aprender hechizos o cambiar talentos)
-- y si puede purgar (Purgar, Disipar magia o Robar hechizo)
local book, canPurge
local function UpdateBook()
    book = {}
    local i = 1
    while true do
        local name = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        book[name] = true
        i = i + 1
    end
    canPurge = false
    for _, id in ipairs(PURGE_SPELLS) do
        local name = GetSpellInfo(id)
        if name and book[name] then canPurge = true end
    end
end

-- Nombre del hechizo si el jugador lo conoce
local function Known(id)
    if not book then UpdateBook() end
    local name = GetSpellInfo(id)
    return name and book[name] and name
end

-- Nombre del hechizo si lo conoce y no esta en cooldown (el GCD se ignora)
local function Ready(id, now)
    local name = Known(id)
    if not name then return end
    local start, duration = GetSpellCooldown(name)
    if start and (duration <= 1.5 or start + duration <= now) then return name end
end

-- Enemigos jugadores identificables (objetivo, foco, arena), sin repetir
local function EnemyPlayerUnits()
    local units, done = {}, {}
    for _, unit in ipairs(ENEMY_UNITS) do
        local guid = UnitGUID(unit)
        if guid and not done[guid] and UnitIsPlayer(unit) and UnitCanAttack("player", unit)
            and not UnitIsDeadOrGhost(unit) then
            done[guid] = true
            units[#units + 1] = unit
        end
    end
    return units
end

-- Vida baja, perjuicios importantes, frenados, purgables y bebiendo
local function ScanEnemyUnits(list, cfg, now)
    if not book then UpdateBook() end
    for _, unit in ipairs(EnemyPlayerUnits()) do
        local _, class = UnitClass(unit)
        local guid = UnitGUID(unit)
        local function Add(fields)
            fields.name, fields.class, fields.unit, fields.pkey = UnitName(unit), class, unit, guid
            list[#list + 1] = fields
        end

        if cfg.health then
            local pct = math.floor(UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100)
            if pct <= cfg.healthPct then
                Add({ icon = HEALTH_ICON, kind = "health", key = "health", effect = "health",
                      label = "Vida " .. pct .. "%", sLabel = "Vida " .. pct .. "%" })
            end
        end

        if cfg.debuff or cfg.snare then
            for i = 1, 40 do
                local aura, _, icon, _, _, duration, expires = UnitDebuff(unit, i)
                if not aura then break end
                local info = AURAS[aura]
                local value
                if duration and duration > 0 and expires then value = (expires - now) / duration end
                if cfg.debuff and info and info.kind == "debuff" then
                    Add({ icon = icon, kind = "debuff", key = aura, effect = info.effect, label = info.label,
                          value = value })
                elseif cfg.snare and not info and SNARES[aura] then
                    Add({ icon = icon, kind = "snare", key = aura, effect = "snare",
                          label = "Frenado (" .. aura .. ")", value = value })
                end
            end
        end

        if (cfg.purge and canPurge) or cfg.drink then
            for i = 1, 40 do
                local aura, _, icon, _, _, duration, expires = UnitBuff(unit, i)
                if not aura then break end
                if cfg.purge and canPurge and PURGEABLE[aura] then
                    local value
                    if duration and duration > 0 and expires then value = (expires - now) / duration end
                    Add({ icon = icon, kind = "purge", key = aura, effect = "purge",
                          label = "Purgar: " .. PURGEABLE[aura], value = value,
                          hot = PURGE_HOT[aura] and TipOn("purgeHot") })
                elseif cfg.drink and DRINKS[aura] then
                    Add({ icon = icon, kind = "drink", key = "drink", effect = "drink",
                          label = "Bebiendo: le falta maná" })
                end
            end
        end
    end
end

local function ScanEnemies()
    local cfg = ns.GetDB().alerts.enemy
    local now = GetTime()
    local list = {}

    for guid, e in pairs(enemies) do
        local unit = UnitForGUID(guid)
        local base = { name = e.name, class = e.class, unit = unit, pkey = guid }
        local function Add(fields)
            for k, v in pairs(base) do fields[k] = v end
            list[#list + 1] = fields
        end
        local activeCats = {}

        -- Controles activos (con su DR: como durara el siguiente)
        for spell, c in pairs(e.cc) do
            if now - c.applied > CC_FALLBACK then
                e.cc[spell] = nil
                if e.dr[c.cat] then e.dr[c.cat].resetAt = now + DR_RESET end
            else
                activeCats[c.cat] = true
                if cfg.cc then
                    local value
                    if unit then
                        local _, _, _, _, _, duration, expires = UnitDebuff(unit, spell)
                        if duration and duration > 0 and expires then value = (expires - now) / duration end
                    end
                    local dr = e.dr[c.cat]
                    Add({ icon = c.icon, kind = "cc", key = spell, effect = c.cat, value = value,
                          label = c.label .. " (" .. tostring(c.caster) .. ")",
                          dr = dr and "DR " .. DR_NEXT[math.min(dr.count, 3)] })
                end
            end
        end

        -- DR pendiente tras acabar el control: cuanto falta para que se reinicie
        for cat, dr in pairs(e.dr) do
            if dr.resetAt and now > dr.resetAt then
                e.dr[cat] = nil
            elseif dr.resetAt and cfg.cc and not activeCats[cat] then
                Add({ icon = dr.icon, kind = "dr", key = "dr" .. cat, effect = cat,
                      value = (dr.resetAt - now) / DR_RESET,
                      label = CC_LABELS[cat] .. ": siguiente " .. DR_NEXT[math.min(dr.count, 3)],
                      sLabel = "Siguiente " .. DR_NEXT[math.min(dr.count, 3)] })
            end
        end

        -- Inmunidades y abalorio solo si el enemigo es identificable
        for spell, im in pairs(e.immune) do
            if now - im.applied > IMMUNE_FALLBACK then
                e.immune[spell] = nil
            elseif unit and cfg.immune then
                Add({ icon = im.icon, kind = "immune", key = spell, effect = im.effect, label = im.label })
            end
        end
        if e.trinketAt then
            local left = TRINKET_CD - (now - e.trinketAt)
            if left <= 0 then
                e.trinketAt = nil
            elseif unit and cfg.trinket then
                Add({ icon = SpellIcon(42292), kind = "trinket", key = "trinket", effect = "trinket",
                      label = "Sin abalorio", value = left / TRINKET_CD })
            end
        end

        -- Cooldowns importantes que ya uso (identificables)
        for spell, c in pairs(e.cds) do
            local left = c.cd - (now - c.usedAt)
            if left <= 0 then
                e.cds[spell] = nil
            elseif unit and cfg.cooldowns then
                Add({ icon = c.icon, kind = "ecd", key = spell, effect = c.effect,
                      label = spell .. " usado", value = left / c.cd })
            end
        end

        if not next(e.cc) and not next(e.dr) and not next(e.immune) and not next(e.cds) and not e.trinketAt then
            enemies[guid] = nil
        end
    end

    -- Totems enemigos (de cualquier chaman enemigo, no hace falta tenerlo de objetivo)
    for guid, t in pairs(totems) do
        if now > t.expires then
            totems[guid] = nil
        elseif cfg.totems then
            list[#list + 1] = { name = t.owner, class = t.class, unit = UnitForGUID(t.ownerGUID),
                                pkey = t.ownerGUID, key = guid, icon = t.icon, kind = "totem",
                                label = t.label, sLabel = t.short, value = (t.expires - now) / t.dur }
        end
    end

    ScanEnemyUnits(list, cfg, now)
    ScanCasts(list, cfg, now)
    return list  -- se ordena y agrupa por jugador al dibujar
end

---------------------------------------------------------------------------
-- Extras de la fila de aliados: tu propio DR y "lo enfocan" (arena)
---------------------------------------------------------------------------

local FOCUS_MIN = 2  -- enemigos de arena apuntando al mismo aliado
local FRIENDLY_UNITS = { "player", "party1", "party2", "party3", "party4" }

local function ScanAllyExtras(list, now)
    local cfg = ns.GetDB().alerts.ally
    local _, myClass = UnitClass("player")

    -- Tu DR: como te durara el siguiente control de cada tipo (para decidir el abalorio)
    for cat, dr in pairs(selfDR) do
        if dr.active and now - dr.at > CC_FALLBACK then
            dr.active, dr.resetAt = nil, now + DR_RESET
        end
        if dr.resetAt and now > dr.resetAt then
            selfDR[cat] = nil
        elseif cfg.selfDR and not dr.active and dr.resetAt then
            list[#list + 1] = { name = "Tú", class = myClass, unit = "player", pkey = UnitGUID("player"),
                                key = "dr" .. cat, icon = dr.icon, kind = "dr", effect = cat,
                                label = CC_LABELS[cat] .. ": siguiente " .. DR_NEXT[math.min(dr.count, 3)],
                                sLabel = "Siguiente " .. DR_NEXT[math.min(dr.count, 3)],
                                value = (dr.resetAt - now) / DR_RESET }
        end
    end

    -- Lo enfocan: varios enemigos de arena con el mismo aliado de objetivo
    if cfg.focus then
        local counts = {}
        for i = 1, 5 do
            local guid = UnitGUID("arena" .. i .. "target")
            if guid then counts[guid] = (counts[guid] or 0) + 1 end
        end
        for _, unit in ipairs(FRIENDLY_UNITS) do
            local guid = UnitGUID(unit)
            local n = guid and counts[guid]
            if n and n >= FOCUS_MIN then
                local _, class = UnitClass(unit)
                local name = UnitIsUnit(unit, "player") and "Tú" or UnitName(unit)
                list[#list + 1] = { name = name, class = class, unit = unit, pkey = guid, key = "focus",
                                    icon = FOCUS_ICON, kind = "focus", effect = "focus",
                                    label = "Lo enfocan " .. n .. " enemigos", sLabel = "Lo enfocan " .. n }
            end
        end
    end
end

---------------------------------------------------------------------------
-- Consejos: icono con titulo corto en la fila del jugador al que se refiere
---------------------------------------------------------------------------

local switchState, switchedAt = {}, {}  -- "te apunta": a quien apuntaba cada enemigo

local function Who(unit)
    local _, class = UnitClass(unit)
    return { name = UnitIsUnit(unit, "player") and "Tú" or UnitName(unit), class = class, unit = unit,
             pkey = UnitGUID(unit) }
end

-- detailIcon/detailLabel: modo detallado. sIcon: icono propio tambien en simple (totem destruido)
local function Tip(list, key, who, detailIcon, detailLabel, value, sIcon)
    local t = TIP_BY_KEY[key]
    list[#list + 1] = { name = who.name, class = who.class, unit = who.unit, pkey = who.pkey,
                        key = "tip" .. key, kind = "tip", icon = detailIcon or t.icon, label = detailLabel,
                        sIcon = sIcon or t.icon, sLabel = t.short, value = value }
end

local function IsEnemyPlayer(unit)
    return UnitExists(unit) and UnitIsPlayer(unit) and UnitCanAttack("player", unit) and not UnitIsDeadOrGhost(unit)
end

local function HealthPct(unit)
    return UnitHealth(unit) / math.max(UnitHealthMax(unit), 1) * 100
end

-- Frenado, enraizado o aturdido (no hace falta frenarlo / ya esta quieto)
local function IsSlowed(unit)
    for i = 1, 40 do
        local name = UnitDebuff(unit, i)
        if not name then return false end
        local a = AURAS[name]
        if SNARES[name] or (a and (a.cat == "root" or a.cat == "stun")) then return true end
    end
end

local function HasAura(unit, set, filterFn)
    for i = 1, 40 do
        local name = UnitDebuff(unit, i)
        if not name then return false end
        if set[name] or (filterFn and filterFn(name)) then return true end
    end
end

local function HasCC(unit)
    return HasAura(unit, {}, function(name) return AURAS[name] and AURAS[name].kind == "cc" end)
end

local function HasHealCut(unit)
    return HasAura(unit, {}, function(name) return AURAS[name] and AURAS[name].effect == "healcut" end)
end

-- Enemigos (objetivo, foco, arena) que te estan lanzando algo a ti
local function CastsAtMe()
    local list, done = {}, {}
    for _, unit in ipairs(ENEMY_UNITS) do
        local guid = UnitGUID(unit)
        if guid and not done[guid] and UnitCanAttack("player", unit) and UnitIsUnit(unit .. "target", "player") then
            done[guid] = true
            local spell = UnitCastingInfo(unit) or UnitChannelInfo(unit)
            if spell then
                local info = AURAS[spell]
                list[#list + 1] = { unit = unit, spell = spell, cat = info and info.kind == "cc" and info.cat }
            end
        end
    end
    return list
end

-- Tu y tu grupo (o banda), sin repetir
local function FriendlyUnits()
    local units, done = {}, {}
    local all = { "player" }
    for _, unit in ipairs(GroupUnits()) do all[#all + 1] = unit end
    for _, unit in ipairs(all) do
        local guid = UnitGUID(unit)
        if guid and not done[guid] and not UnitIsDeadOrGhost(unit) then
            done[guid] = true
            units[#units + 1] = unit
        end
    end
    return units
end

-- Tu o aliados con la vida por debajo de pct
local function LowAllies(pct)
    local list = {}
    for _, unit in ipairs(FriendlyUnits()) do
        if HealthPct(unit) <= pct then list[#list + 1] = unit end
    end
    return list
end

-- Enemigos jugadores a menos de unos 10 m (cuerpo a cuerpo)
local function EnemiesClose()
    local list = {}
    for _, unit in ipairs(EnemyPlayerUnits()) do
        if CheckInteractDistance(unit, 3) then list[#list + 1] = unit end
    end
    return list
end

local function ManaPct()
    return UnitPower("player", 0) / math.max(UnitPowerMax("player", 0), 1) * 100
end

-- Sin rendimiento decreciente de ese tipo de control (o ya reiniciado)
local function DRFree(unit, cat, now)
    local e = enemies[UnitGUID(unit)]
    local dr = e and e.dr[cat]
    return not dr or (dr.resetAt and now > dr.resetAt) or false
end

-- Control al foco: es un enemigo libre, no es tu objetivo, esta a rango y sin DR de ese tipo
local function FocusFree(spellName, cat, now)
    return spellName and IsEnemyPlayer("focus") and not UnitIsUnit("focus", "target") and not HasCC("focus")
        and IsSpellInRange(spellName, "focus") == 1 and DRFree("focus", cat, now)
end

-- Desarmar / Desmantelar a quien tenga un potenciador cuerpo a cuerpo
local function DisarmTips(list, key, spellId, verb, now)
    if not (TipOn(key) and Ready(spellId, now)) then return end
    for _, unit in ipairs(EnemyPlayerUnits()) do
        for i = 1, 40 do
            local buff = UnitBuff(unit, i)
            if not buff then break end
            if DISARM_BUFFS[buff] then
                Tip(list, key, Who(unit), nil, verb .. ": tiene " .. buff)
                break
            end
        end
    end
end

local function ArenaTargetCounts()
    local counts = {}
    for i = 1, 5 do
        local guid = UnitGUID("arena" .. i .. "target")
        if guid then counts[guid] = (counts[guid] or 0) + 1 end
    end
    return counts
end

local function ScanTips(allies, foes, now)
    local db = ns.GetDB()
    if not db.features.tips then return end
    if not book then UpdateBook() end
    local me = Who("player")

    -- ¡Defiendete!: poca vida (o te enfocan) y tienes un defensivo listo
    if TipOn("defend") then
        local pct = HealthPct("player")
        local focused = (ArenaTargetCounts()[UnitGUID("player")] or 0) >= FOCUS_MIN
        if pct <= DEFEND_PCT or (focused and pct <= 60) then
            for _, id in ipairs(DEFENSIVES) do
                local name = Ready(id, now)
                if name then
                    Tip(allies, "defend", me, SpellIcon(id), "Usa " .. name)
                    break
                end
            end
        end
    end

    -- Se oculto (Esfumarse, Sigilo...)
    for guid, s in pairs(stealthed) do
        local age = now - s.at
        if age > TIP_SHOW.stealth then
            stealthed[guid] = nil
        elseif TipOn("stealth") then
            Tip(foes, "stealth", { name = s.name, class = s.class, unit = UnitForGUID(guid), pkey = guid },
                s.icon, s.spell .. ": se ocultó", 1 - age / TIP_SHOW.stealth)
        end
    end

    -- Te apunta: un enemigo cambia de objetivo y pasa a ti
    if TipOn("targetSwitch") then
        for _, unit in ipairs(EnemyPlayerUnits()) do
            local guid = UnitGUID(unit)
            local onMe = UnitIsUnit(unit .. "target", "player") and true or false
            if onMe and switchState[guid] == false then switchedAt[guid] = now end
            switchState[guid] = onMe
            local at = switchedAt[guid]
            if onMe and at and now - at < TIP_SHOW.targetSwitch then
                Tip(foes, "targetSwitch", Who(unit), nil, "Te ha cambiado de objetivo",
                    1 - (now - at) / TIP_SHOW.targetSwitch)
            end
        end
    end

    -- ¡A por el!: un posible sanador enemigo esta controlado y otro enemigo tiene poca vida
    if TipOn("killWindow") then
        local healerGUID, healer
        for guid, e in pairs(enemies) do
            if HEALER_CLASSES[e.class] and next(e.cc) then healerGUID, healer = guid, e break end
        end
        if healer then
            for _, unit in ipairs(EnemyPlayerUnits()) do
                if UnitGUID(unit) ~= healerGUID and HealthPct(unit) <= db.alerts.enemy.healthPct then
                    Tip(foes, "killWindow", Who(unit), nil, healer.name .. " controlado: ¡a por él!")
                end
            end
        end
    end

    -- Lo que te estan lanzando a ti: Reflejo, Ira rabiosa, Derribador, Temblor
    for _, c in ipairs(CastsAtMe()) do
        local fear = c.cat == "fear" or c.cat == "horror"
        if c.cat and TipOn("reflectCC") and Ready(23920, now) then
            Tip(foes, "reflectCC", Who(c.unit), nil, "Reflejo de hechizos: te lanza " .. c.spell)
        end
        if fear and TipOn("berserkerFear") and Ready(18499, now) then
            Tip(foes, "berserkerFear", Who(c.unit), nil, "Ira rabiosa: te lanza " .. c.spell)
        end
        if (c.cat or BIGS[c.spell]) and TipOn("grounding") and Ready(8177, now) then
            Tip(foes, "grounding", Who(c.unit), nil, "Tótem derribador: te lanza " .. c.spell)
        end
        if fear and TipOn("tremor") and Ready(8143, now) then
            Tip(foes, "tremor", Who(c.unit), nil, "Tótem de temblor: te lanza " .. c.spell)
        end
        if fear and TipOn("fearWard") and Ready(6346, now) then
            Tip(foes, "fearWard", Who(c.unit), nil, "Custodia de miedo: te lanza " .. c.spell)
        end
        if (c.cat or BIGS[c.spell]) and TipOn("cloak") and Ready(31224, now) then
            Tip(foes, "cloak", Who(c.unit), nil, "Capa de las Sombras: te lanza " .. c.spell)
        end
        if (fear or c.cat == "charm") and TipOn("lichborne") and Ready(49039, now) then
            Tip(foes, "lichborne", Who(c.unit), nil, "Exánime: te lanza " .. c.spell)
        end
        if (c.cat or BIGS[c.spell]) and TipOn("amsCast") and Ready(48707, now) then
            Tip(foes, "amsCast", Who(c.unit), nil, "Caparazón antimagia: te lanza " .. c.spell)
        end
    end

    -- Guerrero
    DisarmTips(foes, "disarm", 676, "Desarmar", now)
    if TipOn("hamstring") and Known(1715) and IsEnemyPlayer("target") and CheckInteractDistance("target", 3)
        and not IsSlowed("target") then
        Tip(foes, "hamstring", Who("target"), nil, "Seccionar: no va frenado")
    end
    local ms = TipOn("msRefresh") and Known(12294)
    if ms and IsEnemyPlayer("target") then
        local _, _, _, _, _, duration, expires, caster = UnitDebuff("target", ms)
        local left = caster == "player" and expires and expires - now
        if left and left < 2.5 and duration and duration > 0 then
            Tip(foes, "msRefresh", Who("target"), nil, "Golpe mortal: se acaba", left / duration)
        elseif not HasHealCut("target") and CheckInteractDistance("target", 3) and Ready(12294, now) then
            Tip(foes, "msRefresh", Who("target"), nil, "Golpe mortal: no tiene -50% curación")
        end
    end

    -- Mago
    if TipOn("frozen") and IsEnemyPlayer("target") and HasAura("target", FROZEN) then
        if Ready(44572, now) then
            Tip(foes, "frozen", Who("target"), SpellIcon(44572), "Ultracongelación: está congelado")
        elseif Known(30455) then
            Tip(foes, "frozen", Who("target"), SpellIcon(30455), "Lanza de hielo: está congelado")
        end
    end
    local poly = TipOn("polyFocus") and Ready(118, now)
    if FocusFree(poly, "incap", now) then
        Tip(foes, "polyFocus", Who("focus"), nil, "Polimorfia a tu foco")
    end
    if TipOn("nova") and Ready(122, now) then
        for _, unit in ipairs(EnemyPlayerUnits()) do
            if CheckInteractDistance(unit, 3) and not IsSlowed(unit) then
                Tip(foes, "nova", Who(unit), nil, "Nova de escarcha: te tiene encima")
            end
        end
    end
    local barrier = TipOn("barrier") and Ready(11426, now)
    if barrier and UnitAffectingCombat("player") and not UnitBuff("player", barrier) then
        Tip(allies, "barrier", me, nil, "Barrera de hielo: no la tienes puesta")
    end

    -- Chaman
    if TipOn("tremor") and Ready(8143, now) and ns.GroupHasCC(ns.CC.fear) then
        Tip(allies, "tremor", me, nil, "Tótem de temblor: hay miedo en tu grupo")
    end
    for guid, d in pairs(totemsDown) do
        local age = now - d.at
        if age > TIP_SHOW.totemDown then
            totemsDown[guid] = nil
        elseif TipOn("totemDown") then
            Tip(allies, "totemDown", me, d.icon, d.spell .. " destruido: recolócalo",
                1 - age / TIP_SHOW.totemDown, d.icon)
        end
    end
    if TipOn("shield") and (Known(52127) or Known(324)) then
        local has = false
        for _, id in ipairs({ 52127, 324, 974 }) do  -- Water Shield, Lightning Shield, Earth Shield
            local name = GetSpellInfo(id)
            if name and UnitBuff("player", name) then has = true end
        end
        if not has then
            Tip(allies, "shield", me, SpellIcon(Known(52127) and 52127 or 324), "Te falta Escudo de agua o de relámpagos")
        end
    end
    local lowPct = db.alerts.ally.healthPct
    if TipOn("nsHeal") and (Ready(16188, now) or Ready(17116, now)) then  -- chaman / druida
        for _, unit in ipairs(LowAllies(lowPct)) do
            Tip(allies, "nsHeal", Who(unit), nil, "Presteza de la naturaleza + curación")
        end
    end

    local close = EnemiesClose()

    -- Sacerdote
    if TipOn("psyScream") and Ready(8122, now) and close[1] then
        Tip(foes, "psyScream", Who(close[1]), nil, "Grito psíquico: te tiene encima")
    end
    if TipOn("shieldAlly") and Ready(17, now) then
        local pws, weak = GetSpellInfo(17), GetSpellInfo(6788)  -- Power Word: Shield, Weakened Soul
        for _, unit in ipairs(LowAllies(lowPct + 20)) do
            if not UnitBuff(unit, pws) and not UnitDebuff(unit, weak) then
                Tip(allies, "shieldAlly", Who(unit), nil, "Palabra de poder: escudo")
            end
        end
    end
    if TipOn("painSup") then
        local id = (Ready(33206, now) and 33206) or (Ready(47788, now) and 47788)  -- Pain Suppression, Guardian Spirit
        if id then
            for _, unit in ipairs(LowAllies(lowPct)) do
                Tip(allies, "painSup", Who(unit), SpellIcon(id), GetSpellInfo(id) .. ": está a punto de morir")
            end
        end
    end
    if TipOn("shadowfiend") and Ready(34433, now) and UnitAffectingCombat("player") and ManaPct() < 30 then
        Tip(allies, "shadowfiend", me, nil, "Maligno de las Sombras: te falta maná")
    end

    -- Picaro
    if TipOn("kidney") and Ready(408, now) and IsEnemyPlayer("target") and GetComboPoints("player", "target") >= 4
        and not HasCC("target") and DRFree("target", "stun", now) then
        Tip(foes, "kidney", Who("target"), nil, "Golpe en los riñones: tienes puntos y no tiene DR")
    end
    local blind = TipOn("blindHealer") and Ready(2094, now)
    if blind then
        for _, unit in ipairs(EnemyPlayerUnits()) do
            local _, class = UnitClass(unit)
            if HEALER_CLASSES[class] and not UnitIsUnit(unit, "target") and not HasCC(unit)
                and IsSpellInRange(blind, unit) == 1 and DRFree(unit, "fear", now) then
                Tip(foes, "blindHealer", Who(unit), nil, "Ceguera al sanador")
            end
        end
    end
    DisarmTips(foes, "dismantle", 51722, "Desmantelar", now)

    -- Druida
    local cyclone = TipOn("cycloneFocus") and Ready(33786, now)
    if FocusFree(cyclone, "cyclone", now) then
        Tip(foes, "cycloneFocus", Who("focus"), nil, "Ciclón a tu foco")
    end
    if TipOn("shiftRoot") and (Known(768) or Known(5487) or Known(783)) and ns.UnitHasCC("player", ns.CC.root) then
        Tip(allies, "shiftRoot", me, nil, "Cambia de forma: quita raíces y frenados")
    end
    if TipOn("innervate") and Ready(29166, now) and UnitAffectingCombat("player") and ManaPct() < 30 then
        Tip(allies, "innervate", me, nil, "Inervar: te falta maná")
    end

    -- Paladin
    if TipOn("bopAlly") and Ready(1022, now) then
        local forbearance = GetSpellInfo(25771)
        for _, unit in ipairs(LowAllies(lowPct)) do
            if not UnitDebuff(unit, forbearance) then
                Tip(allies, "bopAlly", Who(unit), nil, "Mano de protección: le pegan y va mal")
            end
        end
    end
    if TipOn("freedom") and Ready(1044, now) then
        for _, unit in ipairs(FriendlyUnits()) do
            if ns.UnitHasCC(unit, ns.CC.root) then
                Tip(allies, "freedom", Who(unit), nil, "Mano de libertad: va enraizado o frenado")
            end
        end
    end
    local hoj = TipOn("hojKill") and Ready(853, now)
    if hoj and IsEnemyPlayer("target") and HealthPct("target") <= db.alerts.enemy.healthPct and not HasCC("target")
        and IsSpellInRange(hoj, "target") == 1 and DRFree("target", "stun", now) then
        Tip(foes, "hojKill", Who("target"), nil, "Martillo de justicia: que no se escape")
    end

    -- Cazador
    if TipOn("scatter") and Ready(19503, now) and close[1] then
        Tip(foes, "scatter", Who(close[1]), nil, "Disparo de dispersión: te tiene encima")
    end
    local aimed = TipOn("aimed") and Ready(19434, now)
    if aimed and IsEnemyPlayer("target") and not HasHealCut("target") and IsSpellInRange(aimed, "target") == 1 then
        Tip(foes, "aimed", Who("target"), nil, "Disparo apuntado: no tiene -50% curación")
    end
    local wyvern = TipOn("wyvernFocus") and Ready(19386, now)
    if FocusFree(wyvern, "incap", now) then
        Tip(foes, "wyvernFocus", Who("focus"), nil, "Picadura de dracoleón a tu foco")
    end

    -- Brujo
    local fearSpell = TipOn("fearFocus") and Ready(5782, now)
    if FocusFree(fearSpell, "fear", now) then
        Tip(foes, "fearFocus", Who("focus"), nil, "Miedo a tu foco")
    end
    if TipOn("deathCoil") and Ready(6789, now) and close[1] and HealthPct("player") <= 50 then
        Tip(foes, "deathCoil", Who(close[1]), nil, "Espiral de la muerte: te pega y vas mal")
    end
    if TipOn("howl") and Ready(5484, now) and close[1] then
        Tip(foes, "howl", Who(close[1]), nil, "Aullido de terror: te tiene encima")
    end
    local ua = TipOn("uaKeep") and Known(30108)
    if ua and IsEnemyPlayer("target") and UnitAffectingCombat("player") then
        local _, _, _, _, _, _, _, caster = UnitDebuff("target", ua)
        if caster ~= "player" then
            Tip(foes, "uaKeep", Who("target"), nil, "Aflicción inestable: no la tiene")
        end
    end

    -- Caballero de la Muerte
    local strangulate = TipOn("strangulate") and Ready(47476, now)
    if strangulate then
        for _, unit in ipairs(EnemyPlayerUnits()) do
            local _, class = UnitClass(unit)
            if HEALER_CLASSES[class] and not HasCC(unit) and IsSpellInRange(strangulate, unit) == 1 then
                Tip(foes, "strangulate", Who(unit), nil, "Estrangular al sanador")
            end
        end
    end
    local far = IsEnemyPlayer("target") and not CheckInteractDistance("target", 3)
    local chains = TipOn("chains") and Ready(45524, now)
    if chains and far and not IsSlowed("target") and IsSpellInRange(chains, "target") == 1 then
        Tip(foes, "chains", Who("target"), nil, "Cadenas de hielo: se escapa")
    end
    local grip = TipOn("grip") and Ready(49576, now)
    if grip and far and IsSpellInRange(grip, "target") == 1 then
        Tip(foes, "grip", Who("target"), nil, "Atracción letal: se aleja")
    end
end

---------------------------------------------------------------------------
-- Bucle
---------------------------------------------------------------------------

local elapsedSince = 0
local firstSeen = {}  -- [jugador:alerta] = { t = cuando aparecio, seen = ultima vez vista }
local FORGET_AFTER = 1  -- si una alerta falta menos de esto (vida baja que sube y baja), no vuelve a salir en grande

-- Anota en cada alerta cuanto lleva activa (a.age)
local function Stamp(list, now)
    for _, a in ipairs(list) do
        local id = tostring(a.pkey or a.name) .. ":" .. tostring(a.key or a.label)
        local s = firstSeen[id]
        if not s then
            s = { t = now }
            firstSeen[id] = s
        end
        s.seen = now
        a.age = now - s.t
    end
end

-- Consejo de la demostracion convertido en alerta (solo si esta encendido y es de tu clase)
local function DemoTip(d)
    if not TipOn(d.tip) then return end
    local who = d.me and Who("player") or { name = d.name, class = d.class, pkey = d.name }
    local list = {}
    local icon = d.spell and SpellIcon(d.spell)
    Tip(list, d.tip, who, icon, d.label, nil, d.sIcon and icon)
    list[1].start = d.start
    return list[1]
end

-- Demostracion: cada alerta aparece en su segundo del ciclo (static = todas a la vez).
-- Incluye los consejos generales y los de tu clase.
local function DemoList(key, t, static)
    local list = {}
    local ct = t % DEMO_CYCLE
    local function Add(a)
        if a and (static or ct >= a.start) then
            if a.dur then a.value = 1 - (t % a.dur) / a.dur end
            a.age = static and POP_TIME or ct - a.start
            list[#list + 1] = a
        end
    end
    for _, a in ipairs(DEMO[key]) do Add(a) end
    for _, group in ipairs({ DEMO_TIPS.ALL, DEMO_TIPS[ns.class] or {} }) do
        for _, d in ipairs(group) do
            if d.side == key then Add(DemoTip(d)) end
        end
    end
    return list
end

-- Reparte las alertas: las nuevas al centro (1,5 s) y las demas al panel.
-- Sin panel, todo se queda en el centro; sin aviso en el centro, todo va directo al panel.
local function Split(list, popOn, panelOn, showAll)
    local pop, panel = {}, {}
    for _, a in ipairs(list) do
        if showAll then
            if popOn then pop[#pop + 1] = a end
            if panelOn then panel[#panel + 1] = a end
        elseif popOn and (a.age < POP_TIME or not panelOn) then
            pop[#pop + 1] = a
        elseif panelOn then
            panel[#panel + 1] = a
        end
    end
    return pop, panel
end

local function OnUpdate(_, elapsed)
    elapsedSince = elapsedSince + elapsed
    local db = ns.GetDB()
    -- mientras se mueven las barras se ve la demostracion, para ver el tamano real
    local showDemo = demoOn or not db.locked
    if elapsedSince < SCAN_INTERVAL and not showDemo then return end
    elapsedSince = 0

    local now = GetTime()
    local size = AlertSize()
    PlaceRows(size)

    if demoOn and demoUntil and now > demoUntil then
        demoOn, demoUntil = false, nil
        showDemo = not db.locked
    end

    local allies, foes, t, static = {}, {}, now, false
    if showDemo then
        t = now - demoStart
        -- moviendo o vista previa de tamano: todo a la vez; /pvpkit demo: aparecen de una en una
        static = not db.locked or demoUntil ~= nil
        allies, foes = DemoList("ally", t, static), DemoList("enemy", t, static)
    else
        if db.enabled and db.features.alerts then
            allies = ScanAllies()
            ScanAllyExtras(allies, now)
            foes = ScanEnemies()
            ScanTips(allies, foes, now)
            Stamp(allies, now)
            Stamp(foes, now)
        end
        for id, s in pairs(firstSeen) do
            if now - s.seen > FORGET_AFTER then firstSeen[id] = nil end
        end
    end

    local simple = db.alertSimple
    local popOn, panelOn = db.features.alertPop, db.features.alertPanel
    local popA, panelA = Split(allies, popOn, panelOn, static)
    local popE, panelE = Split(foes, popOn, panelOn, static)
    DrawRow(rows.ally, GroupByPlayer(popA, simple), size, simple, t)
    DrawRow(rows.enemy, GroupByPlayer(popE, simple), size, simple, t)
    DrawPanel(panels.ally, GroupByPlayer(panelA, simple), simple, t)
    DrawPanel(panels.enemy, GroupByPlayer(panelE, simple), simple, t)
end

-- Se llama al terminar de cargar (Core.lua)
function ns.InitAlerts()
    Build()
    ns.ApplyAlertsLock()
    local lastErr

    local events = CreateFrame("Frame")
    events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("SPELLS_CHANGED")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            -- nueva zona / arena: se olvida lo anterior
            wipe(enemies); wipe(totems); wipe(selfDR); wipe(firstSeen)
            wipe(stealthed); wipe(myTotems); wipe(totemsDown); wipe(switchState); wipe(switchedAt)
            return
        elseif event == "SPELLS_CHANGED" then
            book = nil  -- se vuelve a leer el libro (y si puedes purgar)
            return
        end
        local ok, err = pcall(OnCombatLog, ...)
        if not ok and err ~= lastErr then
            lastErr = err
            ns.LogError("registro de combate: " .. tostring(err))
        end
    end)

    container:SetScript("OnUpdate", function(self, elapsed)
        local ok, err = pcall(OnUpdate, self, elapsed)
        if not ok and err ~= lastErr then
            lastErr = err
            ns.LogError("alertas: " .. tostring(err))
        end
    end)
end

-- Posicion guardada y modo mover (llamado desde ApplyLock en Core.lua)
function ns.ApplyAlertsLock()
    if not container then return end
    local db = ns.GetDB()
    local pos = db.alertPos
    container:ClearAllPoints()
    container:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    container:SetHeight(50 + 2 * (CenterRowHeight(AlertSize()) + 12))
    container:EnableMouse(not db.locked)
    if db.locked then
        container.bg:Hide(); container.label:Hide()
    else
        container.bg:Show(); container.label:Show()
    end

    -- Paneles laterales: el marco para arrastrar tiene el tamano de unos 3 jugadores
    for key, p in pairs(panels) do
        local cfg = db.panels[key]
        p:ClearAllPoints()
        p:SetPoint(cfg.point, UIParent, cfg.relPoint, cfg.x, cfg.y)
        local long, short = cfg.size * 6, (cfg.size + NAME_H + BLOCK_GAP) * 3
        if cfg.dir == "V" then
            p:SetWidth(short); p:SetHeight(long)
        else
            p:SetWidth(long); p:SetHeight(short)
        end
        p:EnableMouse(not db.locked)
        if db.locked then
            p.bg:Hide()
            p.header:SetText(PANEL_TITLES[key])
        else
            p.bg:Show()
            p.header:SetText("Panel " .. PANEL_TITLES[key] .. " (arrastra para mover)")
        end
    end
end

-- /pvpkit demo: demostracion fija hasta volver a escribirlo
function ns.ToggleDemo()
    demoOn = not demoOn
    demoStart, demoUntil = GetTime(), nil
    return demoOn
end

-- Vista previa al cambiar el tamano: demostracion durante 5 segundos
function ns.ShowDemo()
    if demoOn and not demoUntil then return end  -- ya esta fija
    demoOn = true
    demoStart = demoStart > 0 and demoStart or GetTime()
    demoUntil = GetTime() + 5
end
