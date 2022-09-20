
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	showTitle $scriptTitle
	
	showTitle "Uninstalling Product Keys"
	Cscript "$env:WinDir\System32\Slmgr.vbs" /upk
	
	showTitle "Removing Product Keys from Registry"
	Cscript "$env:WinDir\System32\Slmgr.vbs" /cpky
	
	showTitle "Removing KMS hosts from Registry"
	Cscript "$env:WinDir\System32\Slmgr.vbs" /ckms
	
	restartPrompt
}

#--------------- Functions ---------------

function runWithAdminRights {
    param ([String[]] $argz)

	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	""
	"===============  $title  ==============="
	""
}

function wait {
	param (
        [ValidateNotNullOrEmpty()]
        [int]$seconds = 3,
		
        [ValidateNotNullOrEmpty()]
        [string]$text = "${textPrefix}Waiting"
    )
	Write-Host -NoNewLine "$text"
	for($i=0; $i -le $seconds; $i++) {
		Start-Sleep 1
		Write-Host -NoNewLine "."
	}
}

function quit {
	param (
        [ValidateNotNullOrEmpty()]
        [string]$text = "${textPrefix}Exiting",
		
        [string]$runPath,
		
        [string]$runArgument
    )
	""
	wait -text $text
	if($runPath -ne $null) {
		Start-Process $runPath $runArgument
	}
	""
	exit
}

function restartPrompt {
	param (
        [ValidateNotNullOrEmpty()]
        [string]$title = "Finish",
		
        [bool]$isQuiting = $true
    )
	showTitle $title
	[system.media.systemsounds]::Beep.play()
	#(New-Object -com SAPI.SpVoice).speak("Operation has finished")
	"${textPrefix}Do you want to restart your computer?"
	""
	"${textPrefix} [Y] Yes (Recommended)    [N] No"
	""
	do {
		$userChoice = [console]::ReadKey().Key
		Write-Host -NoNewLine "`r `r"
	} until($userChoice -match '^[yn]$')
	if($userChoice -eq 'y') {
		quit "${textPrefix}Restarting" "Shutdown" "/R /T 0"
	}
	if($isQuiting) { quit }
}

#--------------- Run Main Code ---------------

main $args