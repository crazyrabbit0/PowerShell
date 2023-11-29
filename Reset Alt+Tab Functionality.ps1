
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Reset Alt + Tab Functionality'
$global:args = $args

############################## VARIABLES ##############################

$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
$EntryName = 'AltTabSettings'
$EntryValue = 1

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	show_title $global:title -set_title
	
	If (Get-ItemProperty -Path $RegistryPath -Name $EntryName -ErrorAction 'SilentlyContinue') {
		Write-Host -NoNewLine "`n`n`t Setting `"Alt + Tab`" to Default functionality... "
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName
		check_mark
	}
	else {
		Write-Host -NoNewLine "`n`n`t Setting `"Alt + Tab`" to Old functionality... "
		$NULL = New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType 'DWORD' -Force
		check_mark
	}
	
	finish -restart
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