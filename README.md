# Quest Pins

Pin active quests to a compact HUD panel and get an in-game sound plus notification when you obtain an item still needed by one of them.

## English

### Features

- Adds a **Pin quest / Unpin quest** button to active quest details in the Journal.
- Keeps up to three quests visible in a compact panel on the right side of the HUD.
- Places the panel immediately below the vanilla money and essence display.
- Keeps long quest titles on one line and shortens them with an ellipsis when necessary.
- Shows the current objective and live inventory progress for `has_item` requirements.
- Plays a subtle vanilla UI sound and shows a localized notification when a newly obtained item advances a pinned quest.
- Stores pinned quest keys in MMAPI's per-save sidecar; it does not alter the vanilla save.
- Supports mouse, keyboard, and controller navigation through the vanilla quest-detail pilot.
- Includes English and Spanish interface text.

### Screenshots

Pin or unpin an active quest directly from its Journal details:

![Pin quest button in the Journal](docs/images/pin-quest-journal.png)

Track several objectives and their live item progress from the game HUD:

![Three pinned quests displayed below the vanilla currency HUD](docs/images/pinned-quests-hud.png)

### Requirements

- Fields of Mistria 1.0.x (developed against 1.0.2, Steam build 24619420)
- MOMI/MMAPI 0.15.1 or newer

### Installation

Copy only the [`quest_pins`](quest_pins) directory into the game's `mods` directory, apply the mod with MOMI, and start the game.

### Configuration

Open **Journal → Settings → Quest Pins** to choose a small, medium, or large tracker and to enable or disable item sounds and notifications. Changes are saved immediately.

## Español

### Funciones

- Añade un botón **Fijar misión / Desfijar misión** a los detalles de cada misión activa.
- Mantiene hasta tres misiones visibles en un panel compacto en el lateral derecho del HUD.
- Coloca el panel justo debajo del indicador vanilla de dinero y esencias.
- Mantiene los títulos largos en una sola línea y los acorta con puntos suspensivos cuando es necesario.
- Muestra el objetivo actual y el progreso real del inventario para requisitos de objetos.
- Reproduce un sonido sutil del juego y muestra una notificación cuando un objeto recién obtenido ayuda a una misión fijada.
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

### Uso

1. Abre **Diario → Misiones**.
2. Selecciona una misión activa.
3. Pulsa **Fijar misión** bajo sus objetivos.
4. Cierra el Diario: el objetivo queda visible en el lateral derecho.
5. Al obtener un objeto que aún falta para esa misión, aparece el aviso y suena una confirmación breve.

Las misiones completadas se eliminan automáticamente del panel. El aviso de objetos se limita a requisitos estructurados `has_item`; no intenta deducir objetivos leyendo texto traducido.

### Configuración

Abre **Diario → Ajustes → Quest Pins** para elegir un panel pequeño, mediano o grande y activar o desactivar el sonido y las notificaciones de objetos. Los cambios se guardan inmediatamente.
