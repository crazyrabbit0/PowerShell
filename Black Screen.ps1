
#--------------- Variables ---------------

$debug = 0

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	if($debug) { $argz;"" }
	Add-Type -AssemblyName System.Windows.Forms
	Start-Process -FilePath "X_80.contrast-white.png"
	Start-Sleep 1
	[System.Windows.Forms.SendKeys]::SendWait('{F11}')
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args