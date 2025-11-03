# Age of War - Godot Edition

A streamlined lane-based strategy game built with Godot 4 and GDScript, inspired by the classic *Age of War*. Command your army, defend your base, and overwhelm the enemy stronghold through smart unit composition and resource management.

## Features

- Three distinct unit archetypes with unique stats and battlefield roles
- Passive gold income plus UI spawn buttons for player-controlled unit deployment
- AI opponent that dynamically spawns counters based on its current economy
- Base health bars, unit health bars, and a restartable match loop
- Stylized minimalist visuals rendered via custom GDScript draw calls (no external textures required)

## Project Layout

```
project.godot                # Godot project configuration
scenes/
  Main.tscn                  # Main scene with UI, timers, and battlefield setup
  Base.tscn                  # Base prefab with health tracking and drawing logic
  Unit.tscn                  # Generic combat unit prefab
scripts/
  main.gd                    # Game loop, economy, spawning, and UI handling
  base.gd                    # Base health + drawing
  unit.gd                    # Movement, combat logic, and unit rendering
```

## Getting Started

1. Install [Godot 4.2 or newer](https://godotengine.org/download).
2. Open the project folder (`project.godot`) inside Godot.
3. Run the main scene (`F6`) or the whole project (`F5`).

### Gameplay Notes

- Gold ticks in every second; spend it on Grunt, Ranger, or Tank units.
- Units automatically march toward the opposition, attacking enemies in range.
- Destroy the enemy base to claim victory. Use the restart button to reset the battlefield.

## Exporting for Web

1. In Godot, install the Web export templates if you haven't already.
2. Create an HTML5 export preset targeting `build/` (or another folder of your choice).
3. Export the project—Godot produces `.html`, `.wasm`, and `.pck` files.
4. Deploy those static files to your preferred host (e.g., Vercel, Netlify, GitHub Pages).

## License

Released as open source under the MIT License. Feel free to build on it, extend the ruleset, or port the gameplay into a larger project.
