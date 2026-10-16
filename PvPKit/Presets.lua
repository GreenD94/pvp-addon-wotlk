local _, ns = ...

-- Perfiles preconfigurados por especializacion: los mas jugados en WotLK 3.3.5 para PvE y PvP
-- (tanque, sanador y dano, si la clase lo permite). Se crean una sola vez por clase al entrar;
-- el jugador puede copiarlos o borrarlos (los borrados no vuelven).
--   id   = identificador fijo (no cambiar: sirve para no volver a crearlo)
--   mode = "pve" o "pvp"; role = "tank", "heal" o "dps"
--   fav  = habilidades clave de la especializacion (van a la barra de favoritas)
--   off  = habilidades que esa especializacion no usa (se ocultan)
--   tips = en PvE, consejos que quedan encendidos (el resto se apaga). En PvP van todos.
-- En PvE las alertas de JcJ se apagan salvo ¡Córtalo! (tambien sirve con PNJ); los sanadores
-- mantienen las alertas de sus aliados (control, perjuicios y vida baja).

ns.PRESETS = {
    WARRIOR = {
        { id = "pve_tank", name = "PvE Tanque Protección", mode = "pve", role = "tank",
          fav = { 23922, 6572, 2565 },                   -- Shield Slam, Revenge, Shield Block
          off = { 676, 5246, 64382, 12328 },             -- Disarm, Intimidating Shout, Shattering Throw, Sweeping Strikes
          tips = { "defend" } },
        { id = "pve_dps", name = "PvE Daño Furia", mode = "pve", role = "dps",
          fav = { 23881, 1680, 1464 },                   -- Bloodthirst, Whirlwind, Slam (proc)
          off = { 676, 5246, 64382, 355, 694, 1161, 2565, 72, 871, 12975, 23920 },
          tips = { "defend" } },
        { id = "pvp_dps", name = "PvP Daño Armas", mode = "pvp", role = "dps",
          fav = { 12294, 7384, 5308 },                   -- Mortal Strike, Overpower, Execute
          off = { 355, 694, 1161 } },                    -- Taunt, Mocking Blow, Challenging Shout
    },
    PALADIN = {
        { id = "pve_tank", name = "PvE Tanque Protección", mode = "pve", role = "tank",
          fav = { 31935, 53595, 53600 },                 -- Avenger's Shield, Hammer of the Righteous, Shield of Righteousness
          off = { 20066 },                               -- Repentance
          tips = { "defend" } },
        { id = "pve_heal", name = "PvE Sanador Sagrado", mode = "pve", role = "heal",
          fav = { 20473, 54428, 31842 },                 -- Holy Shock, Divine Plea, Divine Illumination
          off = { 62124, 31789, 20066, 26573, 2812 },    -- provocar, Repentance, Consecration, Holy Wrath
          tips = { "defend", "bopAlly", "freedom" } },
        { id = "pve_dps", name = "PvE Daño Reprensión", mode = "pve", role = "dps",
          fav = { 35395, 53385, 20271 },                 -- Crusader Strike, Divine Storm, Judgement
          off = { 62124, 31789, 20066 },
          tips = { "defend" } },
        { id = "pvp_heal", name = "PvP Sanador Sagrado", mode = "pvp", role = "heal",
          fav = { 20473, 1044, 1022 },                   -- Holy Shock, Hand of Freedom, Hand of Protection
          off = { 62124, 31789, 26573, 2812 } },
        { id = "pvp_dps", name = "PvP Daño Reprensión", mode = "pvp", role = "dps",
          fav = { 35395, 53385, 24275 },                 -- Crusader Strike, Divine Storm, Hammer of Wrath
          off = { 62124, 31789 } },
    },
    DEATHKNIGHT = {
        { id = "pve_tank", name = "PvE Tanque Sangre", mode = "pve", role = "tank",
          fav = { 55233, 48982, 49028 },                 -- Vampiric Blood, Rune Tap, Dancing Rune Weapon
          off = { 47476 },                               -- Strangulate
          tips = { "defend" } },
        { id = "pve_dps", name = "PvE Daño Profano", mode = "pve", role = "dps",
          fav = { 49206, 43265, 57330 },                 -- Summon Gargoyle, Death and Decay, Horn of Winter
          off = { 56222, 47476 },                        -- Dark Command, Strangulate
          tips = { "defend" } },
        { id = "pvp_dps", name = "PvP Daño Profano", mode = "pvp", role = "dps",
          fav = { 49206, 47476, 49576 },                 -- Summon Gargoyle, Strangulate, Death Grip
          off = { 56222 } },
    },
    DRUID = {
        { id = "pve_tank", name = "PvE Tanque Feral", mode = "pve", role = "tank",
          fav = { 33878, 22842, 61336 },                 -- Mangle (Bear), Frenzied Regeneration, Survival Instincts
          off = { 16689, 740 },                          -- Nature's Grasp, Tranquility
          tips = { "defend" } },
        { id = "pve_dps", name = "PvE Daño Equilibrio", mode = "pve", role = "dps",
          fav = { 48505, 33831, 29166 },                 -- Starfall, Force of Nature, Innervate
          off = { 6795, 5209, 16689 },                   -- Growl, Challenging Roar, Nature's Grasp
          tips = { "defend", "innervate" } },
        { id = "pve_heal", name = "PvE Sanador Restauración", mode = "pve", role = "heal",
          fav = { 18562, 48438, 17116 },                 -- Swiftmend, Wild Growth, Nature's Swiftness
          off = { 6795, 5209, 16689 },
          tips = { "defend", "nsHeal", "innervate" } },
        { id = "pvp_heal", name = "PvP Sanador Restauración", mode = "pvp", role = "heal",
          fav = { 18562, 17116, 22812 },                 -- Swiftmend, Nature's Swiftness, Barkskin
          off = { 6795, 5209 } },
        { id = "pvp_dps", name = "PvP Daño Feral", mode = "pvp", role = "dps",
          fav = { 22570, 49376, 50334 },                 -- Maim, Feral Charge (Cat), Berserk
          off = { 6795, 5209 } },
    },
    PRIEST = {
        { id = "pve_heal", name = "PvE Sanador Disciplina", mode = "pve", role = "heal",
          fav = { 47540, 33206, 10060 },                 -- Penance, Pain Suppression, Power Infusion
          off = { 8122, 64044 },                         -- Psychic Scream, Psychic Horror
          tips = { "defend", "painSup", "shieldAlly", "shadowfiend" } },
        { id = "pve_dps", name = "PvE Daño Sombras", mode = "pve", role = "dps",
          fav = { 8092, 34433, 47585 },                  -- Mind Blast, Shadowfiend, Dispersion
          off = { 8122, 64044 },
          tips = { "defend", "shadowfiend" } },
        { id = "pvp_heal", name = "PvP Sanador Disciplina", mode = "pvp", role = "heal",
          fav = { 47540, 33206, 8122 } },                -- Penance, Pain Suppression, Psychic Scream
        { id = "pvp_dps", name = "PvP Daño Sombras", mode = "pvp", role = "dps",
          fav = { 8092, 64044, 47585 } },                -- Mind Blast, Psychic Horror, Dispersion
    },
    SHAMAN = {
        { id = "pve_heal", name = "PvE Sanador Restauración", mode = "pve", role = "heal",
          fav = { 61295, 16188, 55198 },                 -- Riptide, Nature's Swiftness, Tidal Force
          off = { 51514, 8177, 2484 },                   -- Hex, Grounding Totem, Earthbind Totem
          tips = { "defend", "nsHeal", "shield" } },
        { id = "pve_dps", name = "PvE Daño Mejora", mode = "pve", role = "dps",
          fav = { 17364, 60103, 51533 },                 -- Stormstrike, Lava Lash, Feral Spirit
          off = { 51514, 8177, 2484 },
          tips = { "defend", "shield" } },
        { id = "pvp_heal", name = "PvP Sanador Restauración", mode = "pvp", role = "heal",
          fav = { 61295, 16188, 8177 } },                -- Riptide, Nature's Swiftness, Grounding Totem
        { id = "pvp_dps", name = "PvP Daño Mejora", mode = "pvp", role = "dps",
          fav = { 17364, 51533, 8177 } },                -- Stormstrike, Feral Spirit, Grounding Totem
    },
    MAGE = {
        { id = "pve_dps", name = "PvE Daño Fuego", mode = "pve", role = "dps",
          fav = { 11129, 55342, 2136 },                  -- Combustion, Mirror Image, Fire Blast
          off = { 120, 122, 543, 6143 },                 -- Cone of Cold, Frost Nova, Fire Ward, Frost Ward
          tips = { "defend" } },
        { id = "pvp_dps", name = "PvP Daño Escarcha", mode = "pvp", role = "dps",
          fav = { 44572, 12472, 11958 } },               -- Deep Freeze, Icy Veins, Cold Snap
    },
    ROGUE = {
        { id = "pve_dps", name = "PvE Daño Combate", mode = "pve", role = "dps",
          fav = { 13750, 51690, 13877 },                 -- Adrenaline Rush, Killing Spree, Blade Flurry
          off = { 408, 2094, 51722, 1776, 1725 },        -- Kidney Shot, Blind, Dismantle, Gouge, Distract
          tips = { "defend" } },
        { id = "pvp_dps", name = "PvP Daño Sutileza", mode = "pvp", role = "dps",
          fav = { 51713, 36554, 14185 } },               -- Shadow Dance, Shadowstep, Preparation
    },
    HUNTER = {
        { id = "pve_dps", name = "PvE Daño Puntería", mode = "pve", role = "dps",
          fav = { 53209, 19434, 3045 },                  -- Chimera Shot, Aimed Shot, Rapid Fire
          off = { 19503, 19386, 1513, 5116 },            -- Scatter Shot, Wyvern Sting, Scare Beast, Concussive Shot
          tips = { "defend" } },
        { id = "pvp_dps", name = "PvP Daño Puntería", mode = "pvp", role = "dps",
          fav = { 53209, 34490, 19503 } },               -- Chimera Shot, Silencing Shot, Scatter Shot
    },
    WARLOCK = {
        { id = "pve_dps", name = "PvE Daño Aflicción", mode = "pve", role = "dps",
          fav = { 48181, 29858, 603 },                   -- Haunt, Soulshatter, Curse of Doom
          off = { 5484, 6789 },                          -- Howl of Terror, Death Coil
          tips = { "defend", "uaKeep" } },
        { id = "pvp_dps", name = "PvP Daño Aflicción", mode = "pvp", role = "dps",
          fav = { 48181, 6789, 5484 } },                 -- Haunt, Death Coil, Howl of Terror
    },
}
