# WarriorReady

Addon para **World of Warcraft 3.3.5a (WotLK)**, probado en el servidor NaerZone con cliente en español.
Ayuda visual para el guerrero: muestra qué habilidades están listas para usar, al estilo de WeakAuras pero sin configurar nada.

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

Copia la carpeta `WarriorReady` dentro de `<carpeta del juego>\Interface\AddOns\` y entra al juego (o escribe `/reload`).
En la pantalla de personajes, en **AddOns**, marca "Cargar addons desactualizados" si hace falta.

## Comandos

| Comando | Qué hace |
|---|---|
| `/wready` | Ayuda |
| `/wready config` | Abrir la ventana de opciones (también con el botón del minimapa) |
| `/wready unlock` / `lock` | Mover el aviso y las barras arrastrando |
| `/wready test` | Muestra todas las habilidades durante 5 s |
| `/wready size aviso\|ofensivas\|defensivas <px>` | Tamaño de los iconos |
| `/wready max aviso\|ofensivas\|defensivas <n>` | Máximo de iconos |
| `/wready pop <seg>` | Duración del aviso grande (por defecto 2) |
| `/wready combat` | Ver solo en combate / siempre |
| `/wready list` | Lista de habilidades numerada (blanco = conocida) |
| `/wready toggle <n>` | Activar/desactivar una habilidad |
| `/wready debug` | Registro de diagnóstico on/off |
| `/wready reset` | Configuración por defecto |

Se usa `/wready` para no chocar con `/wa` de WeakAuras.

## Diagnóstico

WoW 3.3.5 no guarda los errores de Lua en un archivo. El addon guarda su propio registro:

1. `/wready debug` para activarlo.
2. Jugar un rato.
3. `/reload` (o salir del juego) para que se escriba en disco.
4. Leer `WTF\Account\<CUENTA>\SavedVariables\WarriorReady.lua`, en la sección `log`.

Cada línea anota cuándo una habilidad cambia de estado y lo que dice el juego en ese momento (ira, cooldown, combate). Los errores del addon también se guardan ahí y se muestran en el chat.

Para ver los errores de Lua en pantalla: `/console scriptErrors 1`.

## Archivos

- `WarriorReady.toc`: metadatos del addon (Interface 30300).
- `Spells.lua`: lista de habilidades, orden de prioridad, barra y condiciones. Para añadir una habilidad basta con agregar su spell ID aquí.
- `Core.lua`: lógica, dibujo, comandos y registro.
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
- **Procs:** se muestran en el aviso grande mientras dura el buff (con destello al activarse). La lista está en `ns.procs`, en `Spells.lua`.
- **Ventana de opciones, parte 1:** iconos de las habilidades conocidas y de los procs (Ofensivas, Defensivas, Procs). Un clic activa o desactiva cada uno; los desactivados se ven en gris. El tooltip muestra la descripción del hechizo.
- **Pestañas** en la ventana: General (activar/desactivar) y Habilidades (iconos).
- **Seleccionar/Deseleccionar todos** por sección (Ofensivas, Defensivas, Procs). El texto cambia según haya al menos una activa o ninguna.
- **Pestañas verticales** a la izquierda: General, Habilidades, Tamaños.
- **Tamaños:** deslizador de 4 posiciones XS (32), S (44), M (60) y L (80) para el aviso grande y cada barra. Se aplica al momento con vista previa de 5 s.
- **Posición:** cuadrícula 3x3 por cada barra y el aviso (TL, T, TR, L, M, R, BL, B, BR) que coloca el elemento en ese punto de la pantalla, con márgenes para no tapar los marcos del juego (minimapa, chat, barras de acción, retratos). Si varios elementos eligen la misma zona se apilan. También: casilla Vertical, deslizador de alineación (se ajusta solo al elegir zona) y botón Mover/Fijar barras para ajustar a mano.
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
  - [x] alineación: izquierda, centro, derecha / arriba, centro, abajo;
  - [x] elegir qué habilidades rastrear.
- [ ] Tercera barra de habilidades favoritas.
- [ ] Perfiles de configuración guardados.
- [ ] Soporte para más clases, con elección de clase y detección automática.
- [ ] Mostrar en grande cuando un aliado tiene un control (CC), mientras le dure.
- [ ] Mostrar en grande cuando un jugador enemigo lanza un hechizo, o qué habilidades tiene disponibles.
