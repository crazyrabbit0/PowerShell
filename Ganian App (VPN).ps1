
#-----------------------------------------------------------Administrator-----------------------------------------------------------#

$debug = 0
$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-Not $has_admin_rights) {Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(if (Test-Path $MyInvocation.MyCommand.Definition -EA 0) {"-File `"$PSCommandPath`" $args"} else {"`"$($MyInvocation.MyCommand.Definition)`""}) -WorkingDirectory "$pwd" -Verb 'RunAs' -WindowStyle 'Normal'; if ($debug) {pause} exit}

#-----------------------------------------------------------Variables-----------------------------------------------------------#

$title	= 'Ganian App'
$domain	= 'ganian'
$vpn_ip	= '26.235.25.211'

#-----------------------------------------------------------Main Code-----------------------------------------------------------#

function main
{
	param ([String[]] $argz)
	
	showTitle $title
	
	$radmin = @{
		path		= "${env:ProgramFiles(x86)}\Radmin VPN\RvRvpnGui.exe"
		url			= 'https://www.radmin-vpn.com/'
		download	= "$env:TMP/radmin_vpn.exe"
	}
	
	if (-Not (Test-Path $radmin.path))
	{
		"`n`t Downloading Radmin VPN..."
		$radmin_page = Invoke-RestMethod $radmin.url
		$download_url = ($radmin_page | Select-String "<a href=""(.*?)"" class=""buttonDownload""").Matches.Groups[1].Value
		Start-BitsTransfer -Source $download_url -Destination $radmin.download -DisplayName 'Downloading Radmin VPN...'
		
		"`n`t Installing Radmin VPN..."
		Start-Process $radmin.download '/VERYSILENT /NORESTART' -Wait
		Remove-Item $radmin.download
	}
	
	if (Test-Path $radmin.path)
	{
		"`n`t Starting Radmin VPN..."
		Start-Process $radmin.path '/show'
	}
	
	$hosts = @{
		path	= "$env:WINDIR\System32\drivers\etc\hosts"
		content	= $NULL
	}
	$hosts.content = Get-Content $hosts.path
	
	$domains_with_ip = $hosts.content -Match $domain -Match $vpn_ip
	if ($domains_with_ip.count -eq 0)
	{
		"`n`t Adding domain to Windows hosts..."
		$hosts.content += "`n$vpn_ip   $domain"
	}
	
	$domains_without_ip = $hosts.content -Match $domain -NotMatch $vpn_ip
	if ($domains_without_ip.count -gt 0)
	{
		"`n`t Removing old domains from Windows hosts..."
		$hosts.content = $hosts.content -Replace ($domains_without_ip -join '|'), ''
	}
	
	if ($hosts.content -ne (Get-Content $hosts.path))
	{
		"`n`t Saving Windows hosts..."
		$hosts.content -join "`n" -replace '\n{3,}', "`n`n" | Out-File $hosts.path
	}
	
	Start-Process "http://$domain"
	
	"`n`n"
	if ($debug) {pause}
	exit
}

#-----------------------------------------------------------Functions-----------------------------------------------------------#

function showTitle
{
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	
	$Host.UI.RawUI.WindowTitle = $title
	"`n====================  $title  ====================`n"
}

#-----------------------------------------------------------Run Main Code-----------------------------------------------------------#

main $args