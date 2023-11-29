
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Adobe Plugin Installer'
$global:args = $args

############################## VARIABLES ##############################

$plugin_installer_path = "$env:CommonProgramFiles\Adobe\Adobe Desktop Common\RemoteComponents\UPI\UnifiedPluginInstallerAgent\UnifiedPluginInstallerAgent.exe"

############################## MAIN CODE ##############################
function main {
	if ($global:debug) { $global:args; '' }
	
	if (Test-Path $plugin_installer_path -PathType Leaf) {
		Start-Process -FilePath $plugin_installer_path "/install `"$($global:args[0])`"" -NoNewWindow
		Start-Sleep 1
	}

	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main