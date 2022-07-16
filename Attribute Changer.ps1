
#--------------- Variables ---------------

$debug = 0

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	if($debug) { $argz;"" }
	
	Foreach($arg in $argz) {
		if(Test-Path $arg) {
			$file = Get-Item $arg -Force
			if($debug) { $file.Attributes }
			if($argz[0] -eq 'r') {
				if($file.Attributes -match 'ReadOnly') {
					$file.Attributes = $file.Attributes -Replace '(, )?ReadOnly(, )?', ''
				}
				else {
					$file.Attributes = $file.Attributes -Replace '(.+)', '$1, ReadOnly'
				}
			}
			elseif($argz[0] -eq 's') {
				if($file.Attributes -match 'System') {
					$file.Attributes = $file.Attributes -Replace '(, )?Hidden(, )?System(, )?', ''
				}
				else {
					$file.Attributes = $file.Attributes -Replace '(.+)', '$1, Hidden, System'
				}
			}
			if($debug) { $file.Attributes }
		}
	}
	
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args