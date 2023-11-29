
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Set Environment Variables'
$global:args = $args

############################## VARIABLES ##############################

$environment_variables = @(
	@{name = 'CR'; 		shortcut = 'cr';	path = 'C:\CR' },
	@{name = 'Send To';	shortcut = 's2';	path = 'shell:SendTo' },
	@{name = 'Startup';	shortcut = 'su';	path = 'shell:Startup' },
	@{name = 'Apps';	shortcut = 'ap';	path = 'shell:AppsFolder' }
)

############################## MAIN CODE ##############################

function main {
	show_title $global:title
	
	$environment_variables | Foreach-Object {
		Write-Host -NoNewLine "`n`n`t $($_.shortcut):`t$($_.name) "
		[Environment]::SetEnvironmentVariable($_.shortcut, $_.path, [System.EnvironmentVariableTarget]::User)
		check_mark
	}
	
	finish
}

############################## FUNCTIONS ##############################

function show_title {
	param (
		[Parameter(Mandatory)] [string] $title,
		[switch] $set_title
	)
	
	if ($set_title) { $Host.UI.RawUI.WindowTitle = $title }
	Write-Host "`n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  $title  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

function finish {
	param (
		[string] $title = 'Process Finished',
		[switch] $restart
	)
	
	''
	show_title $title
	[system.media.systemsounds]::Beep.play()

	if ($restart) {
		Write-Host -ForegroundColor Yellow -NoNewline "`n`n`t`t Restarting is required, restart now? [y/n] "
		do {
			$user_choice = [console]::ReadKey($TRUE).Key
		} until (@('Y', 'N') -contains $user_choice)

		if ($user_choice -eq 'Y') {
			Start-Process 'shutdown' '/t /t 0'
		}
	}
	else {
		Write-Host -ForegroundColor Yellow "`n`n`t`t`t    (Press any key to exit)"
		$NULL = [Console]::ReadKey($TRUE)
	}
	
	exit
}

function check_mark {
	param (
		[string] $symbol = 'v',
		[string] $color = 'Green'
	)
	
	Write-Host -ForegroundColor $color $symbol
}

############################## RUN MAIN CODE ##############################

main