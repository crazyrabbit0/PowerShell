	
####################  Variables  ####################

$debug = 0
$anydesk_folder = "$env:ProgramData\AnyDesk"
$file_to_rename = "service.conf"

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
$icon_path = "$env:LocalAppData\Microsoft\Edge\User Data\Default\Edge Profile.ico"

$title = [PSCustomObject]@{
	font = "Microsoft Sans Serif"
	size = "13"
	style = ""
	color = "Black"
	symbol = " "
	x = 10
	y = 10
}
$subtitle = [PSCustomObject]@{
	font = "Microsoft Sans Serif"
	size = "10"
	style = "style=Bold"
	color = [PSCustomObject]@{
		success = "Green"
		exit = "Red"
	}
	symbol = [PSCustomObject]@{
		success = " "
		exit = " "
	}
	x = 30
	y = 25
}
$global:y = [PSCustomObject]@{
	base = 0
	space = 30
	form = 75
}

####################  Main Code  ####################

function main {
	param ([String[]]$argz)
	
	runWithAdminRights $argz "Minimized"
	show_window $false
	if ($debug) {show_window $true}
	
	showTitle $scriptTitle
	$form = make_form $scriptTitle $icon_path
	$form.Add_Shown({
		If (Get-Process "AnyDesk*") {
			""
			"${textPrefix}Closing AnyDesk processes..."
			add_label $form "$($title.symbol)Closing AnyDesk processes..." $title.x ($y.base += $title.y) "$($title.font), $($title.size), $($title.style)"
			Do {
				Get-Process "AnyDesk*" | Stop-Process -Force
				$anydesk_is_running = Get-Process "AnyDesk*"
			} Until (-Not $anydesk_is_running)
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) "$($subtitle.font), $($subtitle.size), $($subtitle.style)" "$($subtitle.color.success)"
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
			add_label $form "$($title.symbol)Removing old backups..." $title.x ($y.base += $title.y) "$($title.font), $($title.size), $($title.style)"
			Remove-Item -Path $file_path.backup -Force
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) "$($subtitle.font), $($subtitle.size), $($subtitle.style)" "$($subtitle.color.success)"
			$y.base += $y.space
		}
		
		If (Test-Path -Path $file_path.original -PathType Leaf) {
			""
			"${textPrefix}Making backup of affected files..."
			add_label $form "$($title.symbol)Making backup of affected files..." $title.x ($y.base += $title.y) "$($title.font), $($title.size), $($title.style)"
			Rename-Item -Path $file_path.original -NewName $file_path.backup -Force
			add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) "$($subtitle.font), $($subtitle.size), $($subtitle.style)" "$($subtitle.color.success)"
			$y.base += $y.space
		}
		
		""
		showTitle "Process Finished"
		add_label $form "$($title.symbol)${scriptTitle} finished!" $title.x ($y.base += $title.y) "$($title.font), $($title.size), $($title.style)"
		add_label $form "$($subtitle.symbol.exit)Please close the window" $subtitle.x ($y.base += $subtitle.y) "$($subtitle.font), $($subtitle.size), $($subtitle.style)" "$($subtitle.color.exit)"
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
		Icon = New-Object System.Drawing.Icon $icon
		StartPosition = "CenterScreen"
		FormBorderStyle = 1	# FormBorderStyle.FixedSingle
	}
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
		
        [string]$text_color
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
	$form.Height = $global:y.form + $y
	[System.Windows.Forms.Application]::DoEvents()
	$label
}

function show_window {
	param (
		[bool]$show = $true
	)
	if (-not ("win32.user32" -as [type])) { 
		Add-Type -Name user32 -NameSpace win32 -MemberDefinition '
			[DllImport("user32.dll")]
			public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
		$global:console_handle = (get-process -id $pid).mainWindowHandle
	}
	$null = [win32.user32]::ShowWindow($console_handle, $(if ($show) {5} else {0}))
}

####################  Run Main Code  ####################

main $args