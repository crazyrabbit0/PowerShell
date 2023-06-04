
####################  Variables  ####################

$debug = 1
$adobe_sync_apps = @(
	"${env:ProgramFiles(x86)}\Adobe\Adobe Sync\CoreSync\CoreSync.exe",
	"$env:ProgramFiles\Adobe\Adobe Creative Cloud Experience\CCXProcess.exe",
	"$env:CommonProgramFiles\Adobe\Creative Cloud Libraries\CCLibrary.exe"
)
$adobe_sync_rights = @{
	user = "Everyone"
	right = "ReadAndExecute"
	access = "Deny"
}
$adobe_system_library_folders = @(
	"${env:CommonProgramFiles(x86)}\Adobe\SLCache",
	"$env:ProgramData\Adobe\SLStore"
)

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
#$icon_path = "$env:LocalAppData\Microsoft\Edge\User Data\Default\Edge Profile.ico"

$symbol = @{
	primary = " "
	success = " "
	fail = " "
	exit = " "
}
$font = @{
	primary = "Segoe UI, 13"
	secondary = "Segoe UI Semibold, 10"
}
$color = @{
	primary = "Black"
	secondary = "White"
	success = "DarkGreen"
	fail = "Crimson"
	exit = "RoyalBlue"
}
$x = @{
	primary = 10
	secondary = 30
}
$y = @{
	primary = 10
	secondary = 30
}
$space = @{
	next = 25
	bottom = 75
}
$global:current_y = 0

####################  Main Code  ####################

function main {
	param ([String[]] $argz)
	
	run_as_administrator $argz $(if ($debug) {"Normal"} else {"Minimized"})
	if (-not $debug) {hide_powershell}
	
	Write-Host "`n===============  $scriptTitle  ===============`n"
	$form = make_form $scriptTitle $icon_path "250, 0"
	$close_adobe_apps = add_checkbox $form "Close all Adobe Apps" $x.primary $y.primary $font.primary $color.primary $space.bottom $space.next
	If ((Get-Acl -Path $adobe_sync_apps).Access | Where-Object {$_.IdentityReference -eq $adobe_sync_rights.user -and $_.FileSystemRights -eq $adobe_sync_rights.right -and $_.AccessControlType -eq $adobe_sync_rights.access}) {
		$unblock_adobe_sync_apps = add_checkbox $form "Unblock Adobe Sync Apps" $x.primary $y.primary $font.primary $color.primary $space.bottom $space.next
	}
	else {
		$block_adobe_sync_apps = add_checkbox $form "Block Adobe Sync Apps" $x.primary $y.primary $font.primary $color.primary $space.bottom $space.next
	}
	$y.current += $spacing.middle
	$clean_adobe_system_library = add_checkbox $form "Clean Adobe System Library" $x.primary $y.primary $font.primary $color.primary $space.bottom ($space.next * 1.5)
	$ok_button = add_button $form "" ($x.primary + 25) $y.primary $font.primary $color.secondary $color.success $space.bottom
	$ok_button.Add_Click({
		if ($close_adobe_apps.Checked -or $block_adobe_sync_apps.Checked -or $unblock_adobe_sync_apps.Checked -or $clean_adobe_system_library.Checked) {
			$form.DialogResult = [System.Windows.Forms.DialogResult]::Ok
		}
	})
	$cancel_button = add_button $form "" ($x.primary + 125) $y.current $font.primary $color.secondary $color.fail ($space.bottom * 1.2)
	$cancel_button.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$form_result = $form.ShowDialog()
	
	if ($form_result -eq "Cancel") {exit}
	
	$form = make_form $scriptTitle $icon_path
	$form.Add_Shown({
		if ($close_adobe_apps.Checked) {
			$title = "Close all Adobe Apps"
			Write-Host "`n${textPrefix}$title`:"
			add_label $form "$($symbol.title)$title`:" $x.primary $y.primary $font.primary $color.primary $space.bottom
			Get-Process "Acrobat*" | Stop-Process -Force
			Get-Process | Where-Object Company -Match ".*Adobe.*" | Stop-Process -Force
			Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
			add_label $form "$($symbol.success)Completed" $x.secondary $y.secondary $font.secondary $color.success $space.bottom $space.next
		}
		
		if ($block_adobe_sync_apps.Checked) {
			$title = "Block Adobe Sync Apps"
			Write-Host "`n${textPrefix}$title`:"
			add_label $form "$($symbol.title)$title`:" $x.primary $y.primary $font.primary $color.primary $space.bottom
			foreach ($app in $adobe_sync_apps) {
				$app_permissions = Get-Acl -Path $app
				$app_permissions.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adobe_sync_rights.user, $adobe_sync_rights.right, $adobe_sync_rights.access))) | Out-Null
				Set-Acl -Path $app -AclObject $app_permissions
			}
			Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
			add_label $form "$($symbol.success)Completed" $x.secondary $y.secondary $font.secondary $color.success $space.bottom $space.next
		}
		
		if ($unblock_adobe_sync_apps.Checked) {
			$title = "Unblock Adobe Sync Apps"
			Write-Host "`n${textPrefix}$title`:"
			add_label $form "$($symbol.title)$title`:" $x.primary $y.primary $font.primary $color.primary $space.bottom
			foreach ($app in $adobe_sync_apps) {
				$app_permissions = Get-Acl -Path $app
				$app_permissions.RemoveAccessRule((New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $adobe_sync_rights.user, $adobe_sync_rights.right, $adobe_sync_rights.access)) | Out-Null
				Set-Acl -Path $app -AclObject $app_permissions
			}
			Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
			add_label $form "$($symbol.success)Completed" $x.secondary $y.secondary $font.secondary $color.success $space.bottom $space.next
		}
		
		if ($clean_adobe_system_library.Checked) {
			$title = "Clean Adobe System Library"
			Write-Host "`n${textPrefix}$title`:"
			add_label $form "$($symbol.title)$title`:" $x.primary $y.primary $font.primary $color.primary $space.bottom
			Remove-Item -Path ($adobe_system_library_folders | ForEach-Object {"$_\*"}) -Force
			Write-Host "`n${textPrefix}--- Completed ---" -ForegroundColor "DarkGreen"
			add_label $form "$($symbol.success)Completed" $x.secondary $y.secondary $font.secondary $color.success $space.bottom $space.next
		}
		
		Write-Host "`n`n===============  Process Finished  ===============`n"
		Write-Host "`n${textPrefix}--- You can close the window ---" -ForegroundColor "DarkCyan"
		add_label $form "$($symbol.title)Process finished!" $x.primary $y.primary $font.primary $color.primary $space.bottom
		add_label $form "$($symbol.exit)You can close the window" $x.secondary $y.secondary $font.secondary $color.exit $space.bottom
	})
	$form.ShowDialog()
}

####################  Functions  ####################

function run_as_administrator {
    param (
		[String[]]$argz,
		
		[String]$window_style = "Normal"
	)
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs -WindowStyle $window_style -FilePath powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

function hide_powershell {
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

function make_form {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [string]$icon,
		
        [string]$client_size = "300, 300",
		
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
	$global:current_y = 0
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
		
		[int]$bottom_space,
		
		[int]$next_space = 0
    )
	$global:current_y += $y
	$label = New-Object System.Windows.Forms.Label -Property @{
		Text = $text
		Location = New-Object System.Drawing.Point($x, $global:current_y)
		Font = $font
		ForeColor = $text_color
		AutoSize = $true
		UseCompatibleTextRendering = $true
	}
	$form.controls.Add($label)
	$form.Height = $global:current_y + $bottom_space
	$global:current_y += $next_space
	[System.Windows.Forms.Application]::DoEvents()
	$label
}

function add_checkbox {
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
		
		[int]$bottom_space,
		
		[int]$next_space = 0
    )
	$global:current_y += $y
	$checkbox = New-Object System.Windows.Forms.CheckBox -Property @{
		Text = $text
		Location = New-Object System.Drawing.Point($x, $global:current_y)
		Font = $font
		ForeColor = $text_color
		AutoSize = $true
		UseCompatibleTextRendering = $true
		Cursor = [System.Windows.Forms.Cursors]::Hand
	}
	$form.controls.Add($checkbox)
	$form.Height = $global:current_y + $bottom_space
	$global:current_y += $next_space
	[System.Windows.Forms.Application]::DoEvents()
	$checkbox
}

function add_button {
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
		
        [string]$back_color,
		
		[int]$bottom_space,
		
		[int]$next_space = 0
    )
	$global:current_y += $y
	$button = New-Object System.Windows.Forms.Button -Property @{
		Text = $text
		Location = New-Object System.Drawing.Point($x, $global:current_y)
		Font = $font
		ForeColor = $text_color
		BackColor = $back_color
		AutoSize = $true
		UseCompatibleTextRendering = $true
		FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
		Cursor = [System.Windows.Forms.Cursors]::Hand
	}
	$button.FlatAppearance.BorderSize = 0
	$form.controls.Add($button)
	$form.Height = $global:current_y + $bottom_space
	$global:current_y += $next_space
	[System.Windows.Forms.Application]::DoEvents()
	$button
}

####################  Run Main Code  ####################

main $args