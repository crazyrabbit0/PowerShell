
############################## GLOBALS ##############################

$global:debug	= 0
$global:display = 'Normal'
$global:title = 'Grand Permissions + Ownership'
$global:args = $args

############################## VARIABLES ##############################

$permissionsSource = "$env:appData"

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	if ($global:debug) { $global:args; '' }

	Foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType Leaf) {
			if ($global:debug) { Get-Acl $arg | format-list }
			Get-Acl $permissionsSource | Set-Acl $arg
			if ($global:debug) { Get-Acl $arg | format-list }
		}
		elseif (Test-Path $arg -PathType 'Container') {
			Get-ChildItem $arg -Recurse -Force | Foreach-Object {
				if ($global:debug) { Get-Acl $_.FullName | format-list }
				Get-Acl $permissionsSource | Set-Acl $_.FullName
				if ($global:debug) { Get-Acl $_.FullName | format-list }
			}
		}
	}
	
	if ($global:debug) { ''; pause }
	exit
}

############################## FUNCTIONS ##############################

function run_as_admin {
	$has_admin_rights = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
	if (-not $has_admin_rights) {
		Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(if ($NULL -ne $PSCommandPath) { "-File `"$PSCommandPath`" $global:args" } else { $MyInvocation.MyCommand.Definition -replace '"', "'" }) -WorkingDirectory $pwd -Verb 'RunAs' -WindowStyle $(if ($global:debug) { 'Normal' } else { $global:display })
		if ($global:debug) { pause }
		exit
	}
}

############################## RUN MAIN CODE ##############################

main