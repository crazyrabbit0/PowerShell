
############################## Variables ##############################

$debug	= 0
$show	= 'Normal'
$title	= 'Grand Permissions + Ownership'

$permissionsSource = "$env:appData"

############################## Main Code ##############################

function main
{
	param (
		[String[]] $argz
	)
	
	run_as_admin
	
	if ($debug) {$argz; ''}
	Foreach ($arg in $argz)
	{
		if (Test-Path $arg -PathType Leaf)
		{
			if ($debug) {Get-Acl $arg | format-list}
			Get-Acl $permissionsSource | Set-Acl $arg
			if ($debug) {Get-Acl $arg | format-list}
		}
		elseif (Test-Path $arg -PathType Container)
		{
			Get-ChildItem $arg -Recurse -Force | Foreach
			{
				if ($debug) {Get-Acl $_.FullName | format-list}
				Get-Acl $permissionsSource | Set-Acl $_.FullName
				if ($debug) {Get-Acl $_.FullName | format-list}
			}
		}
	}
	if ($debug) {''; pause}
}

############################## Functions ##############################

function run_as_admin
{
	$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
	if (-Not $has_admin_rights) {Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(if (Test-Path $MyInvocation.MyCommand.Definition -EA 0) {"-File `"$PSCommandPath`" $args"} else {$MyInvocation.MyCommand.Definition -replace '"', "'"}) -WorkingDirectory "$pwd" -Verb 'RunAs' -WindowStyle $(if ($show) {$show} else {'Normal'}); if ($debug) {pause} exit}
}

############################## Run Main Code ##############################

main $args