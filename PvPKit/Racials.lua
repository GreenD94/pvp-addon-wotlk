local _, ns = ...

-- Raciales: comunes a todas las clases (Core.lua las anade al final de la lista de la clase).
-- Solo aparece la de tu raza. Se reconocen por nombre, asi sirve la version de cada clase.
-- Ninguna hace dano -> barra defensiva.
ns.RACIALS = {
    { id = 20572, def = true },  -- Blood Fury (orco)
    { id = 26297, def = true },  -- Berserking (trol)
    { id = 20549, def = true },  -- War Stomp (tauren)
    { id = 7744,  def = true },  -- Will of the Forsaken (no-muerto)
    { id = 59752, def = true },  -- Every Man for Himself (humano)
    { id = 20594, def = true },  -- Stoneform (enano)
    { id = 20589, def = true },  -- Escape Artist (gnomo)
    { id = 28880, def = true },  -- Gift of the Naaru (draenei)
    { id = 58984, def = true },  -- Shadowmeld (elfo de la noche)
    { id = 28730, def = true },  -- Arcane Torrent (elfo de sangre)
}
