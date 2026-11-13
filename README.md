# PowerShell

Personal Windows PowerShell scripts for Windows maintenance, fixes and file tools. Most take a file or folder as their argument, so they work well from the **Send To** menu or by dragging files onto them.

## Usage

1. Allow local scripts once: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` (or run `Run .ps1 files with PowerShell.ps1`, which also adds double-click, drag-and-drop and *Run as administrator* to `.ps1` files).
2. Run a script by double-clicking it, dropping files onto it, or from a shortcut in `shell:sendto`.
3. Scripts that change the system re-launch themselves as administrator.

`.Script Shortcut.lnk` and `.Hidden Script Shortcut.lnk` are templates: copy one, rename `Script.ps1` in its target to the script you want, and the hidden one runs without a console window.

> These scripts change the registry, services, permissions and licensing. Read a script before running it.

## Scripts

### Windows

| Script | What it does |
|---|---|
| `Windows Repair.ps1` | Checklist window that runs Disk Cleanup, `chkdsk`, DISM, `sfc` and disk optimisation, reporting what it could not fix. |
| `AutoLogin.ps1` | Toggles Windows Hello's passwordless-only sign-in, which hides the "users must enter a password" checkbox, then opens `netplwiz` so automatic sign-in can be set. |
| `Convert Windows 10 Home to Pro.ps1` | Starts the licensing services and applies the generic Windows 10 Pro key with `changepk`. |
| `Clear KMS Hosts & Keys.ps1` | Uninstalls the product key and clears the KMS host and key from the registry. |
| `Reset Alt+Tab Functionality.ps1` | Switches `Alt+Tab` between the old (icons only) and the default switcher. |
| `Hyper-V Port Reservations Fix.ps1` | Moves the dynamic TCP port range to 49152+ so Hyper-V stops reserving ports in the 3000-8000 range. |
| `Set Environment Variables.ps1` | Creates short environment variables (`%cr%`, `%s2%`, `%su%`, `%ap%`) for common folders. |
| `Run .ps1 files with PowerShell.ps1` | Sets the execution policy and fixes how `.ps1` files open, look and accept dropped files. |
| `Add to Startup.ps1` | Adds the dropped program to, or removes it from, `HKCU\...\Run`. |
| `Restart Cast Service.ps1` | Restarts the Wi-Fi Direct, device association and device picker services and the wireless adapter so Cast to Device finds screens again. |
| `Headphone Service.ps1` + `Headphone Service Task.xml` | Background task that starts Audio Repeater when Bluetooth headphones connect. |

### Files and folders

| Script | What it does |
|---|---|
| `Attribute Changer.ps1` | `r` toggles read-only and `s` toggles hidden + system on the given files. |
| `Grand Permissions + Ownership.ps1` | Copies the permissions of `%AppData%` onto the given files. |
| `Delete Locked Registry Keys  (+Lock keys).ps1` | Takes ownership of locked keys under a configured `HKCU` path, deletes the empty ones, then locks the remaining keys again. |
| `Clear Temp.ps1` | Deletes old files from the given folders (default: `tmp` and `temp` next to the script). |
| `Shortcut.ps1` | Creates a desktop shortcut for each given file. |
| `7z SFX Merge.ps1` | Joins `.sfx`, `.txt` and `.7z` parts with the same name into a self-extracting `.exe`. |
| `Image to Base64 to Clipboard.ps1` | Copies an image file, or the image on the clipboard, as a base64 data URI. |
| `Run as Non-Admin.ps1` | Starts a program without elevation (`RunAsInvoker`). |
| `Synchronizer.ps1` | Backs up app settings (registry and config folders) into `%CR%\Programs` and opens Beyond Compare to review them. |

### Apps

| Script | What it does |
|---|---|
| `Adobe Fixes.ps1` | Checklist window: close all Adobe apps, block or unblock Adobe Sync and the Acrobat updater, clean the Adobe system library. |
| `Adobe Plugin Installer.ps1` | Installs a `.zxp`/`.ccx` plugin with Adobe's Unified Plugin Installer. |
| `Reset AnyDesk ID.ps1` | Stops AnyDesk and renames its `service.conf` so it generates a new ID. |
| `Chrome AutoLaunch Fix  (Allow Manifest V2 Extensions).ps1` | Adds the flags that keep Manifest V2 extensions enabled to Chrome's startup entry; meant as a logoff script. |
| `NVM Auto Install & Use.ps1` | PowerShell profile snippet: installs nvm-windows when missing and switches Node.js to the project's `.nvmrc` on `cd`. |
| `Ganian App (VPN).ps1` | Greek-language helper that adds a hosts entry, installs Radmin VPN and opens a private web app. |
| `Black Screen.ps1` | Opens a full-screen black image. |

Some scripts use personal paths under `%CR%` (default `C:\CR`); adjust them for your setup.

## Issues

Found a bug or have an idea? [Open an issue](https://github.com/crazyrabbit0/PowerShell/issues/new/choose).

## License

[GPL-3.0](LICENSE) © CrazyRabbit
