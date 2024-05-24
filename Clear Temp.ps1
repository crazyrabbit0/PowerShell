
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Clear Temp'
$global:args = $args

############################## VARIABLES ##############################

$folders = @(
    "${PSScriptRoot}\tmp\",
    "${PSScriptRoot}\temp\"
)

$daysOld = 3

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }

	if ($global:args.count -eq 0) {
		$global:args = $folders
	}
	foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType 'Container') {
			Get-ChildItem $arg -Recurse -Force | Where-Object { $_.LastWriteTime -lt (get-date).AddDays(-$daysOld) } | Foreach-Object {
				if ($global:debug) { $_ | format-list }
				Remove-Item $_.FullName -Force
			}
		}
	}

	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main