local _, ns = ...

-- Habilidades rastreadas, en orden de prioridad (la primera sale a la izquierda).
-- id   = spell ID de rango 1 (el nombre localizado se saca del cliente, sirve para cualquier idioma)
-- def  = barra defensiva. Regla: si hace dano es ofensiva; si no, defensiva.
--        Excepcion: Cargar, Interceptar e Intervenir van en la ofensiva.
-- aura = solo disponible si el jugador tiene este buff (procs)
-- cond = condicion extra, ver ns.conditions en Core.lua
ns.spells = {
    -- Ofensivas: hacen dano
    { id = 5308 },                        -- Execute (objetivo < 20% o Muerte subita)
    { id = 23922 },                       -- Shield Slam (incluye reinicio por Espada y escudo)
    { id = 6572 },                        -- Revenge (tras bloquear/esquivar/parar)
    { id = 7384 },                        -- Overpower (tras esquiva / Sabor de sangre)
    { id = 34428 },                       -- Victory Rush (tras matar)
    { id = 1464,  aura = 46916 },         -- Slam, solo con proc de Oleada sangrienta
    { id = 23881 },                       -- Bloodthirst
    { id = 12294 },                       -- Mortal Strike
    { id = 1680 },                        -- Whirlwind
    { id = 46968 },                       -- Shockwave
    { id = 12809 },                       -- Concussion Blow
    { id = 6343 },                        -- Thunder Clap
    { id = 694,   cond = "notTanking" },  -- Mocking Blow, solo si el objetivo pega a otro
    { id = 46924 },                       -- Bladestorm
    { id = 20230 },                       -- Retaliation
    { id = 57755 },                       -- Heroic Throw
    { id = 64382 },                       -- Shattering Throw
    { id = 100,   cond = "inRange" },     -- Charge, solo entre 8 y 25 m del objetivo
    { id = 20252, cond = "inRange" },     -- Intercept, idem
    { id = 3411,  cond = "inRange" },     -- Intervene, solo con un aliado objetivo a rango

    -- Defensivas: no hacen dano (defensa, vida, curacion, ira, control, potenciadores)
    { id = 2565,  def = true },                        -- Shield Block
    { id = 23920, def = true, cond = "castingOnMe" },  -- Spell Reflection, solo si el objetivo me castea a mi
    { id = 72,    def = true, cond = "interrupt" },    -- Shield Bash, solo si el objetivo castea algo interrumpible
    { id = 6552,  def = true, cond = "interrupt" },    -- Pummel, idem
    { id = 355,   def = true, cond = "notTanking" },   -- Taunt, solo si el objetivo pega a otro
    { id = 12975, def = true },                        -- Last Stand
    { id = 871,   def = true },                        -- Shield Wall
    { id = 55694, def = true },                        -- Enraged Regeneration
    { id = 676,   def = true },                        -- Disarm
    { id = 5246,  def = true },                        -- Intimidating Shout
    { id = 1161,  def = true },                        -- Challenging Shout
    { id = 2687,  def = true },                        -- Bloodrage
    { id = 18499, def = true },                        -- Berserker Rage
    { id = 60970, def = true },                        -- Heroic Fury
    { id = 12292, def = true },                        -- Death Wish
    { id = 1719,  def = true },                        -- Recklessness
    { id = 12328, def = true },                        -- Sweeping Strikes
}
