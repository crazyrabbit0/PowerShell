
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	showTitle $scriptTitle
	""
	
	""
	"${textPrefix}Set Execution Policy"
	if(!$debug) { $ErrorActionPreference = 'SilentlyContinue' }
	Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force > $null
	
	""
	"${textPrefix}Fix Run Command in Registry"
	Set-Item 'Registry::HKEY_CLASSES_ROOT\Applications\powershell.exe\shell\open\command' -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "%1"' -Force > $null
	
	""
	"${textPrefix}Add Open With to Registry"
	New-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\OpenWithList' -Name a -Value powershell.exe -Force > $null
	""
	New-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1\OpenWithList' -Name MRUList -Value a -Force > $null
	
	showTitle "Finish"
	quit
}

#--------------- Functions ---------------

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$Title
    )
	""
	"================ $Title ================"
	#""
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

#--------------- Run Main Code ---------------

main $args