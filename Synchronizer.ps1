
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Synchronizer'
$global:args = $args

############################## VARIABLES ##############################

if (-not (Test-Path env:cr)) { $env:cr = 'C:\CR' }

$setupsPath = "$env:cr\Programs\Setups"
$portablesPath = "$env:cr\Programs\Portables"
$storePath = "$env:cr\Programs\Store"

############################## MAIN CODE ##############################

function main {
	show_title $global:title -set_title

	Write-Host -NoNewLine "`n`n   You are about to run the $global:title, do you want to continue? [y/n] "
	do {
		$user_choice = [console]::ReadKey($TRUE).Key
		if ($user_choice -eq 'N') { exit }
	} until ($user_choice -eq 'Y')
	''
	
	sync @{
		registry = @(
			@{
				title	= 'Internet Download Manager'
				path	= 'HKCU\SOFTWARE\DownloadManager'
				backup	= "$setupsPath\Internet Download Manager\.Internet Download Manager Settings  -CR.reg"
			},
			@{
				title	= 'Cheat Engine'
				path	= 'HKCU\SOFTWARE\Cheat Engine'
				backup	= "$portablesPath\Cheat Engine\.Cheat Engine Settings  -CR.reg"
			}
		)
		
		files = @(
			@{
				title	= 'AnyDesk'
				path	= "$env:AppData\AnyDesk\user.conf"
				backup	= "$portablesPath\AnyDesk\.AnyDesk Settings  -CR\user.conf"
			}
		)
		
		folders = @(
			@{
				title	= 'GitHub Desktop'
				path	= "$env:AppData\GitHub Desktop"
				backup	= "$setupsPath\GitHub Desktop\.GitHub Desktop Settings  -CR\GitHub Desktop"
			},
			@{
				title	= 'Chrome'
				path	= "$env:LocalAppData\Google\Chrome\User Data"
				backup	= "$setupsPath\Chrome\.Chrome Settings  -CR\User Data"
				exclude	= 'BrowserMetrics Cache "Code Cache" GPUCache CacheStorage optimization_guide_prediction_model_downloads'
			},
			@{
				title	= 'Thunderbird'
				path	= "$env:AppData\Thunderbird\Profiles\ln02bahd.default-esr"
				backup	= "$setupsPath\Thunderbird\.Thunderbird Settings  -CR\ln02bahd.default-esr"
			},
			@{
				title	= 'NanaZip  (Store)'
				path	= "$env:LocalAppData\Packages\40174MouriNaruto.NanaZip_gnj4mf6z9tkrc\SystemAppData"
				backup	= "$storePath\NanaZip\.NanaZip Settings  -CR\SystemAppData"
			}
		)
	}
	
	Write-Host -NoNewLine "`n`n`t Running Beyond Compare... "
	Start-Process "$portablesPath\Beyond Compare\BCompare.exe" 'Unique'
	check_mark
	
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

function sync {
	param ([Parameter(Mandatory)] [System.Collections.Hashtable] $syncs)
	
	"`n`n`t Registry:"
	$syncs.registry | ForEach-Object {
		list_item $_.title
		if (Test-Path ($_.path -Replace '^(.+?)\\', '$1:\')) {
			Start-Process 'reg' "export ""$($_.path)"" ""$($_.backup)"" /y" -WindowStyle 'Hidden' -Wait
			check_mark
		}
		else {
			check_mark 'x' 'Red'
		}
	}
	
	"`n`n`t Files:"
	$syncs.files | ForEach-Object {
		list_item $_.title
		if (Test-Path $_.path -PathType 'Leaf') {
			Copy-Item $_.path $_.backup
			check_mark
		}
		else {
			check_mark 'x' 'Red'
		}
	}
	
	"`n`n`t Folders:"
	$syncs.folders | ForEach-Object {
		list_item $_.title
		if (Test-Path $_.path -PathType 'Container') {
			Start-Process 'robocopy' "`"$($_.path)`" `"$($_.backup)`" /MIR /XD $($_.exclude)" -WindowStyle 'Hidden' -Wait
			check_mark
		}
		else {
			check_mark 'x' 'Red'
		}
	}
}

############################## RUN MAIN CODE ##############################

main