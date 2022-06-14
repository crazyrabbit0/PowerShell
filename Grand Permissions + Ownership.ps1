
#--------------- Variables ---------------

$debug = 0
$permissionsSource = "$env:appData"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
	if($debug) { $argz;"" }
	Foreach($arg in $argz) {
		if(Test-Path $arg -PathType Leaf) {
			if($debug) { Get-Acl $arg | format-list }
			Get-Acl $permissionsSource | Set-Acl $arg
			if($debug) { Get-Acl $arg | format-list }
		}
		elseif(Test-Path $arg -PathType Container) {
			Get-ChildItem $arg -Recurse -Force | Foreach {
				if($debug) { Get-Acl $_.FullName | format-list }
				Get-Acl $permissionsSource | Set-Acl $_.FullName
				if($debug) { Get-Acl $_.FullName | format-list }
			}
		}
	}
	if($debug) { "";pause }
}

#--------------- Functions ---------------

function runWithAdminRights {
    param ([String[]] $argz)

	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

#--------------- Run Main Code ---------------

main $args