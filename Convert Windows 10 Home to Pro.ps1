
############################## VARIABLES ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Convert Windows 10 Home to Pro'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	showTitle $global:title
	
	"`n Starting License Manager"
	Set-Service LicenseManager -StartupType Automatic -Status Running #-PassThru
	
	"`n Starting Windows Update"
	Set-Service wuauserv -StartupType Automatic -Status Running #-PassThru
	
	"`n`n Updating Product Key"
	Start-Process -Wait ChangePk "/ProductKey VK7JG-NPHTM-C97JM-9MPGT-3V66T"
	
	''
	restartPrompt
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

function showTitle {
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n===============  $title  ===============`n"
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

function restartPrompt {
	param (
		[ValidateNotNullOrEmpty()] [string] $title = "Finish",

		[bool] $isQuiting = $TRUE
	)
	
	showTitle $title
	
	[system.media.systemsounds]::Beep.play()
	#(New-Object -com SAPI.SpVoice).speak("Operation has finished")
	
	" Do you want to restart your computer? `n"
	"  [Y] Yes (Recommended)    [N] No `n"
	do {
		$user_choice = [console]::ReadKey($TRUE).Key
	} until (@('Y', 'N') -contains $user_choice)
	
	if ($user_choice -eq 'Y') {
		quit ' Restarting' 'Shutdown' '/R /T 0'
	}
	
	if ($isQuiting) {
		quit
	}
}

############################## RUN MAIN CODE ##############################

main