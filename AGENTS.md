# AGENTS.md

Personal Windows PowerShell 5.1 scripts, public on GitHub (`crazyrabbit0/PowerShell`, branch `main`). Each `.ps1` is standalone and runs from double-click, drag-and-drop or the Send To menu. `README.md` lists every script.

## Script template

Most scripts share one skeleton; follow it for new ones:

- Banner sections: `############################## GLOBALS | VARIABLES | MAIN CODE | FUNCTIONS | RUN MAIN CODE ##############################`.
- Globals: `$global:debug = 0`, `$global:display = 'Normal'|'Minimized'`, `$global:title = '<window title>'`, `$global:args = $args` (`Windows Repair.ps1` uses `$global:script_args`).
- `function main { ... }` called at the bottom; helpers are copied into each file, not imported: `run_as_admin` (re-launch elevated), `show_title`, `list_item`, `check_mark`, `finish [-restart]`.
- `if ($global:debug) { ... }` guards debug output; leave `$global:debug = 0` in commits.
- GUI scripts (`Windows Repair`, `Adobe Fixes`, `Reset AnyDesk ID`) build WinForms windows from a `$views` table of fonts/colours.

## Rules

- Target Windows PowerShell 5.1 (`powershell.exe`), not PowerShell 7: no `?:`, `??`, `&&`.
- Five files carry a UTF-8 BOM (`Adobe Fixes`, `Black Screen`, `Clear Temp`, `Ganian App (VPN)`, `Reset AnyDesk ID`) so PS 5.1 reads their non-ASCII text; keep a BOM on any script with non-ASCII characters. `Ganian App (VPN).ps1` is in Greek.
- `Headphone Service Task.xml` is UTF-16 (Task Scheduler export) and marked `-text`; `.lnk` files are binary templates.
- Personal paths go through `$env:cr` (default `C:\CR`).
- Indentation is tabs in most files; keep each file's own style.

## Checking a change

- CI (`.github/workflows/parse.yml`) parses every `.ps1` with the PowerShell 5.1 parser on `windows-latest`. Locally: `[System.Management.Automation.Language.Parser]::ParseFile(<path>, [ref]$null, [ref]$errors)`, and `$errors` must be empty.
- These scripts change the registry, services and licensing; never run one to "test" it. Ask the user to run it.

## Commits

Conventional Commits with a script scope, e.g. `feat(windows): ...`, `fix(sync): ...`, `chore: ...`. Update the README table when a script is added, removed or changes purpose. Text files are LF (`.gitattributes`).
