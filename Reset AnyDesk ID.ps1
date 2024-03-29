﻿
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Minimized'
$global:title = 'Reset AnyDesk ID'
$global:args = $args

############################## VARIABLES ##############################

$icon_path = "$env:LocalAppData\Microsoft\Edge\User Data\Default\Edge Profile.ico"

$anydesk_folders = @("$env:ProgramData\AnyDesk", "$env:AppData\AnyDesk")
$file_to_rename = 'service.conf'

$title = [PSCustomObject]@{
	font   = 'Segoe UI, 13'
	color  = 'Black'
	symbol = ' '
	x      = 10
	y      = 10
}
$subtitle = [PSCustomObject]@{
	font   = 'Segoe UI Semibold, 10'
	color  = [PSCustomObject]@{
		success = 'DarkGreen'
		exit    = 'RoyalBlue'
	}
	symbol = [PSCustomObject]@{
		success = ' '
		exit    = ' '
	}
	x      = 30
	y      = 30
}
$y = [PSCustomObject]@{
	base  = 0
	space = 25
	added = 75
}

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	if (-not $global:debug) { hide_window }
	
	show_title $global:title -set_title
	$form = make_form $global:title $icon_path
	$form.Add_Shown({
			If (Get-Process 'AnyDesk*') {
				Write-Host "`n Closing AnyDesk processes..."
				add_label $form "$($title.symbol)Closing AnyDesk processes..." $title.x ($y.base += $title.y) $title.font $title.color $y.added

				Do {
					Get-Process "AnyDesk*" | Stop-Process -Force
					$anydesk_is_running = Get-Process 'AnyDesk*'
				} Until (-Not $anydesk_is_running)

				add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
				$y.base += $y.space
			}
		
			ForEach ($anydesk_folder in $anydesk_folders) {
				$file_path = [PSCustomObject]@{
					original = "$anydesk_folder\$file_to_rename"
					backup   = "$anydesk_folder\$file_to_rename.bak"
				}
				if ($global:debug) { Write-Output $file_path | Format-List }
			
				If (Test-Path -Path $file_path.backup -PathType Leaf) {
					Write-Host ''
					Write-Host ' Removing old backups...'
					add_label $form "$($title.symbol)Removing old backups..." $title.x ($y.base += $title.y) $title.font $title.color $y.added

					Remove-Item -Path $file_path.backup -Force

					add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
					$y.base += $y.space
				}
			
				If (Test-Path -Path $file_path.original -PathType Leaf) {
					Write-Host ''
					Write-Host ' Making backup of affected files...'

					add_label $form "$($title.symbol)Making backup of affected files..." $title.x ($y.base += $title.y) $title.font $title.color $y.added

					Rename-Item -Path $file_path.original -NewName $file_path.backup -Force
					
					add_label $form "$($subtitle.symbol.success)Completed" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.success $y.added
					$y.base += $y.space
				}
			}
		
			Write-Host ''
			show_title 'Process Finished'
			add_label $form "$($title.symbol)Process finished!" $title.x ($y.base += $title.y) $title.font $title.color $y.added
			add_label $form "$($subtitle.symbol.exit)You can close the window" $subtitle.x ($y.base += $subtitle.y) $subtitle.font $subtitle.color.exit $y.added
			if ($global:debug) { ''; pause }
			#quit -form $form
		})
	$form.ShowDialog()
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

function show_title {
	param (
		[Parameter(Mandatory)] [string] $title,
		[switch] $set_title
	)
	
	if ($set_title) { $Host.UI.RawUI.WindowTitle = $title }
	Write-Host "`n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  $title  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

function wait {
	param (
		[ValidateNotNullOrEmpty()]
		[int]$seconds = 3,
		
		[ValidateNotNullOrEmpty()]
		[string]$text = " Waiting"
	)
	Write-Host -NoNewLine "$text"
	for ($i = 0; $i -le $seconds; $i++) {
		Start-Sleep 1
		Write-Host -NoNewLine "."
	}
}

function quit {
	param (
		[ValidateNotNullOrEmpty()]
		[string]$text = " Exiting",
		
		[string]$runPath,
		
		[string]$runArgument,
		
		[object]$form
	)
	Write-Host ""
	wait -text $text
	if ($runPath -ne $NULL) { Start-Process $runPath $runArgument }
	Write-Host ""
	if ($NULL -ne $form) { $form.Close() }
	else { exit }
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
		Text            = $title
		ClientSize      = $client_size
		BackColor       = $back_color
		StartPosition   = "CenterScreen"
		FormBorderStyle = 1	# FormBorderStyle.FixedSingle
	}
	if ($icon) { $form.Icon = New-Object System.Drawing.Icon $icon }
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
		Text                       = $text
		Location                   = New-Object System.Drawing.Point($x, $y)
		Font                       = $font
		ForeColor                  = $text_color
		AutoSize                   = $TRUE
		UseCompatibleTextRendering = $TRUE
	}
	$form.controls.Add($label)
	$form.Height = $y + $added_height
	[System.Windows.Forms.Application]::DoEvents()
	$label
}

function hide_window {
	param (
		[bool]$hide = $TRUE
	)
	if (-not ("win32.user32" -as [type])) { 
		Add-Type -Name user32 -NameSpace win32 -MemberDefinition '
			[DllImport("user32.dll")]
			public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
		$global:console_handle = (get-process -id $pid).mainWindowHandle
	}
	$NULL = [win32.user32]::ShowWindow($console_handle, $(if ($hide) { 0 } else { 5 }))
}

############################## RUN MAIN CODE ##############################

main