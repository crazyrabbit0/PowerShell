
############################## VARIABLES ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Win 10 Home to Pro'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	show_title $global:title -set_title
	
	Write-Host -NoNewLine "`n`n`t Starting License Manager... "
	Set-Service 'LicenseManager' -StartupType 'Automatic' -Status 'Running' #-PassThru
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Starting Windows Update... "
	Set-Service 'wuauserv' -StartupType 'Automatic' -Status 'Running' #-PassThru
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Updating Product Key... "
	Start-Process 'ChangePk' '/ProductKey VK7JG-NPHTM-C97JM-9MPGT-3V66T' -Wait
	check_mark
	
	finish -restart
}

############################## FUNCTIONS ##############################

function run_as_admin {
	$has_admin_rights = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
	if (-not $has_admin_rights) {
		Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(if ($NULL -ne $PSCommandPath) { "-File `"$PSCommandPath`" $global:args" } else { $MyInvocation.MyCommand.Definition -replace '"', "'" }) -WorkingDirectory $pwd -Verb 'RunAs' -WindowStyle $(if ($global:debug) { 'Normal' } else { $global:display })
		if ($global:debug) { pause }
		exit
	}
}

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