
#--------------- Variables ---------------

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	showTitle $scriptTitle
	
	Get-Process "Acrobat*" | Stop-Process -Force -PassThru
	Get-Process | Where-Object Company -Match ".*Adobe.*" | Stop-Process -Force -PassThru
    
	""
	"${textPrefix}Do you want to Clean the Adobe Folders?"
	""
	"${textPrefix} [Y] Yes    [N] No"
	""
	do {
		$userChoice = [console]::ReadKey().Key
		Write-Host -NoNewLine "`r `r"
	} until($userChoice -match '^[yn]$')
	if($userChoice -eq 'y') {
		Remove-Item -Path @("${env:CommonProgramFiles(x86)}\Adobe\SLCache\*", "$env:ProgramData\Adobe\SLStore\*") -Force
	}
	
	""
	showTitle "Finish"
	quit
}

#--------------- Functions ---------------

function runWithAdminRights {
    param ([String[]] $argz)

	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	""
	"===============  $title  ==============="
	""
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