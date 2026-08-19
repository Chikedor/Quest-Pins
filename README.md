# Quest Pins

Pin active quests to a compact HUD panel and get an in-game sound plus notification when you obtain an item still needed by one of them.

## English

### Features

- Adds a **Pin quest / Unpin quest** button to active quest details in the Journal.
- Keeps up to three quests visible in a compact panel on either side of the HUD.
- Places the panel on either side of the HUD and dynamically follows the visible vanilla HUD above it: money and essence on the right, or health, stamina, mana, and status effects on the left.
- Keeps long quest titles on one line and shortens them with an ellipsis when necessary.
- Shows the current objective and every progress row supported by the vanilla Journal, including backpack items and seal offerings.
- Keeps requirement names to one line and shortens long item names with an ellipsis so multi-item quests remain compact.
- Caps objectives at two lines in Compact mode and three lines at every other width, adding an ellipsis when needed so narrow panels do not become taller than wider ones.
- Adds a small mouse-clickable **X** to each HUD card so it can be unpinned without reopening the Journal.
- Shows a vanilla storage icon and the amount kept in player-owned chests when the required item is missing from the backpack.
- Marks active quests with stored required items in the Journal list and shows the exact stored items and quantities in their details, without requiring the quest to be pinned.
- Plays a subtle vanilla UI sound and shows a localized notification when a newly obtained item advances any active quest, whether pinned or not.
- Stores pinned quest keys in MMAPI's per-save sidecar; it does not alter the vanilla save.
- Supports mouse, keyboard, and controller navigation through the vanilla quest-detail pilot.
- Includes English and Spanish interface text.

### Screenshots

Pin or unpin an active quest directly from its Journal details:

![Pin quest button in the Journal](docs/images/pin-quest-journal.png)

Track several objectives and their live item progress from the game HUD:

![Three pinned quests displayed below the vanilla currency HUD](docs/images/pinned-quests-hud.png)

### Requirements

- Fields of Mistria 1.0.3 (Steam build 24742087)
- MOMI/MMAPI 0.15.5 or newer

### Installation

Copy only the [`quest_pins`](quest_pins) directory into the game's `mods` directory, apply the mod with MOMI, and start the game.

### Configuration

Open **Journal → Settings → Quest Pins** to choose among five balanced panel widths (112, 136, 160, 184, and 208 pixels), place it on the left or right, select whether item alerts cover all active quests or pinned quests only, and enable or disable sounds and notifications. All active quests are monitored by default, and changes are saved immediately.

## Español

### Funciones

- Añade un botón **Fijar misión / Desfijar misión** a los detalles de cada misión activa.
- Mantiene hasta tres misiones visibles en un panel compacto en cualquiera de los laterales del HUD.
- Permite colocar el panel en cualquier lateral y sigue dinámicamente el HUD vanilla visible sobre él: dinero y esencias a la derecha; salud, energía, maná y efectos de estado a la izquierda.
- Mantiene los títulos largos en una sola línea y los acorta con puntos suspensivos cuando es necesario.
- Muestra el objetivo actual y todas las filas de progreso compatibles con el Diario vanilla, incluidos los objetos de la mochila y las ofrendas de los sellos.
- Mantiene cada requisito en una sola línea y acorta con puntos suspensivos los nombres largos para que las misiones con muchos objetos sigan siendo compactas.
- Limita los objetivos a dos líneas en el modo Compacto y a tres en las demás anchuras, añadiendo puntos suspensivos cuando sea necesario para que un panel estrecho no termine siendo más alto que uno ancho.
- Añade una pequeña **X** pulsable con el ratón a cada tarjeta del HUD para desfijarla sin volver a abrir el Diario.
- Si falta un objeto en la mochila pero está guardado, muestra el icono vanilla de almacenamiento y la cantidad disponible en los cofres del jugador.
- Marca en la lista del Diario todas las misiones activas que tienen objetos necesarios guardados y muestra los objetos y cantidades en sus detalles, aunque la misión no esté fijada.
- Reproduce un sonido sutil del juego y muestra una notificación cuando un objeto recién obtenido ayuda a cualquier misión activa, esté fijada o no.
- Guarda las misiones fijadas por partida mediante el archivo auxiliar de MMAPI; no modifica el guardado original.
- Funciona con ratón, teclado y mando mediante la navegación vanilla del Diario.
- Incluye textos en inglés y español.

### Capturas

Fija o desfija una misión activa directamente desde sus detalles en el Diario:

![Botón para fijar una misión en el Diario](docs/images/pin-quest-journal.png)

Consulta varios objetivos y el progreso real de sus objetos desde el HUD del juego:

![Tres misiones fijadas debajo del indicador vanilla de dinero y esencias](docs/images/pinned-quests-hud.png)

### Instalación

Copia únicamente la carpeta [`quest_pins`](quest_pins) dentro de `mods`, aplica el mod con MOMI e inicia el juego.

### Requisitos

- Fields of Mistria 1.0.3 (Steam build 24742087)
- MOMI/MMAPI 0.15.5 o posterior

### Uso

1. Abre **Diario → Misiones**.
2. Selecciona una misión activa.
3. Pulsa **Fijar misión** bajo sus objetivos.
4. Cierra el Diario: el objetivo queda visible en el lateral elegido.
5. Al obtener un objeto que aún falta para cualquier misión activa, aparece el aviso y suena una confirmación breve; no es necesario fijarla.

Las misiones completadas se eliminan automáticamente del panel. El indicador de cofres no cuenta el buzón de envíos, máquinas ni almacenes que no pertenecen al jugador. El aviso de objetos se limita a requisitos estructurados `has_item`; no intenta deducir objetivos leyendo texto traducido.

### Configuración

Abre **Diario → Ajustes → Quest Pins** para elegir entre cinco anchuras equilibradas —112, 136, 160, 184 y 208 píxeles—, colocar el panel a la izquierda o a la derecha, decidir si los avisos cubren todas las misiones activas o solo las fijadas, y activar o desactivar el sonido y las notificaciones. De forma predeterminada se vigilan todas las misiones activas. Los cambios se guardan inmediatamente.
