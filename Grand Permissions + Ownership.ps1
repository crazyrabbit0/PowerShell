
#--------------- Variables ---------------

$debug = 0
$permissionsSource = get-acl "$env:appData"

#--------------- Main Code ---------------

function main {
	runWithAdminRights
	if($debug) { $args;"" }
	Foreach($arg in $args) {
		if(Test-Path $arg -PathType Leaf) {
			if($debug) { get-acl $arg | format-list }
			Set-Acl $arg $permissionsSource
			if($debug) { get-acl $arg | format-list }
		}
		elseif(Test-Path $arg -PathType Container) {
			Get-ChildItem $arg -Recurse -Force | Foreach {
				if($debug) { get-acl $_.FullName | format-list }
				Set-Acl $_.FullName $permissionsSource
				if($debug) { get-acl $_.FullName | format-list }
			}
		}
	}
	if($debug) { "";pause }
}

#--------------- Functions ---------------

function runWithAdminRights {
	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
		exit
	}
}

#--------------- Run Main Code ---------------

main $args