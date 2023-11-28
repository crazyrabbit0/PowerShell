
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Reset Alt+Tab Functionality'
$global:args = $args

############################## VARIABLES ##############################

$RegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$EntryName = "AltTabSettings"
$EntryValue = 1

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	showTitle $global:title
	
	If (Get-ItemProperty -Path $RegistryPath -Name $EntryName -ErrorAction SilentlyContinue) {
		showTitle 'Resetting "Alt + Tab" to Default functionality'
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName
	}
	else {
		showTitle 'Setting "Alt + Tab" to Old functionality'
		New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType DWORD -Force
	}
	
	if ($global:debug) { ''; pause }
	restartPrompt
}

############################## FUNCTIONS ##############################

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