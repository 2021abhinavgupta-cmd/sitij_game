# Rare Encounter

A small top-down Godot 4.4.1 demo: walk through a City block, into a Mall, down
to an Office, and interact with an NPC at the back to trigger a GBA-style
battle minigame.

Started as a fork of [SlayHorizon's Pokémon FireLeaf](https://github.com/SlayHorizon/pokemon-fireleaf-godot)
— the player movement, camera, and scene-warp mechanics are kept from that
project (see [LICENSE](./LICENSE), MIT). Everything else — the City/Mall/Office
maps, tilesets, the battle scene, and the NPC — is original content built on
top of that base; no Pokémon assets, branding, or code remain in this repo.

## Run locally

Open `game/` in the [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) editor and press Play, or from the CLI:

```
godot --path game
```

Controls: arrow keys to move, Enter/Space to interact or advance dialog, Esc to leave a win/lose screen.

## Structure

- `game/source/player/` — player controller + camera (from the original project, unchanged).
- `game/source/maps/common/warper/` — scene-transition trigger (`Area2D`, from the original project; extended with an optional `target_area` so warps between fully separate areas — City/Mall/Office each have their own `Ground`/`UpperGround` `TileMapLayer` pair — keep working collision).
- `game/source/maps/city_demo/` — the City/Mall/Office scene and its two tilesets ([Kenney](https://kenney.nl) CC0 packs — see [THIRD_PARTY_ASSETS.md](./THIRD_PARTY_ASSETS.md)).
- `game/source/npc/` — the interactable NPC that starts the battle.
- `game/source/battle/` — the battle minigame (dialog box, HP bars, action menu, win/lose screens).

## Deploying (Railway)

`Dockerfile` builds a Godot Web (HTML5/WASM) export and serves it via Caddy.
Push to a repo connected to Railway and it builds from the `Dockerfile`
automatically (see `railway.toml`) — no local export step needed.
