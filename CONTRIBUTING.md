# Contributing

Thanks for helping out. Bug reports and ideas go in [issues](https://github.com/crazyrabbit0/PowerShell/issues/new/choose); fixes and new scripts go in pull requests.

## Pull requests

1. Keep each pull request to one script or one change.
2. Follow the shared template: the `GLOBALS / VARIABLES / MAIN CODE / FUNCTIONS / RUN MAIN CODE` banners, a `main` function, and `$global:debug = 0` in commits.
3. Make sure the script parses in Windows PowerShell 5.1 (CI checks every `.ps1`), and save it as UTF-8 **with BOM** if it contains any non-ASCII character.
4. Update the table in the [README](README.md) when you add or remove a script or change what one does.
5. Describe how you tested it, including your Windows version.

These are personal Windows PowerShell 5.1 scripts that change real systems, so explain anything that edits the registry, services, files or permissions.

## License

By contributing you agree that your changes are licensed under [GPL-3.0](LICENSE).
