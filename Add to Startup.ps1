
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Add to Startup'
$global:args = $args

############################## VARIABLES ##############################

$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }

	show_title $global:title -set_title
	
	$EntryName = (Get-Item $global:args[0]).BaseName
	$EntryValue = "`"$($global:args[0])`"" + ($global:args | Select-Object -Skip 1 | ForEach-Object { " `"$_`"" })
	
	If ((Get-Item $RegistryPath -ErrorAction 'Ignore').Property -contains $EntryName) {
		Write-Host -NoNewLine "`n`n`t`t`t Removing `"$EntryName`" from Starup... "
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName -Force
		check_mark
	}
	else {
		Write-Host -NoNewLine "`n`n`t`t`t Addind `"$EntryName`" to Starup... "
		$NULL = New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType 'String' -Force
		check_mark
	}
	
	finish
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