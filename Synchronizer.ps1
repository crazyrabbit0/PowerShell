
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
				backup	= "$setupsPath\Internet Download Manager\.settings.reg"
			},
			@{
				title	= 'Cheat Engine'
				path	= 'HKCU\SOFTWARE\Cheat Engine'
				backup	= "$portablesPath\Cheat Engine\.settings.reg"
			}
		)
		
		files = @(
			@{
				title	= 'AnyDesk'
				path	= "$env:AppData\AnyDesk\user.conf"
				backup	= "$portablesPath\AnyDesk\.settings\user.conf"
			},
			@{
				title	= 'Handy'
				path	= "$env:AppData\com.pais.handy\settings_store.json"
				backup	= "$portablesPath\Handy\.settings\settings_store.json"
			},
			@{
				title	= 'MEGAsync'
				path	= "$env:LocalAppData\Mega Limited\MEGAsync\MEGAsync.cfg"
				backup	= "$setupsPath\MEGAsync\.settings\MEGAsync.cfg"
			},
			@{
				title	= 'OpenCode'
				path	= "$env:UserProfile\.config\opencode\opencode.json"
				backup	= "$portablesPath\OpenCode\.settings\opencode.json"
			},
			@{
				title	= 'Oh My OpenCode'
				path	= "$env:UserProfile\.config\opencode\oh-my-opencode.json"
				backup	= "$portablesPath\OpenCode\.settings\oh-my-opencode.json"
			},
			@{
				title	= 'Stacher'
				path	= "$env:AppData\Stacher7\CR.stacfg"
				backup	= "$setupsPath\Stacher\.settings\CR.stacfg"
			}
		)
		
		folders = @(
			@{
				title	= 'Chrome'
				path	= "$env:LocalAppData\Google\Chrome\User Data"
				backup	= "$setupsPath\Chrome\.settings\User Data"
				exclude	= 'BrowserMetrics Cache "Code Cache" GPUCache CacheStorage optimization_guide_prediction_model_downloads'
			},
			@{
				title	= 'Thunderbird'
				path	= "$env:AppData\Thunderbird\Profiles\ln02bahd.default-esr"
				backup	= "$setupsPath\Thunderbird\.settings\ln02bahd.default-esr"
			},
			@{
				title	= 'NanaZip  (Store)'
				path	= "$env:LocalAppData\Packages\40174MouriNaruto.NanaZip_gnj4mf6z9tkrc\SystemAppData"
				backup	= "$storePath\NanaZip\.settings\SystemAppData"
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