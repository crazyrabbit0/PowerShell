
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Run as Non-Admin'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	$Env:__COMPAT_LAYER = 'RunAsInvoker'
	Start-Process ("`"$($global:args[0])`"" + ($global:args | Select -Skip 1 | ForEach-Object { " `"$_`"" }))
	
	if ($global:debug) { ''; pause }
}

############################## RUN MAIN CODE ##############################

main