# PvP Kit

Addon para **World of Warcraft 3.3.5a (WotLK)**, probado en el servidor NaerZone con cliente en español.
Ayuda visual para JcJ: muestra qué habilidades están listas para usar y los procs activos, al estilo de WeakAuras pero sin configurar nada. Detecta la clase del personaje y carga su lista de habilidades.

**Clases:** Guerrero (probado), Chamán (en prueba). Plan: probar cada función con estas dos clases y, al final, replicar para todas las demás.

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

Copia la carpeta `PvPKit` dentro de `<carpeta del juego>\Interface\AddOns\` y entra al juego (o escribe `/reload`).
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
| `/pvpkit debug` | Registro de diagnóstico on/off |
| `/pvpkit reset` | Configuración por defecto |

Se usa `/pvpkit` para no chocar con `/wa` de WeakAuras.

## Diagnóstico

WoW 3.3.5 no guarda los errores de Lua en un archivo. El addon guarda su propio registro:

1. `/pvpkit debug` para activarlo.
2. Jugar un rato.
3. `/reload` (o salir del juego) para que se escriba en disco.
4. Leer `WTF\Account\<CUENTA>\SavedVariables\PvPKit.lua`, en la sección `log`.

Cada línea anota cuándo una habilidad cambia de estado y lo que dice el juego en ese momento (ira, cooldown, combate). Los errores del addon también se guardan ahí y se muestran en el chat.

Para ver los errores de Lua en pantalla: `/console scriptErrors 1`.

## Archivos

- `PvPKit.toc`: metadatos del addon (Interface 30300).
- `Warrior.lua`, `Shaman.lua`: una por clase. Lista de habilidades (orden de prioridad, barra y condiciones) y procs, registradas en `ns.classes[CLASE]`. Para añadir una clase basta con crear su archivo y añadirlo al `.toc`.
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
- **Posición:** botón Mover/Fijar barras para arrastrarlas a mano (mientras se mueven se ven todos los iconos) y casilla Vertical por cada barra y el aviso. Se probó una cuadrícula 3x3 de zonas y un deslizador de alineación, pero se quitaron por preferencia.
- **General:** botón Restaurar configuración (con confirmación) que vuelve todo a los valores originales. La ventana siempre abre en General.
- **Barra de favoritas:** en Habilidades, clic derecho en un icono lo marca con una estrella y lo mueve a una cuarta barra (Favoritas) en vez de la suya. Tiene su propio tamaño, posición y opción vertical. Los procs no pueden ser favoritos (van al aviso grande).
- **Perfiles (máximo 5):** abajo en la barra lateral se ve el perfil activo y el botón Cambiar perfil. Al pulsarlo se ocultan las pestañas y aparecen Volver y los perfiles como pestañas para cambiar; a la derecha están los botones para crear (Nuevo, con la configuración original), copiar el actual, borrar y cambiar de perfil. Cada personaje recuerda su perfil. Restaurar configuración afecta solo al perfil activo. La configuración anterior pasa sola al perfil "Default".
- **v0.2 - PvP Kit:** el addon pasa a llamarse PvP Kit (carpeta `PvPKit`, comando `/pvpkit` o `/pvk`). Detección de clase con un archivo por clase; se añadió el **chamán** (Estallido de lava, Golpe de tormenta, choques, Corte de viento, Totem de derribo, Maleficio, Ira chamanística, Mareas vivas, etc. y procs de Arma vorágine a 5 cargas y Oleadas). El botón del minimapa muestra el emblema de la clase detectada y su nombre (en su color) en el tooltip. La configuración se migró de WarriorReady.
- Los errores de la ventana de opciones se guardan en el registro aunque `/pvpkit debug` esté apagado.
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
- [ ] Replicar para todas las clases (al final, cuando todo esté probado).
### Alertas JcJ (objetivo: ventaja en arena)

Vista elegida: **opción A**, iconos grandes en el centro con el nombre del jugador. Se configura en una pestaña **Alertas** con dos secciones, Aliados y Enemigos. Primero se hace un **modo demostración** (`/pvpkit demo`) con datos inventados para revisar la experiencia de uso; después, los datos reales.

Para probar sin equipo de arena: campos de batalla (controles, perjuicios y vida baja), duelos con un amigo (enemigos) y grupo con un amigo (aliados). El registro guarda lo que pasa.

- [x] Modo demostración (`/pvpkit demo` o botón "Ver demostración") y pestaña Alertas con casillas por sección y umbral de vida baja (solo visual). Fila Aliados y fila Enemigos en el centro-arriba; borde de color según el tipo (morado control, rojo perjuicio/vida, dorado inmune, gris abalorio, azul lanzando), barra que se vacía con la duración (sin números), DR en la esquina y "¡AHORA!" latiendo.
- [ ] **Aliados:** control (CC) mientras dure, perjuicios importantes, vida baja (umbral configurable).
- [ ] **Aliados:** "lo están enfocando". Solo es fiable en arena: el juego solo da el objetivo de los enemigos de arena o del objetivo/foco.
- [ ] **Enemigos:** control (CC) con quién lo puso y cuánto le queda; perjuicios; vida baja (para rematar); hechizo que está lanzando.
- [ ] **Rendimientos decrecientes (DR)** por tipo de control sobre cada enemigo, para encadenar controles con el equipo. Ejemplo: el chamán aturde y tú lanzas tu aturdimiento justo al acabar, sabiendo si durará entero, la mitad o nada. Necesita la lista de controles de todas las clases.
- [ ] **Abalorio JcJ del enemigo:** si ya lo usó y cuánto falta para que lo recupere.
- [ ] **Inmunidades y defensivos activos del enemigo** (Escudo divino, Bloque de hielo, Capa de las Sombras, Caparazón antimagia, Reflejo de hechizos, Filotormenta...): "no gastes control ni hechizos ahora".
- [ ] **Ventana de muerte:** sanador enemigo controlado y objetivo con poca vida, sale "¡AHORA!".
- [ ] **Cortes del enemigo:** cuándo tiene listos Zurrar, Patada, Contrahechizo, etc. (sobre todo para el chamán sanador).
- [ ] **Tótems enemigos:** Tótem de temblor (tu miedo no sirve) o Tótem derribador (no lances hechizos), para matarlo.
- [ ] **Purgables:** beneficios del enemigo que el chamán puede purgar.
- [ ] **Sanador enemigo bebiendo** (le falta maná: hay que presionar).
- [ ] **Tu propio DR:** si el próximo control que recibas será completo, la mitad o nada, para decidir si usar tu abalorio.
