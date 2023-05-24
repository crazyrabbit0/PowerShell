	
####################  Variables  ####################

$debug = 0
$anydesk_folder = "$env:ProgramData\AnyDesk"
$file_to_rename = "service.conf"

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
		exit = "RoyalBlue"
	}
	symbol = [PSCustomObject]@{
		success = " "
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
	param ([String[]]$argz)
	
	runWithAdminRights $argz $(if ($debug) {"Normal"} else {"Minimized"})
	hide_window
	if ($debug) {hide_window $false}
	
	showTitle $scriptTitle
	$form = make_form $scriptTitle $icon_path
	$form.Add_Shown({
		If (Get-Process "AnyDesk*") {
			""
			"${textPrefix}Closing AnyDesk processes..."
			add_label $form "$($title.symbol)Closing AnyDesk processes..." $title.x ($y.base += $title.y) $title.font $title.color $y.added
			Do {
				Get-Process "AnyDesk*" | Stop-Process -Force
				$anydesk_is_running = Get-Process "AnyDesk*"
			} Until (-Not $anydesk_is_running)
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
			$y.base += $y.space
		}
		
		$file_path = [PSCustomObject]@{
			original = "$anydesk_folder\$file_to_rename"
			backup = "$anydesk_folder\$file_to_rename.bak"
		}
		if ($debug) {Write-Output $file_path | Format-List}
		
		If (Test-Path -Path $file_path.backup -PathType Leaf) {
			""
			"${textPrefix}Removing old backups..."
			add_label $form "$($title.symbol)Removing old backups..." $title.x ($y.base += $title.y) $title.font $title.color $y.added
			Remove-Item -Path $file_path.backup -Force
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
			$y.base += $y.space
		}
		
		If (Test-Path -Path $file_path.original -PathType Leaf) {
			""
			"${textPrefix}Making backup of affected files..."
			add_label $form "$($title.symbol)Making backup of affected files..." $title.x ($y.base += $title.y) $title.font $title.color $y.added
			Rename-Item -Path $file_path.original -NewName $file_path.backup -Force
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
			$y.base += $y.space
		}
		
		""
		showTitle "Process Finished"
		add_label $form "$($title.symbol)Process finished!" $title.x ($y.base += $title.y) $title.font $title.color $y.added
		add_label $form "$($subtitle.symbol.exit)You can close the window" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.exit $y.added
		if ($debug) {"";pause}
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
	""
	"===============  $title  ==============="
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