# PvP Kit

Addon para **World of Warcraft 3.3.5a (WotLK)**, probado en el servidor NaerZone con cliente en español.
Ayuda visual para JcJ: muestra qué habilidades están listas para usar y los procs activos, al estilo de WeakAuras pero sin configurar nada. Detecta la clase del personaje y carga su lista de habilidades.

**Clases:** las 10 de WotLK. Guerrero (probado), Chamán (en prueba) y Mago, Sacerdote, Pícaro, Druida, Paladín, Cazador, Brujo y Caballero de la Muerte (listas hechas, sin probar). Las raciales son comunes a todas (`Racials.lua`).

## Qué hace

- **Aviso grande (centro de la pantalla):** cuando una habilidad *acaba* de quedar disponible aparece grande durante 2 segundos con un destello y se desvanece.
- **Barra ofensiva (iconos pequeños):** habilidades que **hacen daño** y están disponibles **ahora**. Excepción: Cargar, Interceptar e Intervenir también van aquí. Si no se pueden usar, no aparecen.
- **Barra defensiva (debajo):** todo lo que **no hace daño**: defensivos, curación, generar ira (Rabia sangrienta, Ira rabiosa), control (Desarmar, Grito intimidador), interrupciones, provocar y potenciadores (Deseo de muerte, Temeridad, Golpes de barrido).

"Disponible" significa:
- el cooldown propio terminó (el GCD se ignora),
- estás en la postura correcta,
- se cumple su condición: Revancha tras bloquear/esquivar/parar, Ejecutar con el objetivo bajo 20 %, Abrumar, Ataque de la victoria, Embate solo con su proc instantáneo, etc.

Colores del icono: **azul** = falta ira, **rojo** = objetivo fuera de rango.

### Condiciones especiales

| Habilidad | Solo aparece si... |
|---|---|
| Golpe con escudo, Zurrar | el objetivo lanza algo interrumpible |
| Reflejo de hechizos | el objetivo te está lanzando un hechizo a ti |
| Provocar, Golpe burlón | el enemigo está pegando a otro |
| Cargar, Interceptar | el objetivo está a rango (ni muy lejos ni a menos de 8 m) |
| Intervenir | tienes un aliado como objetivo y está a rango |

Solo se muestran las habilidades que tu personaje conoce. Por defecto solo se ve en combate.

## Instalación

Versión actual: **0.4.0** (WoW 3.3.5a, probado en NaerZone).

1. En GitHub: **Code → Download ZIP** y descomprímelo.
2. Copia la carpeta `PvPKit` (está dentro de `pvp-addon-wotlk-main`) en `<carpeta del juego>\Interface\AddOns\`.
3. Entra al juego. Si ya estaba abierto, ciérralo y vuelve a abrirlo.
En la pantalla de personajes, en **AddOns**, marca "Cargar addons desactualizados" si hace falta.

## Comandos

| Comando | Qué hace |
|---|---|
| `/pvpkit` | Ayuda |
| `/pvpkit config` | Abrir la ventana de opciones (también con el botón del minimapa) |
| `/pvpkit unlock` / `lock` | Mover el aviso y las barras arrastrando |
| `/pvpkit test` | Muestra todas las habilidades durante 5 s |
| `/pvpkit size aviso\|ofensivas\|defensivas <px>` | Tamaño de los iconos |
| `/pvpkit max aviso\|ofensivas\|defensivas <n>` | Máximo de iconos |
| `/pvpkit pop <seg>` | Duración del aviso grande (por defecto 2) |
| `/pvpkit combat` | Ver solo en combate / siempre |
| `/pvpkit list` | Lista de habilidades numerada (blanco = conocida) |
| `/pvpkit toggle <n>` | Activar/desactivar una habilidad |
| `/pvpkit reset` | Configuración por defecto |

Se usa `/pvpkit` para no chocar con `/wa` de WeakAuras.

## Diagnóstico

WoW 3.3.5 no guarda los errores de Lua en un archivo. El addon guarda su propio registro (últimas 500 líneas). Por defecto **solo guarda los errores**, sin avisar en el chat. Para el registro completo, con el juego cerrado, poner `["debug"] = true` en `PvPKitDB` dentro del archivo de SavedVariables:

1. Jugar un rato.
2. `/reload` (o salir del juego) para que se escriba en disco.
3. Leer `WTF\Account\<CUENTA>\SavedVariables\PvPKit.lua`, en la sección `log`.

Con el registro completo, cada línea anota cuándo una habilidad cambia de estado y lo que dice el juego en ese momento (ira, cooldown, combate) y cada alerta nueva; los errores además se muestran en el chat.

Para ver los errores de Lua en pantalla: `/console scriptErrors 1`.

## Archivos

- `PvPKit.toc`: metadatos del addon (Interface 30300).
- `Warrior.lua`, `Shaman.lua`, `Mage.lua`, `Priest.lua`, `Rogue.lua`, `Druid.lua`, `Paladin.lua`, `Hunter.lua`, `Warlock.lua`, `DeathKnight.lua`: una por clase. Lista de habilidades (orden de prioridad, barra, condiciones, `kick` = sirve para ¡Córtalo!) y procs, registradas en `ns.classes[CLASE]`.
- `Racials.lua`: raciales comunes, se añaden al final de la lista de cada clase.
- `Core.lua`: lógica, dibujo, comandos y registro.
- `Alerts.lua`: alertas JcJ (por ahora solo el modo demostración).
- `Options.lua`: botón del minimapa (clic izquierdo abre la ventana, clic derecho activa/desactiva, arrastrar lo mueve) y ventana de opciones.

## Historial

- **v0.1:** iconos de habilidades listas en dos filas, con aviso previo con cuenta atrás.
- **Corrección:** los iconos no se dibujaban (error al poner texto sin fuente).
- **Rediseño:** el aviso grande dura 1 s y luego queda una sola barra con lo disponible. Se quitó la cuenta atrás.
- **Corrección:** el modo prueba se quedaba encendido; ahora se apaga solo a los 5 s.
- **Registro de diagnóstico** en SavedVariables. Verificado en el juego que Embate con escudo, Ola de choque, Arremetida de conmoción y Bloquear con escudo desaparecen al usarlos y vuelven con aviso al terminar su cooldown.
- **Ahora:**
  - el aviso grande dura 2 s,
  - la barra se separa en ofensiva y defensiva,
  - Cargar, Interceptar e Intervenir solo salen si el objetivo está a rango.
- **Clasificación:** ofensiva = hace daño (más Cargar, Interceptar e Intervenir); defensiva = no hace daño.
- **Botón de minimapa** con ventana para activar/desactivar.
- **Procs:** se muestran en el aviso grande mientras dura el buff (con destello al activarse). La lista está en el archivo de cada clase (`procs`); `minStacks` exige un mínimo de cargas (p. ej. Arma vorágine a 5).
- **Ventana de opciones, parte 1:** iconos de las habilidades conocidas y de los procs (Ofensivas, Defensivas, Procs). Un clic activa o desactiva cada uno; los desactivados se ven en gris. El tooltip muestra la descripción del hechizo.
- **Pestañas** en la ventana: General (activar/desactivar) y Habilidades (iconos).
- **Seleccionar/Deseleccionar todos** por sección (Ofensivas, Defensivas, Procs). El texto cambia según haya al menos una activa o ninguna.
- **Pestañas verticales** a la izquierda: General, Habilidades, Tamaños.
- **Tamaños:** deslizador de 4 posiciones XS (32), S (44), M (60) y L (80) para el aviso grande y cada barra. Se aplica al momento con vista previa de 5 s.
- **Posición:** botón Mover/Fijar barras para arrastrarlas a mano, también el bloque de alertas JcJ (mientras se mueven se ven todos los iconos y la demostración de alertas) y casilla Vertical por cada barra y el aviso. Se probó una cuadrícula 3x3 de zonas y un deslizador de alineación, pero se quitaron por preferencia.
- **General:** botón Restaurar configuración (con confirmación) que vuelve todo a los valores originales. La ventana siempre abre en General.
- **Funciones (pestaña General):** cada función se puede apagar por completo para no saturar la pantalla: aviso grande, procs, barra ofensiva, defensiva, favoritas y alertas JcJ.
- **Seleccionar todos / Deseleccionar todos** en cada lista de casillas (Funciones, Aliados, Enemigos). Las opciones aún no hechas salen en gris con "(pronto)".
- **Barra de favoritas:** en Habilidades, clic derecho en un icono lo marca con una estrella y lo mueve a una cuarta barra (Favoritas) en vez de la suya. Tiene su propio tamaño, posición y opción vertical. Los procs no pueden ser favoritos (van al aviso grande).
- **Perfiles (máximo 5):** abajo en la barra lateral se ve el perfil activo y el botón Cambiar perfil. Al pulsarlo se ocultan las pestañas y aparecen Volver y los perfiles como pestañas para cambiar; a la derecha están los botones para crear (Nuevo, con la configuración original), copiar el actual, borrar y cambiar de perfil. Cada personaje recuerda su perfil. Restaurar configuración afecta solo al perfil activo. La configuración anterior pasa sola al perfil "Default".
- **v0.2 - PvP Kit:** el addon pasa a llamarse PvP Kit (carpeta `PvPKit`, comando `/pvpkit` o `/pvk`). Detección de clase con un archivo por clase; se añadió el **chamán** (Estallido de lava, Golpe de tormenta, choques, Corte de viento, Totem de derribo, Maleficio, Ira chamanística, Mareas vivas, etc. y procs de Arma vorágine a 5 cargas y Oleadas). El botón del minimapa muestra el emblema de la clase detectada y su nombre (en su color) en el tooltip. La configuración se migró de WarriorReady.
- Los errores de la ventana de opciones se guardan en el registro. (Más tarde se quitó el comando `/pvpkit debug`: el registro está siempre activo.)
- **Raciales** añadidas a la barra defensiva (Furia sangrienta, Rabiar, Pisotón de guerra, Voluntad de los Renegados, Cada hombre por sí mismo, Forma de piedra, Artista del escape, Ofrenda de los naaru, Fusión de las sombras).

## Pendiente

- Confirmar Revancha, Ataque de la victoria y Reflejo de hechizos contra enemigos que ataquen.

## Ideas (por hacer)

- [x] Botón en el minimapa que abre una ventana para activar/desactivar el addon.
- [x] Mostrar los procs en el aviso grande mientras están activos (Espada y escudo, Oleada sangrienta, Muerte súbita, Sabor de sangre, Glifo de Revancha, Gigante).
- [ ] Ventana de opciones con iconos y sin comandos:
  - [x] tamaño de las barras: grande, mediano, pequeño, extra pequeño;
  - [x] posición de las barras;
  - [x] dirección horizontal o vertical;
  - [ ] alineación (probada y descartada por ahora);
  - [x] elegir qué habilidades rastrear.
- [x] Barra de habilidades favoritas.
- [x] Perfiles de configuración guardados.
- [x] Detección automática de clase (guerrero y chamán).
- [x] Replicar para todas las clases: listas de las 10 clases hechas (por probar en el juego cada una). Las habilidades de mascota (Bloqueo de hechizo, etc.) no se rastrean porque no están en el libro del jugador.
- [ ] Elegir la clase a mano (ahora solo detección automática): **por discutir y definir mejor**.
### Alertas JcJ (objetivo: ventaja en arena)

Vista elegida: **opción A**, iconos grandes en el centro con el nombre del jugador. Se configura en una pestaña **Alertas** con dos secciones, Aliados y Enemigos. Primero se hace un **modo demostración** (`/pvpkit demo`) con datos inventados para revisar la experiencia de uso; después, los datos reales.

Para probar sin equipo de arena: campos de batalla (controles, perjuicios y vida baja), duelos con un amigo (enemigos) y grupo con un amigo (aliados). El registro guarda lo que pasa.

- [x] Modo demostración (`/pvpkit demo`; el botón de la pestaña se quitó) y pestaña Alertas con casillas por sección y umbral de vida baja (solo visual). Fila Aliados y fila Enemigos en el centro-arriba; borde de color según el tipo (morado control, rojo perjuicio/vida, dorado inmune, gris abalorio, azul lanzando), barra que se vacía con la duración (sin números), DR en la esquina y "¡AHORA!" latiendo.
- [x] Cada alerta muestra la **cara** del jugador (si el juego la tiene: arena, grupo, objetivo, foco) junto al icono del efecto, con el emblema de la clase en la esquina; si no hay cara, el emblema de la clase ocupa su lugar. Tamaño de alertas XS/S/M/L en la pestaña Tamaños (vista previa con la demostración).
- [x] **Aliados (datos reales):** control (CC) mientras dure con quién lo puso, perjuicios importantes (reducción de curación, Aflicción inestable) y vida baja (umbral configurable), en grupo, banda o campo de batalla. Unos 65 controles de todas las clases, comparados por nombre (sirve cualquier rango). Máximo 6 alertas, ordenadas: control, vida baja, perjuicio. Por probar en el juego.
- [x] **Aliados - "Lo enfocan" (arena):** aliado (o tú) con 2 o más enemigos de arena apuntándole.
- [x] **Enemigos - control (CC):** los que pone tu grupo sobre jugadores enemigos, con quién lo puso, barra de duración si el enemigo es identificable (objetivo, foco, arena) y su DR en la esquina.
- [x] **¡Córtalo!:** cuando tu objetivo, foco o enemigo de arena (también PNJ) lanza algo, sale con la barra del lanzamiento; si se puede interrumpir y tu corte (Golpe con escudo, Zurrar, Corte de viento) está listo y a rango, sale en naranja latiendo "¡CÓRTALO! hechizo (tu corte)". Se puede apagar por separado: "Hechizo que lanza" y "¡Córtalo!".
- [x] **Enemigos - perjuicios y vida baja:** reducción de curación y Aflicción inestable sobre tu objetivo, foco o enemigos de arena, y su vida baja con umbral propio (10-50 %).
- [x] **Cooldowns del enemigo usados:** unos 55 cortes, defensivos, escapes y controles largos de todas las clases; sale "X usado" con la barra hasta que lo recupera (objetivo, foco o arena).
- [x] **Rendimientos decrecientes (DR)** (aproximado; categorías simplificadas, reinicio a los 18 s) por tipo de control sobre cada enemigo, para encadenar controles con el equipo. Ejemplo: el chamán aturde y tú lanzas tu aturdimiento justo al acabar, sabiendo si durará entero, la mitad o nada. Necesita la lista de controles de todas las clases.
- [x] **Abalorio JcJ del enemigo** (objetivo, foco o arena; 2 min): si ya lo usó y cuánto falta para que lo recupere.
- [x] **Inmunidades y defensivos activos del enemigo** (objetivo, foco o arena) (Escudo divino, Bloque de hielo, Capa de las Sombras, Caparazón antimagia, Reflejo de hechizos, Filotormenta...): "no gastes control ni hechizos ahora".
- [ ] **Ventana de muerte "¡AHORA!"** (sanador enemigo controlado y objetivo con poca vida): **por discutir** antes de hacerla.
- [x] **Cortes del enemigo:** incluidos en los cooldowns usados (Zurrar, Patada, Contrahechizo, Corte de viento, Helada mental...).
- [x] **Tótems enemigos:** Temblor, Derribador, Purificación y Marea de maná de cualquier chamán enemigo, hasta que muere o se acaba.
- [x] **Purgables:** solo si tienes Purgar, Disipar magia o Robar hechizo; Escudo de poder, Barrera de hielo, Mano de libertad/protección, Inervar, Infusión de poder, Venas heladas, Poder arcano, Escudo de tierra, Custodia de miedo.
- [x] **Enemigo bebiendo** (le falta maná: hay que presionar).
- [x] **Tu propio DR:** tras un control sale "Tú: Aturdido: siguiente ½" con la barra del reinicio, para decidir si usar tu abalorio.
