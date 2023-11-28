
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Synchronizer'
$global:args = $args

############################## VARIABLES ##############################

if (-not (Test-Path env:cr)) { $env:cr = 'C:\CR' }

$setupsPath = "$env:cr\Programs\Setups"
$portablesPath = "$env:cr\Programs\Portables"

$exitText = ' Running Beyond Compare'
$exitRunPath = "$portablesPath\Beyond Compare (64-bit)\BCompare.exe"
$exitRunArgument = 'Unity'

############################## MAIN CODE ##############################

function main {
	showTitle $global:title

	" Are you sure you want to continue? `n"
	"  [Enter] Continue  [Escape] Exit `n"
	do {
		$user_choice = [console]::ReadKey($TRUE).Key
		if ($user_choice -eq "Escape") { exit }
	} until ($user_choice -eq 'Enter')
	
	clear-host
	showTitle $global:title
	
	syncFile `
		'MEGAsync (64-bit)' `
		"$env:LocalAppData\Mega Limited\MEGAsync\MEGAsync.cfg" `
		"$setupsPath\MEGAsync (64-bit)\.MEGAsync Settings  -CR\MEGAsync.cfg"
	
	syncFile `
		'AnyDesk' `
		"$env:AppData\AnyDesk\user.conf" `
		"$portablesPath\AnyDesk\.AnyDesk Settings  -CR\user.conf"
	
	syncFolder `
		'Viber' `
		"$env:AppData\ViberPC" `
		"$setupsPath\Viber\.Viber Settings  -CR\ViberPC"
	
	syncFolder `
		'RustDesk' `
		"$env:AppData\RustDesk\config" `
		"$portablesPath\RustDesk\.RustDesk Settings  -CR\config"
	
	syncFolder `
		'Chrome (64-bit)' `
		"$env:LocalAppData\Google\Chrome\User Data" `
		"$setupsPath\Chrome (64-bit)\.Chrome Settings  -CR\User Data" `
		'BrowserMetrics', 'Cache', 'Code Cache', 'GPUCache', 'CacheStorage', 'optimization_guide_prediction_model_downloads'
	
	exportRegistry `
		'7-Zip (64-bit)' `
		'HKCU\SOFTWARE\7-Zip' `
		"$setupsPath\7-Zip (64-bit)\.7-Zip Settings  -CR.reg"
	
	exportRegistry `
		'Internet Download Manager' `
		'HKCU\SOFTWARE\DownloadManager' `
		"$setupsPath\Internet Download Manager\.Internet Download Manager Settings  -CR.reg"
	
	exportRegistry `
		'Cheat Engine' `
		'HKCU\SOFTWARE\Cheat Engine' `
		"$portablesPath\Cheat Engine\.Cheat Engine Settings  -CR.reg"
	
	''
	showTitle 'Finish'
	quit $exitText $exitRunPath $exitRunArgument
}

############################## FUNCTIONS ##############################

function showTitle {
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n=============== $title ===============`n"
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

function syncFile {
	param (
		[Parameter(Mandatory)] [string] $title,

		[Parameter(Mandatory)] [string] $sourcePath,

		[Parameter(Mandatory)] [string] $destinationPath
	)
	
	if (Test-Path $sourcePath) {
		"`n $title"
		Copy-Item $sourcePath $destinationPath
	}
}

function syncFolder {
	param (
		[Parameter(Mandatory)] [string] $title,

		[Parameter(Mandatory)] [string] $sourcePath,

		[Parameter(Mandatory)] [string] $destinationPath,

		[string[]] $subfoldersToDelete
	)
	
	if (Test-Path $sourcePath) {
		"`n $title"
		Robocopy $sourcePath $destinationPath /Mir > $NULL
		if ($subfoldersToDelete -ne $NULL) {
			Get-ChildItem $destinationPath -Include $subfoldersToDelete -Recurse | Get-ChildItem | Remove-Item -Recurse > $NULL
		}
	}
}

function exportRegistry {
	param (
		[Parameter(Mandatory)] [string] $title,

		[Parameter(Mandatory)] [string] $registryPath,

		[Parameter(Mandatory)] [string] $destinationFile
	)
	
	if (Test-Path ($registryPath -Replace '^(.+?)\\', '$1:\')) {
		"`n $title"
		Reg Export $registryPath $destinationFile /y > $NULL
	}
}

############################## RUN MAIN CODE ##############################

main