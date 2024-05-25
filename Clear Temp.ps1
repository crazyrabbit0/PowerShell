
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

$daysToKeep = 1
$filesToKeep = 0

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }

	if ($global:args.count -eq 0) {
		$global:args = $folders
	}
	foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType 'Container') {
			Get-ChildItem $arg -Recurse -Force | Where-Object { $_.LastWriteTime -lt (get-date).AddDays(-$daysToKeep) } | Sort-Object -Property LastWriteTime | Select-Object -SkipLast $filesToKeep | Foreach-Object {
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