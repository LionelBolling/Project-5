# Project 5

A base 2D Godot game. Move with **W A S D** and reset with **R**.

The heading reads **Project 5 In Progress**.

## Play

GitHub Pages: https://lionelbolling.github.io/Project-5/

The web export is in `docs/`. Enable GitHub Pages using **Deploy from a branch**, the published branch, and the **/docs** folder.

## Paper Tactics update log

- **Tutorial** — Added two wizard-led practice battles before Stage 1. The tutorial teaches players to buy, select, and place a unit, start combat, time a spell with Space, buy XP, purchase and equip items, merge, and collect loot. **Skip Tutorial** takes players straight to the regular game.
- **Combat and difficulty** — Clarified the Space spell timing prompt, eased round difficulty scaling, added unit footprints and gameplay tips, and gave battles a forest backdrop.
- **Shop and preparation** — Added shop unit previews, made merging optional, and added a preparation guide with previews of enemy formations and round gold.
- **Interface** — Polished the game UI and animated in-game notifications.
- **Title screen** — Replaced the scrolling forest duels with a still campfire sketch. The knight toasts a marshmallow, the wizard holds a glowing orb, and the archer sharpens an arrow. The artwork and title stay still. Play highlights in place, and Enter starts the game.
- **Web build** — Rebuilt the web game pack and verified that it starts in Godot headless. The build is on the `Game-Changes` branch at commit `106e802`.

## Develop and export

Open `project.godot` in Godot 4.7.2. Run the main scene, or export the **Web** preset to `docs/index.html`. Install the matching Godot web export templates first. The export uses a single thread, so GitHub Pages can serve it without special cross-origin headers.

Serve `docs/` using an HTTP server to test locally; opening `index.html` as a file will not load the game.

