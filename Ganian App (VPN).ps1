
#-----------------------------------------------------------Administrator-----------------------------------------------------------#

$debug = 0
$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $has_admin_rights) {Start-Process -Verb "RunAs" -WindowStyle $(if ($debug) {"Normal"} else {"Minimized"}) -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -WorkingDirectory $pwd; exit}

#-----------------------------------------------------------Variables-----------------------------------------------------------#

$radmin = $TRUE
$title	= (Get-Item $PSCommandPath).Basename
$vpn_ip	= '26.235.25.211'
$domain	= 'ganian'

#-----------------------------------------------------------Main Code-----------------------------------------------------------#

function main
{
	param ([String[]] $argz)
	
	showTitle $title
	
	if ($radmin)
	{
		$radmin_url = 'https://www.radmin-vpn.com/'
		$radmin_download = "$env:TMP/radmin_vpn.exe"
		$radmin_title = 'Radmin VPN'
		
		$radmin_path = "${env:ProgramFiles(x86)}\Radmin VPN\RvRvpnGui.exe"
		if (-Not (Test-Path -Path $radmin_path))
		{
			if (-Not (Test-Path $radmin_download))
			{
				"`n`t Downloading Radmin VPN..."
				$radmin_page = Invoke-RestMethod $radmin_url
				$download_url = ($radmin_page | Select-String "<a href=""(.*?)"" class=""buttonDownload""").Matches.Groups[1].Value
				wget $download_url -OutFile $radmin_download
			}
			"`n`t Installing Radmin VPN..."
			Start-Process $radmin_download '/VERYSILENT /NORESTART' -Wait
			Remove-Item $radmin_download
		}
		
		if (Test-Path -Path $radmin_path)
		{
			"`n`t Starting Radmin VPN..."
			Start-Process $radmin_path '/show'
		}
	}
	
	$domain_with_ip = "$vpn_ip`t$domain"
	$hosts	= "$env:WINDIR\System32\drivers\etc\hosts"
	$hosts_contents = Get-Content $hosts
	$made_changes = $FALSE
	
	$domains_without_ip = $hosts_contents -Match $domain
	if ($domains_without_ip.count -gt 0)
	{
		"`n`t Removing old domains from Windows hosts..."
		$hosts_contents = $hosts_contents -Replace ($domains_without_ip -join '|'), ''
		$made_changes = $TRUE
	}
	
	$domains_with_ip = $hosts_contents -Match  $domain_with_ip
	if ($domains_with_ip.count -eq 0)
	{
		"`n`t Adding domain to Windows hosts..."
		$hosts_contents += $domain_with_ip
		$made_changes = $TRUE
	}
	
	if ($made_changes)
	{
		"`n`t Saving Windows hosts..."
		$hosts_contents -join "`n" -replace '\n{3,}', "`n`n" | Out-File $hosts
	}
	
	Start-Process 'http://ganian'
	
	if ($debug) { "`n";pause }
}

#-----------------------------------------------------------Functions-----------------------------------------------------------#

function showTitle
{
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	"`n====================  $title  ====================`n"
}

#-----------------------------------------------------------Run Main Code-----------------------------------------------------------#

main $args