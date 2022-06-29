
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
$RegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$EntryName = "AltTabSettings"
$EntryValue = 1

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
    
	showTitle $scriptTitle
    if($debug) { $argz }

    
    If (Get-ItemProperty -Path $RegistryPath -Name $EntryName -ErrorAction SilentlyContinue) {
		showTitle "Resetting ""Alt + Tab"" to Default functionality"
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName
	}
	else {
		showTitle "Setting ""Alt + Tab"" to Old functionality"
		New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType DWORD -Force
	}
	
	if($debug) { "";pause }
	restartPrompt
}

#--------------- Functions ---------------

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