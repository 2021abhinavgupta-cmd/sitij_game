# Pokemon FireLeaf (Rare Encounter) — Godot project

GBA-style overworld + battle minigame. Godot 4.4.1, GDScript. Deployed to Railway
(`https://sitijgame-production.up.railway.app`), auto-redeploys on push to `main`
on `git@github.com:2021abhinavgupta-cmd/sitij_game.git`. **Test exclusively via
the deployed browser build**, not the native `.exe` — Railway build+export takes
a few minutes after push, so a stale-looking screenshot right after pushing is
usually just deploy lag, not a bug. Hard-refresh (Ctrl+Shift+R) and wait before
re-diagnosing.

## Structure

- `game/source/maps/overworld/overworld.tscn` — single persistent scene containing
  ALL areas (PalletTown, PlayerHouse1F/2F, Ghatkopar, RCityMall, Office) as
  always-present siblings, spatially offset via `Node2D.position`. "Areas" are
  simulated by swapping `player.ground`/`upper_ground` and camera clamp limits,
  not by loading/unloading scenes.
- `game/source/battle/battle_encounter.gd` / `.tscn` — battle minigame: HP bars,
  dialog box, action menu (CONFRONT/ATTACK/OVERTHINK/RUN), CONFRONT quiz.
- `game/source/title_screen/rare_encounter_title.tscn` — "Rare Encounter" title
  screen, START button boots into `overworld.tscn`. Currently `run/main_scene`.
- `game/source/maps/common/warper/warper.gd` — custom warp system between areas.
- `game/source/player/player.gd` — movement, grid snapping, area-enter banner.

## Known gotchas (bit us more than once this session)

- **`TextureRect.expand_mode`**: any time you assign a texture/AtlasTexture to a
  `TextureRect` and want the node smaller than the source pixels, you MUST set
  `expand_mode = 1` (`EXPAND_IGNORE_SIZE`). Without it Godot inflates the
  Control's minimum size to the full source texture dimensions, blowing up the
  whole layout regardless of explicit offsets.
- **Pixel font floor**: `assets/fonts/pokemon-firered-leafgreen-font.otf` breaks
  (overlapping glyphs) below `font_size = 6`. Safe range: 6–8 body text, up to 15
  for a short single-line title. Need something smaller? Don't drop font size —
  wrap the nodes in a `Control` and apply a `scale` transform instead (see
  `EnemyHUD`/`PlayerHUD` in `battle_encounter.tscn`, scale `0.78`).
- **Font glyph coverage**: this font has gaps — an unsupported Unicode char (e.g.
  `★`) renders as a literal codepoint-hex tofu box, not a missing-glyph square.
  Verify any decorative character actually exists in the font, or avoid it.
- **`Warper.target_area`**: must point to the warper's OWN destination-side area
  (its eventual parent map_root), not the source area. `warp_player()` runs with
  `self` as the destination warper, reading `self.target_area` — get this
  backwards and every warp binds the wrong tilemap/camera.
- **Scene-tree draw order**: same-`z_index` siblings paint in child declaration
  order, not spatial position. In this single-scene-many-areas design, a node's
  position among Root's children determines paint order across otherwise
  spatially-distant areas (e.g. Player declared before Ghatkopar/RCityMall/Office
  got fully occluded — fix was reordering Player to be the last root child).
- **Camera bleed / overflow reveals neighboring areas**: if a room's own tile
  extent is smaller than the 240×160 viewport, the camera clamped to that room's
  bounds will show past its edges. If that room sits at a small nested offset
  *inside* another area's coordinate space (rather than isolated far away), the
  overflow reveals that other area's real content. Fix: isolate small/self-
  contained areas at remote coordinates, matching the existing convention
  (Ghatkopar=5000, RCityMall=8000, Office=11000, PlayerHouse1F/2F=-3000).
- **Web export click-coordinate mapping**: `window/stretch/mode="canvas_items"` +
  `scale_mode="integer"` means the `<canvas>` CSS rect is larger than the actual
  rendered viewport (letterboxed/centered). Synthetic clicks must account for
  `scale = floor(min(cssW/240, cssH/160))` and the center offset, or clicks land
  off-target. See the dev-loop below for the working helper.

## Local dev/verify loop (used for every visual change before pushing)

1. Temporarily set `game/project.godot`'s `run/main_scene` to the scene under test.
2. `Godot_v4.4.1-stable_win64_console.exe --headless --path game --import`
3. `Godot_v4.4.1-stable_win64_console.exe --headless --path game --export-release "Web" <out>/index.html`
4. Serve locally: `python3 -m http.server 8791` from the export output dir.
5. Use chrome-devtools MCP: `navigate_page` (reload, `ignoreCache: true`),
   `take_screenshot`, and `evaluate_script` for clicks (install a `__clickAt(lx, ly)`
   helper that maps logical 240×160 coords through the integer-scale/letterbox
   math above before dispatching `mousedown`/`mouseup`/`click` on the canvas).
6. Revert `run/main_scene` before committing.
7. Re-run the headless `--import` once more as a final smoke test (catches
   GDScript syntax errors) before `git commit`/`git push`.

Godot executable location changes between sessions/machines — if the previously
known path 404s, search: `Get-ChildItem -Path 'C:\','D:\' -Filter 'Godot*.exe'
-Recurse -Depth 6`.

## Known intentional / current design notes

- `courage_stat` doubles as Abhinav's/YOUNG KSHITIJ's displayed "level" in his HP box.
- ATTACK always shows `"OLD KSHITIJ used AI!\n-99 HP"` flavor text (not tied to
  real damage math — real HP math lives in the `pending_damage`/`ATTACK_DAMAGE` flow).
- CONFRONT is a trivia quiz (`QUESTIONS` array in `battle_encounter.gd`): correct
  answers damage `crush_hp`, wrong answers damage `player_hp` AND repeat the same
  question (`quiz_index` only advances on a correct answer) — the quiz won't move
  on until you get it right.
- `LosePanel`'s QUIT button flees on hover — unclickable by design.
