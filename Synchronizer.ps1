
#--------------- Variables ---------------

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

if(-not (Test-Path env:cr)) { $env:cr = "C:\CR" }
$setupsPath = "$env:cr\Programs\Setups"
$portablesPath = "$env:cr\Programs\Portables"

$exitText = "${textPrefix}Running Beyond Compare"
$exitRunPath = "$portablesPath\Beyond Compare (64-bit)\BCompare.exe"
$exitRunArgument = "Venom"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	showTitle($scriptTitle)
	"${textPrefix}Are you sure you want to continue?"
	""
	"${textPrefix} [Enter] Continue  [Escape] Exit "
	""
	do {
		$userChoice = [console]::ReadKey().Key
		Write-Host -NoNewLine "`r `r"
		if($userChoice -eq "Escape") { exit }
	} until($userChoice -eq 'Enter')
	
	clear-host
	showTitle $scriptTitle
	
	syncFile `
		"MEGAsync (64-bit)" `
		"$env:LocalAppData\Mega Limited\MEGAsync\MEGAsync.cfg" `
		"$setupsPath\MEGAsync (64-bit)\.MEGAsync Settings  -CR\MEGAsync.cfg"
	
	syncFile `
		"AnyDesk" `
		"$env:AppData\AnyDesk\user.conf" `
		"$portablesPath\AnyDesk\.AnyDesk Settings  -CR\user.conf"
	
	syncFolder `
		"Viber" `
		"$env:AppData\ViberPC" `
		"$setupsPath\Viber\.Viber Settings  -CR\ViberPC"
	
	syncFolder `
		"Viber" `
		"$env:AppData\RustDesk\config" `
		"$portablesPath\RustDesk\.RustDesk Settings  -CR\config"
	
	syncFolder `
		"Chrome (64-bit)" `
		"$env:LocalAppData\Google\Chrome\User Data" `
		"$setupsPath\Chrome (64-bit)\.Chrome Settings  -CR\User Data" `
		"BrowserMetrics", "Cache", "Code Cache", "GPUCache"
	
	exportRegistry `
		"7-Zip (64-bit)" `
		"HKCU\SOFTWARE\7-Zip" `
		"$setupsPath\7-Zip (64-bit)\.7-Zip Settings  -CR.reg"
	
	exportRegistry `
		"Internet Download Manager" `
		"HKCU\SOFTWARE\DownloadManager" `
		"$setupsPath\Internet Download Manager\.Internet Download Manager Settings  -CR.reg"
	
	exportRegistry `
		"Cheat Engine" `
		"HKCU\SOFTWARE\Cheat Engine" `
		"$portablesPath\Cheat Engine\.Cheat Engine Settings  -CR.reg"
	
	""
	showTitle "Finish"
	quit $exitText $exitRunPath $exitRunArgument
}

#--------------- Functions ---------------

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	""
	"=============== $title ==============="
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

function syncFile {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [Parameter(Mandatory)]
        [string]$sourcePath,
		
        [Parameter(Mandatory)]
        [string]$destinationPath
    )
	if(Test-Path $sourcePath) {
		""
		"${textPrefix}${title}"
		Copy-Item $sourcePath $destinationPath
	}
}

function syncFolder {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [Parameter(Mandatory)]
        [string]$sourcePath,
		
        [Parameter(Mandatory)]
        [string]$destinationPath,
		
        [string[]]$subfoldersToDelete
    )
	if(Test-Path $sourcePath) {
		""
		"${textPrefix}${title}"
		Robocopy $sourcePath $destinationPath /Mir > $null
		if($subfoldersToDelete -ne $null) {
			Get-ChildItem $destinationPath -Include $subfoldersToDelete -Recurse | Get-ChildItem | Remove-Item -Recurse > $null
		}
	}
}

function exportRegistry {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [Parameter(Mandatory)]
        [string]$registryPath,
		
        [Parameter(Mandatory)]
        [string]$destinationFile
    )
	if(Test-Path ($registryPath -Replace '^(.+?)\\', '$1:\')) {
		""
		"${textPrefix}${title}"
		Reg Export $registryPath $destinationFile /y > $null
	}
}

#--------------- Run Main Code ---------------

main $args