
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'AutoLogin Option'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	run_as_admin

	show_title $global:title -set_title
	
	$registry = @{
		key   = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
		entry = 'DevicePasswordLessBuildVersion'
		value = @{
			enabled  = 0
			disabled = 2
		}
	}
	
	$opposite_state = @{
		enabled  = 'disabled'
		disabled = 'enabled'
	}
	
	$current_registry_value = (Get-ItemProperty -Path $registry.key).$($registry.entry)
	$current_state = $registry.value.GetEnumerator().Where({ $_.Value -eq $current_registry_value }).Name
	
	Write-Host -NoNewLine "`n`n`t $global:title is $current_state, do you wish to $($opposite_state.$current_state.TrimEnd('d')) it?  [y/n] "
	do {
		$user_choice = [Console]::ReadKey($TRUE).Key
	} until (@('Y', 'N') -contains $user_choice)
	''
	
	if ($user_choice -eq 'Y') {
		list_item ((Get-Culture).TextInfo.ToTitleCase($opposite_state.$current_state.TrimEnd('ed')) + "ing $global:title...")
		Set-ItemProperty -Path $registry.key -Name $registry.entry -Value $registry.value.$($opposite_state.$current_state)
		check_mark
	
		list_item 'Opening User Accounts...'
		Start-Process 'netplwiz'	# Alternative: Start-Process 'control' 'userpasswords2'
		check_mark
	}
	else {
		list_item 'Operation Aborted...'
		check_mark 'x' 'Red'
	}
	
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

function list_item {
	param (
		[Parameter(Mandatory)] [string] $text,
		[string] $symbol = '-'
	)
	
	Write-Host -NoNewLine -ForegroundColor Gray "`n`t $symbol $text "
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