
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Shortcut'
$global:args = $args

############################## VARIABLES ##############################

$destinationFolder = [Environment]::GetFolderPath('Desktop')

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	if ($global:args.count -eq 0) {
		$global:args = @($PSCommandPath)
	}
	foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType Leaf) {
			$destinationFile = "$destinationFolder\" + (Get-Item $arg).Basename + '.lnk'
			if ($global:debug) { $destinationFile }

			ps1Shortcut "$arg" "$destinationFile"
		}
	}
	
	if ($global:debug) { ''; pause }
	exit
}

############################## FUNCTIONS ##############################

function ps1Shortcut {
	param (
		[Parameter(Mandatory)] [string] $Source,
		[Parameter(Mandatory)] [string] $Destination
	)

	$Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($Destination)
	$Shortcut.TargetPath = 'powershell.exe'
	$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"${Source}`""
	$Shortcut.Save()
}

############################## RUN MAIN CODE ##############################

main