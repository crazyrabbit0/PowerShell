
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	showTitle $scriptTitle
	
	$powershellPath = '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"'
	$powershellRun = "$powershellPath -File `"%1`" %*"
	
	$powershellReg = "Registry::HKEY_CLASSES_ROOT\Microsoft.PowerShellScript.1"
	$powershellOpenWithReg = "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.ps1"
	
	""
	"${textPrefix}Set Execution Policy"
	if(!$debug) { $ErrorActionPreference = 'SilentlyContinue' }
	Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force > $null
	# Default: "Restricted"
	
	""
	"${textPrefix}Fix Run Command"
	Set-Item "$powershellReg\Shell\Open\Command" -Value $powershellRun
	# Default: "C:\Windows\System32\notepad.exe" "%1"
	
	""
	"${textPrefix}Fix Icon"
	Set-Item "$powershellReg\DefaultIcon" -Value $powershellPath
	# Default: "C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe",1
	
	""
	"${textPrefix}Add Drag & Drop"
	Remove-Item "$powershellReg\ShellEx" -Recurse > $null
	New-Item "$powershellReg\ShellEx\DropHandler" -Force > $null
	Set-Item "$powershellReg\ShellEx\DropHandler" -Value "{60254CA5-953B-11CF-8C96-00AA00B8708C}"
	# Default: {86C86720-42A0-1069-A2E8-08002B30309D}
	
	""
	"${textPrefix}Add Run as Administrator"
	Remove-Item "$powershellReg\Shell\RunAs" -Recurse > $null
	New-Item "$powershellReg\Shell\RunAs\Command" -Force > $null
	New-ItemProperty "$powershellReg\Shell\RunAs" "HasLUAShield" > $null
	Copy-Item "$powershellReg\Shell\Open\Command" "$powershellReg\Shell\RunAs"
	
	""
	"${textPrefix}Remove Open With"
	$RegKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($powershellOpenWithReg, $true)
	$RegKey.DeleteSubKey('UserChoice', $true)
	$RegKey.Close()
	
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
        [string]$Title
    )
	""
	"================ $Title ================"
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