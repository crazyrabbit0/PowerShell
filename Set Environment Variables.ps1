
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Set Environment Variables'
$global:args = $args

############################## VARIABLES ##############################

$envVars = @(
	@{name = 'CR'; 		shortcut = 'cr';	path = 'C:\CR' },
	@{name = 'Send To';	shortcut = 's2';	path = 'shell:SendTo' },
	@{name = 'Startup';	shortcut = 'su';	path = 'shell:Startup' },
	@{name = 'Apps';	shortcut = 'ap';	path = 'shell:AppsFolder' }
)

############################## MAIN CODE ##############################

function main {
	showTitle($global:title)
	
	''
	foreach ($envVar in $envVars) {
		" ($($envVar.shortcut)) $($envVar.name)"
		[Environment]::SetEnvironmentVariable($envVar.shortcut, $envVar.path, [System.EnvironmentVariableTarget]::User)
	}
	
	''
	showTitle 'Finish'
	quit
}

############################## FUNCTIONS ##############################

function showTitle {
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n=============== $title ===============`n"
}

function wait {
	param (
		[ValidateNotNullOrEmpty()] [int] $seconds = 3,
		
		[ValidateNotNullOrEmpty()] [string] $text = ' Waiting'
	)
	
	Write-Host -NoNewLine $text
	for ($i = 0; $i -le $seconds; $i++) {
		Start-Sleep 1
		Write-Host -NoNewLine '.'
	}
}

function quit {
	param (
		[ValidateNotNullOrEmpty()] [string] $text = ' Exiting',
		
		[string] $runPath,
		
		[string] $runArgument
	)
	
	''
	wait -text $text
	if ($runPath -ne $NULL) {
		Start-Process $runPath $runArgument
	}
	''
	exit
}

############################## RUN MAIN CODE ##############################

main