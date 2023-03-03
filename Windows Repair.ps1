
#--------------- Variables ---------------

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	showTitle $scriptTitle
	
	showTitle "Clean Disk"
	Start-Process -Wait CleanMgr
	#Start-Process -Wait CleanMgr /LowDisk
	#Start-Process -Wait CleanMgr /VeryLowDisk
	
	showTitle "Check Disk"
	ChkDsk /Scan /Perf #/R
	#ChkDsk /F #/R
	""
	
	showTitle "Repair Image"
	#Dism /Cleanup-Wims
	#Dism /Online /Cleanup-Image /CheckHealth
	#Dism /Online /Cleanup-Image /ScanHealth
	#Dism /Online /Cleanup-Image /StartComponentCleanup #/ResetBase
	#Dism /Online /Cleanup-Image /AnalyzeComponentStore
	Dism /Online /Cleanup-Image /RestoreHealth #/Source:D:\sources\install.wim /LimitAcces
	Notepad "$env:WinDir\Logs\DISM\DISM.log"
	""
	
	showTitle "Repair System Files"
	Sfc /ScanNow
	Notepad "$env:WinDir\Logs\CBS\CBS.log"
	""
	
	showTitle "Optimize Disk"
	Start-Process -Wait DfrGui
	
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
	if($runPath -ne '') {
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