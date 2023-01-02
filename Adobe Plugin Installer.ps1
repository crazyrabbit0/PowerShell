
#--------------- Variables ---------------

$debug = 1
$plugin_installer_path = "$env:CommonProgramFiles\Adobe\Adobe Desktop Common\RemoteComponents\UPI\UnifiedPluginInstallerAgent\UnifiedPluginInstallerAgent.exe"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	if($debug) { $argz;"" }
	if(Test-Path $plugin_installer_path -PathType Leaf) {
		Start-Process -FilePath $plugin_installer_path "/install ""$($argz[0])""" -NoNewWindow
		Start-Sleep 1
	}
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args