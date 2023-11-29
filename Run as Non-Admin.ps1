
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Run as Non-Admin'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	$env:__COMPAT_LAYER = 'RunAsInvoker'
	Start-Process ("`"$($global:args[0])`"" + ($global:args | Select-Object -Skip 1 | ForEach-Object { " `"$_`"" }))
	
	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main