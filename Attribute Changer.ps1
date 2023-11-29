
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Attribute Changer'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	foreach ($arg in $global:args) {
		if (Test-Path $arg) {
			$file = Get-Item $arg -Force
			if ($global:debug) { $file.Attributes }
			
			if ($global:args[0] -eq 'r') {
				if ($file.Attributes -match 'ReadOnly') { $file.Attributes = $file.Attributes -Replace '(, )?ReadOnly(, )?', '' }
				else { $file.Attributes = $file.Attributes -Replace '(.+)', '$1, ReadOnly' }
			}
			elseif ($global:args[0] -eq 's') {
				if ($file.Attributes -match 'System') { $file.Attributes = $file.Attributes -Replace '(, )?Hidden(, )?System(, )?', '' }
				else { $file.Attributes = $file.Attributes -Replace '(.+)', '$1, Hidden, System' }
			}

			if ($global:debug) { $file.Attributes }
		}
	}
	
	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main