
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Clear Temp'
$global:args = $args

############################## VARIABLES ##############################

$tmpFolder = "${PSScriptRoot}\tmp\"

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	if ($global:args.count -eq 0) {
		$global:args = @($tmpFolder)
	}
	foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType 'Container') {
			Get-ChildItem $arg -Recurse -Force | Where-Object { $_.LastWriteTime -lt (get-date).AddHours(-1) } | Foreach-Object {
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