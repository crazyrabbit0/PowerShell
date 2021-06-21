
#--------------- Variables ---------------

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	runWithAdminRights
	showTitle $scriptTitle
	showTitle "Install Module"
	Install-Module ps2exe
	#Uninstall-Module ps2exe
	""
	showTitle "Usage"
	""
	"${textPrefix}Command: ps2exe .\source.ps1 .\target.exe -NoConsole"
	""
	"${textPrefix}Gui: Win-PS2EXE"
	""
	showTitle "Guide"
	""
	"${textPrefix}https://github.com/MScholtes/PS2EXE#parameter"
	""
	quitPrompt
}

#--------------- Functions ---------------

function runWithAdminRights {
	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
		exit
	}
}

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	""
	"=============== $title ==============="
	""
}

function quitPrompt {
	param (
        [ValidateNotNullOrEmpty()]
        [string]$title = "Finish",
		
        [ValidateNotNullOrEmpty()]
        [string]$text = "Press any key to exit",
		
        [bool]$isQuiting = $true
    )
	showTitle $title
	""
	"${textPrefix}${text}"
	[Console]::CursorVisible = $false
	[console]::ReadKey().Key > $null
}


#--------------- Run Main Code ---------------

main $args