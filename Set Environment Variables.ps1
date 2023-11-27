
############################## Variables ##############################

$scriptTitle = (Get-Item $PSCommandPath).Basename

$envVars = @(
	@{name = 'CR';		shortcut = 'cr';	path = 'C:\CR'},
	@{name = 'Send To';	shortcut = 's2';	path = 'shell:SendTo'},
	@{name = 'Startup';	shortcut = 'su';	path = 'shell:Startup'},
	@{name = 'Apps';	shortcut = 'ap';	path = 'shell:AppsFolder'}
)

############################## Main Code ##############################

function main
{
	param ([string[]] $argz)
	
	showTitle($scriptTitle)
	
	''
	foreach ($envVar in $envVars)
	{
		" ($($envVar.shortcut)) $($envVar.name)"
		[Environment]::SetEnvironmentVariable($envVar.shortcut, $envVar.path, [System.EnvironmentVariableTarget]::User)
	}
	
	''
	showTitle 'Finish'
	quit
}

############################## Functions ##############################

function showTitle
{
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n=============== $title ===============`n"
}

function wait
{
	param (
		[ValidateNotNullOrEmpty()] [int] $seconds = 3,
		
		[ValidateNotNullOrEmpty()] [string] $text = ' Waiting'
	)
	
	Write-Host -NoNewLine $text
	for ($i = 0; $i -le $seconds; $i++)
	{
		Start-Sleep 1
		Write-Host -NoNewLine '.'
	}
}

function quit
{
	param (
		[ValidateNotNullOrEmpty()] [string] $text = ' Exiting',
		
		[string] $runPath,
		
		[string] $runArgument
	)
	
	''
	wait -text $text
	if ($runPath -ne $NULL)
	{
		Start-Process $runPath $runArgument
	}
	''
	exit
}

############################## Run Main Code ##############################

main $args