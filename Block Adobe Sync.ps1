
####################  Variables  ####################

$debug = 0
$adobe_sync_apps = 
	"${env:ProgramFiles(x86)}\Adobe\Adobe Sync\CoreSync\CoreSync.exe",
	"$env:ProgramFiles\Adobe\Adobe Creative Cloud Experience\CCXProcess.exe",
	"$env:CommonProgramFiles\Adobe\Creative Cloud Libraries\CCLibrary.exe"
$app_rights = [PSCustomObject]@{
	user = "Everyone"
	right = "ReadAndExecute"
	access = "Deny"
}

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
$icon_path = "$env:LocalAppData\Microsoft\Edge\User Data\Default\Edge Profile.ico"

$title = [PSCustomObject]@{
	font = "Segoe UI, 13"
	color = "Black"
	symbol = " "
	x = 10
	y = 10
}
$subtitle = [PSCustomObject]@{
	font = "Segoe UI Semibold, 10"
	color = [PSCustomObject]@{
		success = "DarkGreen"
		fail = "Crimson"
		exit = "RoyalBlue"
	}
	symbol = [PSCustomObject]@{
		success = " "
		fail = " "
		exit = " "
	}
	x = 30
	y = 30
}
$y = [PSCustomObject]@{
	base = 0
	space = 25
	added = 75
}

####################  Main Code  ####################

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz $(if ($debug) {"Normal"} else {"Minimized"})
	hide_window
	if ($debug) {hide_window $false}
	
	showTitle $scriptTitle
	$form = make_form $scriptTitle $icon_path
	$form.Add_Shown({
		If ((Get-Acl -Path $adobe_sync_apps).Access | Where-Object {$_.IdentityReference -eq $app_rights.user -and $_.FileSystemRights -eq $app_rights.right -and $_.AccessControlType -eq $app_rights.access})
		{
			Write-Host "`n${textPrefix}Unblocking Adobe Sync..."
			add_label $form "$($title.symbol)Unblocking Adobe Sync..." $title.x ($y.base += $title.y) $title.font $title.color $y.added
			if ($debug) {
				Write-Host "`n${textPrefix}Do you want to Unblock the Adobe Sync?"
				Write-Host "`n${textPrefix} [Y] Yes    [N] No"
				Write-Host ""
				do {
					$userChoice = [console]::ReadKey().Key
					Write-Host -NoNewLine "`r `r"
				} until($userChoice -match '^[yn]$')
			}
			else {
				$userChoice = [System.Windows.Forms.MessageBox]::Show("Do you want to Unblock the Adobe Sync?", "Attention:", "YesNo", "Warning", "Button1")
			}
			if($userChoice -eq 'Yes' -or $userChoice -eq 'y') {
				foreach ($app in $adobe_sync_apps)
				{
					$app_permissions = Get-Acl -Path $app
					$app_permissions.RemoveAccessRule((New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $app_rights.user, $app_rights.right, $app_rights.access)) | Out-Null
					Set-Acl -Path $app -AclObject $app_permissions
				}
				Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
				add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
			}
			else {
				Write-Host "`n${textPrefix}--- Aborted ---" -ForegroundColor "Red"
				add_label $form "$($subtitle.symbol.fail)Aborted" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.fail $y.added
			}
			$y.base += $y.space
		}
		else
		{
			Write-Host "`n${textPrefix}Blocking Adobe Sync..."
			add_label $form "$($title.symbol)Blocking Adobe Sync..." $title.x ($y.base += $title.y) $title.font $title.color $y.added
			foreach ($app in $adobe_sync_apps)
			{
				$app_permissions = Get-Acl -Path $app
				$app_permissions.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($app_rights.user, $app_rights.right, $app_rights.access))) | Out-Null
				Set-Acl -Path $app -AclObject $app_permissions
			}
			Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
			$y.base += $y.space
		}
		
		Write-Host ""
		showTitle "Process Finished"
		Write-Host "`n${textPrefix}--- You can close the window ---" -ForegroundColor "DarkCyan"
		add_label $form "$($title.symbol)Process finished!" $title.x ($y.base += $title.y) $title.font $title.color $y.added
		add_label $form "$($subtitle.symbol.exit)You can close the window" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.exit $y.added
		if ($debug) {Write-Host "";Start-Sleep -Seconds 300}
		#quit -form $form
	})
	$form.ShowDialog()
}

####################  Functions  ####################

function runWithAdminRights {
    param (
		[String[]]$argz,
		
		[String]$window_style = "Normal"
	)
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs -WindowStyle $window_style -FilePath powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	Write-Host ""
	Write-Host "===============  $title  ==============="
	Write-Host ""
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
		
        [string]$runArgument,
		
		[object]$form
    )
	""
	wait -text $text
	if ($runPath -ne $null) {Start-Process $runPath $runArgument}
	""
	if ($form -ne $null) {$form.Close()}
	else {exit}
}

function make_form {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [string]$icon,
		
        [string]$client_size = "300, 0",
		
        [string]$back_color = "#ffffff"
    )
	if (-not ("System.Windows.Forms" -as [type])) { 
		Add-Type -AssemblyName System.Windows.Forms
		[System.Windows.Forms.Application]::EnableVisualStyles()
	}
	$form = New-Object System.Windows.Forms.Form -Property @{
		Text = $title
		ClientSize = $client_size
		BackColor = $back_color
		StartPosition = "CenterScreen"
		FormBorderStyle = 1	# FormBorderStyle.FixedSingle
	}
	if ($icon) {$form.Icon = New-Object System.Drawing.Icon $icon}
	$form
}

function add_label {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [string]$text,
		
        [Parameter(Mandatory)]
        [int]$x,
		
        [Parameter(Mandatory)]
        [int]$y,
		
        [string]$font,
		
        [string]$text_color,
		
		[int]$added_height
    )
	$label = New-Object System.Windows.Forms.Label -Property @{
		Text = $text
		Location = New-Object System.Drawing.Point($x, $y)
		Font = $font
		ForeColor = $text_color
		AutoSize = $true
		UseCompatibleTextRendering = $true
	}
	$form.controls.Add($label)
	$form.Height = $y + $added_height
	[System.Windows.Forms.Application]::DoEvents()
	$label
}

function hide_window {
	param (
		[bool]$hide = $true
	)
	if (-not ("win32.user32" -as [type])) { 
		Add-Type -Name user32 -NameSpace win32 -MemberDefinition '
			[DllImport("user32.dll")]
			public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
		$global:console_handle = (get-process -id $pid).mainWindowHandle
	}
	$null = [win32.user32]::ShowWindow($console_handle, $(if ($hide) {0} else {5}))
}

####################  Run Main Code  ####################

main $args