# Bluu - Swordburst 2

Modular cheat script for Swordburst 2 (Roblox game id `212154879`).
Split into one chunk per feature so no chunk ever hits Luau's 200-local
register limit.

## Load

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/z0mlg/Sb2Cheats/refs/heads/main/main.lua'))()
```

`main.lua` bootstraps shared state (services, respawn-synced character refs,
movement helpers, UI window) as globals, then downloads and runs each module
in order through `loadstring`.

## Layout

| File | Contains |
|---|---|
| `main.lua` | Bootstrap: stale-run guard, services (`Function`, `Event`, `RequiredServices`...), character/respawn refs, webhook helpers, Obsidian window, shared movement infra (`linearVelocity`, noclip, controls, waypoint part), module loader |
| `Modules/Waypoints.lua` | `WaypointSystem`, waypoint markers, per-floor config save/load, path farming |
| `Modules/Autofarm.lua` | Autofarm loop + offsets, assist mode, prioritize/ignore lists, **attack dodge** (danger zones from telegraph parts / `ReplicateSkill` args / touched hitboxes), radius + danger-zone visuals, waypoint toggle, floor-state restore |
| `Modules/Autowalk.lua` | Humanoid-based walking autofarm + pathfind mode |
| `Modules/Killaura.lua` | Killaura loop, skill system (`KillauraSkill`/`MiscSkill`), swing hooks, weapon equip tracking |
| `Modules/Cheats.lua` | Additional cheats (speed/fly/noclip/teleports/mob spawns) |
| `Modules/Misc.lua` | Misc tabbox: anim packs, zoom/stretch chat, equip-best, return-on-death, auto join |
| `Modules/ModsKicks.lua` | Misc tab: mod detector + farming kicks (kick webhook) |
| `Modules/ServerHop.lua` | Server switch / empty-server finder |
| `Modules/Items.lua` | Items box (unbox) + Players box (view/goto player) |
| `Modules/DropsSwing.lua` | Auto-dismantle, drop webhook, swing cheats |
| `Modules/Crystals.lua` | Trading / crystal counter & automation |
| `Modules/ESP.lua` | Player + mob ESP (Drawing + highlights, equip bars) |
| `Modules/Settings.lua` | Menu keybind, autoexec, unload, theme/config managers |
| `Modules/OMLFarm.lua` | Floor-9 target farm loop: farm targets, block+hop on players, teleport-reload |

## Dev

Set `DEV_LOCAL = true` and `DEV_PATH` at the top of `main.lua` to load
modules from disk (`readfile`) instead of GitHub while iterating.

To re-split from the monolith: `_split.py` lives outside this repo; the
source of truth for content is `Sb2-0mlg.lua`.
