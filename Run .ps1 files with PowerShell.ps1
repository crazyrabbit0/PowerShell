
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Run .ps1 files with PowerShell'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	show_title $global:title -set_title
	
	$powershellPath = '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"'
	$powershellRun = "$powershellPath -File `"%1`" %*"
	
	$powershellReg = 'Registry::HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1'
	$powershellOpenWithReg = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1'
	
	Write-Host -NoNewLine "`n`n`t Setting Execution Policy... "
	if (-Not $global:debug) { $ErrorActionPreference = 'SilentlyContinue' }
	$NULL = Set-ExecutionPolicy 'RemoteSigned' -Scope 'CurrentUser' -Force # Default: "Restricted"
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Fixing Run Command... "
	Set-Item "$powershellReg\Shell\Open\Command" -Value $powershellRun # Default: "C:\Windows\System32\notepad.exe" "%1"
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Fixing Icon... "
	Set-Item "$powershellReg\DefaultIcon" -Value $powershellPath # Default: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe",1
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Adding Drag & Drop... "
	$NULL = Remove-Item "$powershellReg\ShellEx" -Recurse
	$NULL = New-Item "$powershellReg\ShellEx\DropHandler" -Force
	Set-Item "$powershellReg\ShellEx\DropHandler" -Value '{60254CA5-953B-11CF-8C96-00AA00B8708C}' # Default: {86C86720-42A0-1069-A2E8-08002B30309D}
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Adding Run as Administrator... "
	$NULL = Remove-Item "$powershellReg\Shell\RunAs" -Recurse
	$NULL = New-Item "$powershellReg\Shell\RunAs\Command" -Force
	$NULL = New-ItemProperty "$powershellReg\Shell\RunAs" 'HasLUAShield'
	Copy-Item "$powershellReg\Shell\Open\Command" "$powershellReg\Shell\RunAs"
	check_mark
	
	Write-Host -NoNewLine "`n`n`t Removing Open With... "
	$RegKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($powershellOpenWithReg, $TRUE)
	$RegKey.DeleteSubKey('UserChoice', $TRUE)
	$RegKey.Close()
	check_mark
	
	finish
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