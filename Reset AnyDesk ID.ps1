
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
$anydesk_folder = "$env:ProgramData\AnyDesk"
$file_to_rename = "service.conf"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	showTitle $scriptTitle
	
	""
	"${textPrefix}Closing AnyDesk processes..."
	Get-Process "AnyDesk*" | Stop-Process -Force
	
	$path_to_original_file = "$anydesk_folder\$file_to_rename"
	$path_to_backup_file = "$path_to_original_file.bak"
	if($debug) { $path_to_original_file;""; $path_to_backup_file;"" }
	
	
	If(Test-Path -Path $path_to_backup_file -PathType Leaf) {
		""
		"${textPrefix}Removing old backups..."
		Remove-Item -Path $path_to_backup_file -Force
	}
	""
	"${textPrefix}Making backup of affected files..."
	If(Test-Path -Path $path_to_original_file -PathType Leaf) {
		Rename-Item -Path $path_to_original_file -NewName $path_to_backup_file -Force
	}
	
	if($debug) { "";pause }
	""
	showTitle "Process Finished"
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