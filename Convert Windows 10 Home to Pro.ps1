
############################## Variables ##############################

$debug = 0
$scriptTitle = (Get-Item $PSCommandPath).Basename

############################## Main Code ##############################

function main
{
	param ([string[]] $argz)
	
	runWithAdminRights $argz
	
	showTitle $scriptTitle
	
	"`n Starting License Manager"
	Set-Service LicenseManager -StartupType Automatic -Status Running #-PassThru
	
	"`n Starting Windows Update"
	Set-Service wuauserv -StartupType Automatic -Status Running #-PassThru
	
	"`n`n Updating Product Key"
	Start-Process -Wait ChangePk "/ProductKey VK7JG-NPHTM-C97JM-9MPGT-3V66T"
	
	''
	restartPrompt
}

############################## Functions ##############################

function runWithAdminRights
{
	param ([string[]] $argz)
	
	if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
	{
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

function showTitle
{
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n===============  $title  ===============`n"
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

function restartPrompt
{
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
	
	if ($user_choice -eq 'Y')
	{
		quit ' Restarting' 'Shutdown' '/R /T 0'
	}
	
	if ($isQuiting) {
		quit
	}
}

############################## Run Main Code ##############################

main $args