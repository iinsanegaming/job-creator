# Job & Gang Creator for RedM RSG-Core

> Created by **iiNSANE Gaming** for RSG-Core servers.

NUI-based creator for jobs and gangs. Create and edit jobs/gangs with grades; they are registered with RSG-Core via `AddJob` / `AddGang` and persisted in `data/jobs_gangs.json`.

## Requirements

- **RedM** with **RSG-Core** (rsg-core)
- Resource name: must match what you use in `ensure` (e.g. `job-creator` or your folder name)
- **Do not run old boss/gang menu resources at the same time.** If you previously used `rsg-bossmenu` or `rsg-gangmenu`, you should **remove or comment out** their `ensure` lines in `server.cfg` so you do not get duplicate prompts and menus.

## Installation

1. Copy the `job-creator` folder into your server `resources` directory.
2. Rename the folder if you want; the folder name is the resource name (e.g. `job-creator`).
3. Add to `server.cfg`:
   ```cfg
   ensure rsg-core
   ensure job-creator
   ```
4. In `config.lua`, set **Config.AllowedCitizenIds** to your character's CitizenID (e.g. `{ 'BP027508' }`). The creator is locked to these characters; others will see "This is locked to specific characters" if they try the command.

## Usage

- **Command:** `/jobcreator` (or whatever you set in `config.lua` as `Config.OpenCommand`). Only characters whose citizenid is in `Config.AllowedCitizenIds` can open the creator.
- **Keybind (optional):** you can configure a key in `config.lua` as `Config.OpenKey = 'F7'`. Set `Config.OpenKey = nil` if you only want the command.

## Config (`config.lua`)

| Option            | Description |
|-------------------|-------------|
| `OpenCommand`     | Command to open the NUI (default `jobcreator`) |
| `OpenKey`         | Optional key to open (e.g. `F7`). Set to `nil` to disable and use only the command. |
| `AllowedCitizenIds` | **Lock to character:** only these citizenids can open the creator and place boss/gang locations. e.g. `{ 'BP027508' }`. Empty `{}` = everyone. |
| `DataFile`        | Path to JSON file for custom jobs/gangs (default `data/jobs_gangs.json`) |
| `DefaultJobType`  | Default job type for new jobs (e.g. `none`, `law`, `medic`) |
| `DefaultDuty`     | New jobs default on duty |
| `OffDutyPay`      | New jobs get pay when off duty |
| `ShowBossMenuButton` | Show "Boss Menu" button in the creator. Set `false` to hide. |
| `ShowGangMenuButton` | Show "Gang Menu" button in the creator. Set `false` to hide. |
| `Config.BossMenu`    | Boss menu settings: `Keybind`, `BossLocations`, `Blip`, `StorageMaxWeight`, `StorageMaxSlots`. |
| `Config.GangMenu`    | Gang menu settings: `Keybind`, `GangLocations`, `Blip`, `StorageMaxWeight`, `StorageMaxSlots`. |

## Built-in Boss Menu & Gang Menu

This resource includes **Boss Menu** and **Gang Menu** built in (you **do not** need the standalone `rsg-bossmenu` or `rsg-gangmenu` resources). In fact, if you leave those old resources running you will see duplicate prompts/menus. Make sure they are **stopped/removed** in `server.cfg` when using this script.

Locations are configured via the in-game **Locations** tab (NUI), which saves to `data/boss_gang_locations.json`. You can also set fallback locations in **config.lua**:

- **Config.BossMenu.BossLocations** – fallback list of `{ id, name, coords = vector3(x,y,z), showblip }` where job bosses can open the boss menu (employees, hire, stash, society) if the locations file is missing.
- **Config.GangMenu.GangLocations** – fallback list of `{ id, name, blipname, coords, showblip, blipforall }` where gang bosses can open the gang menu if the locations file is missing.

The creator UI has **Boss Menu** and **Gang Menu** buttons that close the creator and open the same menus. Gang bosses can also use the **/gangmenu** command.

**Requirements:** ox_lib, oxmysql, rsg-inventory. Run **jobcreator.sql** once to create the `management_funds` table for society money.

## How it works

- **Jobs** and **Gangs** from RSG-Core are read on open and shown in the list. You can create **new** jobs/gangs or edit existing ones (including those from rsg-core).
- **Custom** entries are saved to `data/jobs_gangs.json` and re-registered on resource start so they persist across restarts.
- **Grades**: each job/gang has grades with level, name, payment, and boss flag. At least one grade is required.
- **Delete** only removes the job/gang from the custom list and file; it is not unregistered until you restart the resource (RSG-Core does not provide RemoveJob/RemoveGang).

## File structure

```
job-creator/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── main.lua
├── server/
│   └── main.lua
├── html/
│   ├── index.html
│   ├── style.css
│   └── script.js
├── data/
│   └── jobs_gangs.json
└── README.md
```

## Notes

- Job and gang **names** are lowercased and spaces removed (used as IDs).
- Existing RSG-Core jobs/gangs are loaded from `RSGCore.Shared.Jobs` and `RSGCore.Shared.Gangs`. Editing and saving them updates the shared tables and the custom file so they stay after restart.
