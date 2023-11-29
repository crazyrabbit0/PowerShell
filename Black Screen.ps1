
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Black Screen'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	Start-Process -FilePath 'X_80.contrast-white.png'
	Start-Sleep 1
	
	Add-Type -AssemblyName 'System.Windows.Forms'
	[System.Windows.Forms.SendKeys]::SendWait('{F11}')
	
	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main