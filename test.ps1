﻿#-----------------------------------------------------------Administrator-----------------------------------------------------------#

$debug = 0
$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-Not $has_admin_rights) {Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(if (Test-Path $MyInvocation.MyCommand.Definition -EA 0) {"-File `"$PSCommandPath`" $args"} else {$MyInvocation.MyCommand.Definition -replace '"', "'"}) -WorkingDirectory "$pwd" -Verb 'RunAs' -WindowStyle 'Normal'; if ($debug) {pause} exit}

#-----------------------------------------------------------Variables-----------------------------------------------------------#

$title	= 'Ganian App'
$domain	= 'ganian'
$vpn_ip	= '26.235.25.211'

#-----------------------------------------------------------Main Code-----------------------------------------------------------#

function main
{
	param ([String[]] $argz)
	
	set_title $title
	
	"`n`n`t ������ ����������� Windows:"
	$hosts = @{
		path		= "$env:WINDIR\System32\drivers\etc\hosts"
		content		= $NULL
		old_content	= $NULL
		differences	= $NULL
	}
	$hosts.content = $hosts.old_content = Get-Content $hosts.path
	
	$domains_with_ip = $hosts.content -Match $domain -Match $vpn_ip
	if ($domains_with_ip.count -eq 0)
	{
		list_item '�������� ���� ����������...'
		$hosts.content += "`n$vpn_ip   $domain"
		check_mark
	}
	
	$domains_without_ip = $hosts.content -Match $domain -NotMatch $vpn_ip
	if ($domains_without_ip.count -gt 0)
	{
		list_item '�������� ������� �����������...'
		$hosts.content = $hosts.content -Replace ($domains_without_ip -join '|'), ''
		check_mark
	}
	
	$hosts.differences = Compare-Object $hosts.content $hosts.old_content
	if ($hosts.differences -ne $NULL)
	{
		list_item '����������...'
		$hosts.content -join "`n" -replace '\n{3,}', "`n`n" | Out-File -Encoding ASCII $hosts.path
		check_mark
	}
	
	"`n`n`n`t �������� �������� ������ Radmin:"
	$radmin = @{
		path		= "${env:ProgramFiles(x86)}\Radmin VPN\RvRvpnGui.exe"
		url			= 'https://www.radmin-vpn.com/'
		download	= "$env:TMP/radmin_vpn.exe"
	}
	
	if (-Not (Test-Path $radmin.path))
	{
		list_item '����...'
		$radmin_page = Invoke-RestMethod $radmin.url
		$download_url = ($radmin_page | Select-String "<a href=""(.*?)"" class=""buttonDownload""").Matches.Groups[1].Value
		$ProgressPreference = "SilentlyContinue"
		Start-BitsTransfer -Source $download_url -Destination $radmin.download -DisplayName '����...'
		check_mark
		
		list_item '�����������...'
		Start-Process $radmin.download '/VERYSILENT /NORESTART' -Wait
		check_mark
		
		list_item '�������� �����...'
		Remove-Item $radmin.download
		check_mark
	}
	
	if (Test-Path $radmin.path)
	{
		list_item '��������...'
		Start-Process $radmin.path '/show'
		check_mark
	}
	
	Write-Host -NoNewLine "`n`n`n`t ������� ��o��������� ����������... "
	Start-Process "http://$domain"
	check_mark
	
	"`n`n`n`t � ���������� ������������!"
	Write-Host -ForegroundColor Yellow "`n`t (������� ���������� ������� ��� �� ��������)"
	$NULL = [console]::ReadKey($true).Key
	exit
}

#-----------------------------------------------------------Functions-----------------------------------------------------------#

function set_title
{
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	
	$Host.UI.RawUI.WindowTitle = $title
	"`n====================  $title  ===================="
}

function list_item
{
	param (
        [Parameter(Mandatory)]
        [string]$text,
		
        [string]$symbol = '�'
    )
	
	Write-Host -NoNewLine -ForegroundColor Gray "`n`t $symbol $text "
}

function check_mark
{
	param (
        [string]$symbol = '?'
    )
	
	Write-Host -ForegroundColor Green $symbol
}

#-----------------------------------------------------------Run Main Code-----------------------------------------------------------#

main $args