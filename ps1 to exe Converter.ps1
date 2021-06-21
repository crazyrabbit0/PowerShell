
#--------------- Variables ---------------

$debug = 0
$scriptPath = $MyInvocation.MyCommand.Path

#--------------- Main Code ---------------

function main {
	if([string]::IsNullOrWhiteSpace($args[0])) { $args[0] = $scriptPath }
	if($debug) { $args;"" }
	Foreach($arg in $args) {
		if(Test-Path $arg) {
			if($debug) { $arg }
			ps2exe "$arg" -iconFile "./icons/PowerShell.ico"
		}
	}
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args