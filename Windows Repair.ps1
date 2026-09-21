
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Minimized'
$global:title = 'Windows Repair'
$global:script_args = $args

############################## VARIABLES ##############################

$icon = @{
	path  = "$env:SystemRoot\System32\imageres.dll"
	index = 143
}

$actions = @(
	@{
		title = '   Clean Disk'
		code  = @(
			{ Start-Process 'CleanMgr' <# #> -Wait }
			#{ Start-Process 'CleanMgr' '/LowDisk' -Wait }
			#{ Start-Process 'CleanMgr' '/VeryLowDisk' -Wait }
		)
	},
	@{
		title           = '   Check Disk'
		needs_restart   = $TRUE
		code            = @(
			{ ChkDsk /Scan /Perf } #/R
			#{ ChkDsk /F } #/R
		)
		total_stages    = 3	# /Scan reports 3 stages; set to 5 when enabling /R
		percentage_code = {
			param ([string]$log, [object]$action)
			try {
				$last_stage = [int]($log | Select-String 'Stage (\d+)' -AllMatches).Matches[-1].Groups[1].Value
				return $last_stage * 100 / $action.total_stages
			}
			catch {
				return 0
			}
		}
		#log_code = {return (Get-EventLog -LogName 'Application' -Source 'ChkDsk')[0].Message}
	},
	@{
		title           = '   Repair Windows Image'
		needs_restart   = $TRUE
		code            = @(	# one scriptblock per command, so each is error-checked separately
			#{ Dism /Online /Cleanup-Image /ScanHealth },
			{ Dism /Online /Cleanup-Image /RestoreHealth }, #/Source:D:\sources\install.wim /LimitAccess
			#{ Dism /Online /Cleanup-Image /AnalyzeComponentStore },
			{ Dism /Online /Cleanup-Image /StartComponentCleanup } #/ResetBase
		)
		percentage_code = {
			param ([string]$log, [object]$action)
			try {
				$percentage = [int]($log | Select-String '(\d+)\.\d+%' -AllMatches).Matches[-1].Groups[1].Value
				return $percentage
			}
			catch {
				return 0
			}
		}
		#log_code = {return (Get-Content -Path "$env:WinDir\Logs\DISM\DISM.log") -Join "`r`n"}
	},
	@{
		title           = '   Repair System Files'
		needs_restart   = $TRUE
		code            = @(
			{ Sfc /ScanNow }
		)
		percentage_code = {
			param ([string]$log, [object]$action)
			try {
				$percentage = [int]($log | Select-String '(\d+)%' -AllMatches).Matches[-1].Groups[1].Value
				return $percentage
			}
			catch {
				return 0
			}
		}
		#log_code = {return (Get-Content -Path "$env:WinDir\Logs\CBS\CBS.log") -Join "`r`n"}
	},
	@{
		title = '   Optimize Disk'
		code  = @(
			{ Start-Process 'DfrGui' -Wait }
		)
	}
)

$global:error_check_code = {
	if (-not ($? -and $LastExitCode -in (0, $NULL))) { Throw "Operation failed, with exit code: $LastExitCode" }
}

# indent of a status row: starts the whole row under the title's text, clear of the title's icon
$global:indent = 36

# views carry appearance only - the TableLayoutPanel owns every position
$views = @{
	title               = @{
		font  = 'Segoe UI, 13'
		color = 'Black'
	}
	queued              = @{
		text  = ' Queued'
		font  = 'Segoe UI Semibold, 10'
		color = 'RoyalBlue'
	}
	success             = @{
		text          = ' Completed'
		font          = 'Segoe UI Semibold, 10'
		color         = 'DarkGreen'
		console_color = 'DarkGreen'
	}
	fail                = @{
		text          = ' Aborted'
		font          = 'Segoe UI Semibold, 10'
		color         = 'Crimson'
		console_color = 'DarkRed'
	}
	select_all_button   = @{
		text  = '[Select all]'
		font  = 'Segoe UI Symbol, 10'
		color = 'RoyalBlue'
	}
	deselect_all_button = @{
		text  = '[Deselect all]'
		font  = 'Segoe UI Symbol, 10'
		color = 'RoyalBlue'
	}
	ok_button           = @{
		text   = ''
		font   = 'Segoe UI Symbol, 13'
		color  = 'White'
		back   = 'DarkGreen'
		height = 30
	}
	progressbar         = @{
		height = 10
	}
	open_log_button     = @{
		text   = 'Log'
		font   = 'Segoe UI Semibold, 10'
		color  = 'White'
		back   = 'RoyalBlue'
		height = 24
	}
	textarea            = @{
		font       = 'Consolas, 9'
		multiline  = $TRUE
		scrollbars = 'both'
		wordwrap   = $FALSE	# increases loading speed dramatically
	}
	exit                = @{
		text          = 'A restart is required!'
		font          = 'Segoe UI Semibold, 10'
		color         = 'RoyalBlue'
		console_color = 'DarkCyan'
	}
	close               = @{
		text          = 'You can close the window'
		font          = 'Segoe UI Semibold, 10'
		color         = 'RoyalBlue'
		console_color = 'DarkCyan'
	}
	restart_button      = @{
		text   = ' Restart Now'
		font   = 'Segoe UI Semibold, 10'
		color  = 'White'
		back   = 'Crimson'
		height = 30
	}
	close_button        = @{
		text   = ' Close Window'
		font   = 'Segoe UI Semibold, 10'
		color  = 'White'
		back   = 'RoyalBlue'
		height = 30
	}
}

############################## MAIN CODE ##############################

function main {
	run_as_admin
	
	if (-not $global:debug) { hide_powershell }
	
	Write-Host "`n===============  $global:title  ===============`n"
	$form = make_form $global:title $icon '260, 0' -autosize
	$form.Add_KeyDown({ if ($_.KeyCode -eq 'Enter') { $this.DialogResult = 'OK' } })
	$form.Add_Closing({ if ($this.DialogResult -eq 'OK' -and -not ($actions | Where-Object { $_.checkbox.checked })) { $_.Cancel = $TRUE } })

	$select_all_button = add_row $form 'button' $views.select_all_button
	$select_all_button.Add_Click({
			if ($actions | Where-Object { $_.checkbox.checked }) { $form.DialogResult = 'OK' }
			else { $actions | ForEach-Object { $_.checkbox.checked = $TRUE } }
		})
	
	$deselect_all_button = add_row $form 'button' $views.deselect_all_button -align 'Right'
	$deselect_all_button.Add_Click({ $actions | ForEach-Object { $_.checkbox.checked = $FALSE } })
	
	$actions | ForEach-Object { $_.checkbox = add_row $form 'checkbox' $views.title $_.title -span 2 }

	$ok_button = add_row $form 'button' $views.ok_button -align 'Fill' -span 2
	$ok_button.Add_Click({ $form.DialogResult = 'OK' })
	
	$NULL = $form.ShowDialog()
	if ($form.DialogResult -eq 'Cancel') { exit }
	
	$form = make_form $global:title $icon '300, 0' -autosize
	$form.Add_Closing({
			$exit_prompt = [System.Windows.Forms.MessageBox]::Show('You are about to exit the application!', 'Exit Application', 'OKCancel', 'Warning')
			if ($exit_prompt -eq 'OK') { Start-Process 'TaskKill' "/f /t /pid $pid" -WindowStyle 'Hidden' }
			else { $_.Cancel = $TRUE }
		})
	
	$actions | ForEach-Object {
		if ($_.checkbox.Checked) {
			$NULL = add_row $form 'label' $views.title $_.title -span 2
			$_.slot = add_slot $form -name $_.title -span $(if ($_.percentage_code) { 1 } else { 2 })
			$NULL = set_slot $_.slot 'label' $views.queued
			if ($_.percentage_code) { $_.log_button = add_log_button $form $views $_ }	# built up front, but hidden until the action starts
		}
	}

	$form.Add_Shown({
			$actions | ForEach-Object { if ($_.checkbox.Checked) { run_action $this $views $_ } }
			finish $this $views
		})
	
	$form.ShowDialog()
}

############################## FUNCTIONS ##############################

function run_as_admin {
	$has_admin_rights = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
	if (-not $has_admin_rights) {
		Start-Process 'powershell' '-NoProfile -ExecutionPolicy Bypass', $(		if ($NULL -ne $PSCommandPath) { "-File `"$PSCommandPath`" $global:script_args" } else { $MyInvocation.MyCommand.Definition -replace '"', "'" }) -WorkingDirectory $pwd -Verb 'RunAs' -WindowStyle $(if ($global:debug) { 'Normal' } else { $global:display })
		if ($global:debug) { pause }
		exit
	}
}

function hide_powershell {
	param ([bool] $hide = $TRUE)
	
	Add-Type -Name 'user32' -NameSpace 'win32' -MemberDefinition '
		[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
		[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
	'

	if (-not (Test-Path variable:global:console_handle)) { $global:console_handle = [win32.user32]::GetConsoleWindow() }	# MainWindowHandle is 0 in some hosts, GetConsoleWindow is not
	if ($global:console_handle -eq [IntPtr]::Zero) { return }
	[win32.user32]::ShowWindow($global:console_handle, $(if ($hide) { 0 } else { 5 }))
}

function clamp_percentage {
	param ([int] $value)
	
	if ($value -lt 0) { return 0 }	# ProgressBar.Value throws outside 0-100
	if ($value -gt 100) { return 100 }
	$value
}

function make_form {
	param (
		[parameter(Mandatory)] [string] $title,
		[object] $icon,
		[string] $client_size = '300, 0',
		[string] $border = 'FixedSingle',	# Not resizable
		[string] $back_color = '#ffffff',
		[switch] $autosize
	)

	Add-Type -AssemblyName 'System.Windows.Forms'
	[System.Windows.Forms.Application]::EnableVisualStyles()

	$form = New-Object 'System.Windows.Forms.Form' -Property @{
		Text            = $title
		ClientSize      = $client_size
		FormBorderStyle	= $border
		BackColor       = $back_color
		StartPosition   = 'CenterScreen'
		KeyPreview      = $TRUE
		MaximizeBox     = $FALSE
	}
	
	$form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape') { $form.close() } })
	
	if ($icon) { set_form_icon $form $icon }
	set_form_app_id $form $title	# Set Form Icon as Taskbar Icon
	
	if ($autosize) {
		$form.AutoSize = $TRUE
		$form.AutoSizeMode = 'GrowOnly'	# GrowAndShrink collapses the form to its widest control and truncates labels
	}
	
	$stack = New-Object 'System.Windows.Forms.TableLayoutPanel' -Property @{
		ColumnCount = 2
		AutoSize    = $TRUE
		Dock        = 'Top'	# not Fill: a filled panel hands its spare height to the last row, which then re-centres that row's contents
		Padding     = New-Object 'System.Windows.Forms.Padding' 8
	}
	$stack.Add_SizeChanged({ $this.FindForm().ClientSize = New-Object 'System.Drawing.Size' $this.FindForm().ClientSize.Width, $this.Height })	# trim the form's autosize slack so the bottom margin matches the top, on every row added
	$NULL = $stack.ColumnStyles.Add((New-Object 'System.Windows.Forms.ColumnStyle' 'Percent', 100))	# column 1 absorbs slack so 'Right' lands on the edge
	$NULL = $stack.ColumnStyles.Add((New-Object 'System.Windows.Forms.ColumnStyle' 'AutoSize'))
	$form.Controls.Add($stack)
	$form | Add-Member -NotePropertyName 'stack' -NotePropertyValue $stack
	
	$form
}

function style_control {
	param (
		[parameter(Mandatory)] [object] $control,
		[parameter(Mandatory)] [string] $type,
		[parameter(Mandatory)] [object] $view,
		[string] $text
	)
	
	switch ($type) {
		{ @('label', 'checkbox', 'button', 'textbox') -contains $_ } {
			$control.Text = $text
			$control.Font = $view.font
		}
		
		{ @('label', 'checkbox', 'button') -contains $_ } {
			$control.ForeColor = $view.color
			$control.UseCompatibleTextRendering = $TRUE
		}
		
		{ @('checkbox', 'button') -contains $_ } {
			$control.Cursor = 'Hand'	# only on what is actually clickable - labels keep the arrow
		}
		
		'button' {
			$control.FlatStyle = 'Flat'
			$control.FlatAppearance.BorderSize = 0
		}
		
		'progressbar' {
			$control.Style = 'Marquee'
			$control.MarqueeAnimationSpeed = 20
		}
		
		'textbox' {
			$control.MultiLine = $view.multiline
			$control.ScrollBars = $view.scrollbars
			$control.WordWrap = $view.wordwrap
		}
	}
	
	if ($NULL -ne $view.back) { $control.BackColor = $view.back }
	if ($NULL -ne $view.height) { $control.Height = $view.height }
}

function add_row {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [string] $type,
		[parameter(Mandatory)] [object] $view,
		[string] $text = $view.text,
		[string] $name,
		[string] $align = 'Left',	# Left | Right | Fill
		[int] $span = 1,
		[int] $indent = 0,
		[switch] $tight	# no gap above: keeps a sub-message attached to the line it belongs to
	)
	
	$control = New-Object "System.Windows.Forms.$type" -Property @{
		AutoSize = $($NULL -eq $view.height)
		Margin   = New-Object 'System.Windows.Forms.Padding' $indent, $(if ($tight) { 0 } else { 3 }), 0, 3
		Name     = "$type $name"
	}
	
	style_control $control $type $view $text
	$control.Anchor = $(switch ($align) { 'Right' { 'Right' } 'Fill' { 'Left, Right' } default { 'Left' } })	# no Top: the row centres it, so neighbours of different heights line up
	
	$form.stack.Controls.Add($control)
	if ($span -gt 1) { $form.stack.SetColumnSpan($control, $span) }
	
	[System.Windows.Forms.Application]::DoEvents()
	
	$control
}

# a slot is a one-cell host: swapping its child never disturbs the surrounding rows
function add_slot {
	param (
		[parameter(Mandatory)] [object] $form,
		[string] $name,
		[int] $span = 1
	)
	
	$slot = New-Object 'System.Windows.Forms.Panel' -Property @{
		AutoSize     = $TRUE
		AutoSizeMode = 'GrowAndShrink'
		Margin       = New-Object 'System.Windows.Forms.Padding' $global:indent, 0, 0, 0
		Anchor       = 'Left'	# no Top: let the row centre it, so it lines up with a taller neighbour
		Name         = "slot $name"
	}
	
	$form.stack.Controls.Add($slot)
	if ($span -gt 1) { $form.stack.SetColumnSpan($slot, $span) }
	
	$slot
}

function set_slot {
	param (
		[parameter(Mandatory)] [object] $slot,
		[parameter(Mandatory)] [string] $type,
		[parameter(Mandatory)] [object] $view,
		[string] $text = $view.text
	)
	
	$slot.Controls | ForEach-Object { $_.Dispose() }
	$slot.Controls.Clear()
	
	$control = New-Object "System.Windows.Forms.$type" -Property @{ AutoSize = $($NULL -eq $view.height) }
	style_control $control $type $view $text
	
	if ($type -eq 'progressbar') {
		$widths = $slot.Parent.GetColumnWidths()
		$first = $slot.Parent.GetPositionFromControl($slot).Column	# GetColumn returns -1 for auto-placed controls, and PowerShell reads [-1] as the LAST column
		$span = $slot.Parent.GetColumnSpan($slot)
		$cell = ($widths[$first..($first + $span - 1)] | Measure-Object -Sum).Sum
		$control.Width = $cell - $slot.Margin.Left - $(if ($first + $span -ge $widths.Count) { $slot.Parent.Padding.Right } else { 0 })
	}
	
	$slot.Controls.Add($control)
	[System.Windows.Forms.Application]::DoEvents()
	
	$control
}

function add_log_button {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [object] $views,
		[parameter(Mandatory)] [object] $action
	)
	
	$log_button = add_row $form 'button' $views.open_log_button -name $action.title -align 'Right' -indent 12	# indent = breathing room between the progress bar and this button
	$log_button.Visible = $FALSE	# nothing to show while the action is still queued
	$log_button.Width = 64
	
	$log_button.Add_Click({
			$action_title = $this.Name.split(' ', 2)[-1]
			$action = $actions | Where-Object { $_.title -eq $action_title }
			
			if ($action.log_form -and -not $action.log_form.IsDisposed) { $action.log_form.Activate(); return }	# reuse the window instead of stacking copies
			
			$log_form = New-Object 'System.Windows.Forms.Form' -Property @{
				Text            = "$($action_title.substring(2)): Log"
				ClientSize      = New-Object 'System.Drawing.Size' 657, 502
				FormBorderStyle = 'Sizable'
				BackColor       = '#ffffff'
				StartPosition   = 'CenterScreen'
				MaximizeBox     = $TRUE
			}
			if ($icon) { set_form_icon $log_form $icon }
			
			$log_textbox = New-Object 'System.Windows.Forms.TextBox' -Property @{
				Dock     = 'Fill'
				ReadOnly = $TRUE
				Font     = $views.textarea.font
			}
			$log_textbox.MultiLine = $views.textarea.multiline
			$log_textbox.ScrollBars = $views.textarea.scrollbars
			$log_textbox.WordWrap = $views.textarea.wordwrap
			$log_form.Controls.Add($log_textbox)
			$log_textbox.AppendText($action.log)
			
			$action.log_form = $log_form
			$action.log_textbox = $log_textbox	# run_action appends here while the job streams
			$log_form.Add_FormClosed({ $action.log_form = $NULL; $action.log_textbox = $NULL }.GetNewClosure())
			
			$log_form.Show()	# Show not ShowDialog: a modal window would freeze the polling loop that feeds it
			
			$log_textbox.SelectionStart = $log_textbox.TextLength	# scroll to the newest output - ScrollToCaret needs the handle, so this runs after Show
			$log_textbox.SelectionLength = 0
			$log_textbox.ScrollToCaret()
		})
	
	$log_button
}

function append_log {
	param (
		[parameter(Mandatory)] [object] $action,
		[parameter(Mandatory)] [string] $chunk
	)
	
	$action.log += $chunk
	if ($action.log_textbox -and -not $action.log_textbox.IsDisposed) { $action.log_textbox.AppendText($chunk) }	# AppendText auto-scrolls; setting .Text would reset the caret
}

# drains whatever the job has emitted since the last poll into the action log, and hands the chunk back for the per-command log
function drain_job {
	param (
		[parameter(Mandatory)] [object] $job,
		[parameter(Mandatory)] [object] $action
	)
	
	$new = Receive-Job -Job $job 2>&1	# no -Keep: drains only what arrived since the last poll, so the log streams live
	if (-not $new) { return '' }
	
	$chunk = (($new | ForEach-Object { "$_" }) -Join "`r`n") + "`r`n"
	append_log $action $chunk
	$chunk
}

# each command owns an equal slice of the bar, so a multi-command action never restarts the bar at 0
function set_progress {
	param (
		[parameter(Mandatory)] [object] $progressbar,
		[parameter(Mandatory)] [object] $action,
		[parameter(Mandatory)] [AllowEmptyString()] [string] $command_log,
		[parameter(Mandatory)] [int] $index,
		[parameter(Mandatory)] [int] $count
	)
	
	$percentage = clamp_percentage (Invoke-Command -ScriptBlock $action.percentage_code -ArgumentList $command_log, $action)	# measured against THIS command's output only - the full log still holds the previous command's trailing 100%
	$overall = clamp_percentage (($index * 100 + $percentage) / $count)
	if ($overall -gt $progressbar.Value) { $progressbar.Value = $overall }	# never backwards: jitter in the source output would read as a restart
}

function run_action {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [object] $views,
		[parameter(Mandatory)] [object] $action
	)

	$form.Cursor = 'WaitCursor'

	if ($global:debug) { $form.Add_KeyDown({ if ($_.KeyCode -eq 'Escape' -and $job.State -eq 'Running') { Stop-Job -Job $job } }) }

	Write-Host "`n $($action.title)"
	if ($action.log_button) { $action.log_button.Visible = $TRUE }	# revealed on running, and stays for the finished state - before set_slot, which sizes the bar from the column widths this widens
	$progressbar = set_slot $action.slot 'progressbar' $views.progressbar
	if ($action.percentage_code) { $progressbar.Style = 'Continuous' }

	$job_state = 'Completed'
	$index = 0
	foreach ($command in $action.code) {	# one job per command: each gets its own progress slice, and a failure stops the rest
		$checked_code = "$command `n ${global:error_check_code}"	# check exit code after EVERY command, not just the last
		$job = Start-Job -ScriptBlock ([ScriptBlock]::Create($checked_code)) -ArgumentList $action.code_arguments
		$command_log = ''
		do {
			$command_log += drain_job $job $action
			
			if ($action.percentage_code) { set_progress $progressbar $action $command_log $index $action.code.Count }
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 50	# without this the loop spins ~3800x/sec, pegging a core for the whole run
		} until ($job.State -ne 'Running')
		
		$command_log += drain_job $job $action	# final drain: whatever landed between the last poll and the job ending
		$job_state = $job.State
		Remove-Job -Job $job -Force
		
		if ($job_state -ne 'Completed') { break }	# abort the action on the first failed command, as the single-job version did
		$index++
		if ($action.percentage_code) { $progressbar.Value = clamp_percentage ($index * 100 / $action.code.Count) }	# close the slice: the source rarely prints a final 100%
	}
	
	$result_view = $(If ($job_state -eq 'Completed') { $views.success } else { $views.fail })
	Write-Host "`n --- $($result_view.text) ---" -ForegroundColor $result_view.console_color
	
	$NULL = set_slot $action.slot 'label' $result_view

	$form.ResetCursor()
}

function finish {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [object] $views,
		[string] $text = '   Process Finished'
	)

	Write-Host "`n`n===============  $text  ===============`n"
	$NULL = add_row $form 'label' $views.title $text -span 2	# finish_label

	if (-not ($actions | Where-Object { $_.checkbox.Checked -and $_.needs_restart })) {	# Clean Disk / Optimize Disk alone need no restart
		Write-Host "`n --- $($views.close.text) ---" -ForegroundColor $views.close.console_color
		$NULL = add_row $form 'label' $views.close -span 2 -indent $global:indent -tight	# close_label
		
		$close_button = add_row $form 'button' $views.close_button -align 'Fill' -span 2
		$close_button.Add_Click({ Start-Process 'TaskKill' "/f /t /pid $pid" -WindowStyle 'Hidden' })
		return
	}

	Write-Host "`n --- $($views.exit.text) ---" -ForegroundColor $views.exit.console_color
	$NULL = add_row $form 'label' $views.exit -span 2	# exit_label

	$restart_button = add_row $form 'button' $views.restart_button -align 'Fill' -span 2
	$restart_button.Add_Click({
			Start-Process 'ShutDown' '/r /t 0' -WindowStyle 'Hidden'
			Start-Process 'TaskKill' "/f /t /pid $pid" -WindowStyle 'Hidden'
		})
}

function set_form_icon {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [object] $icon
	)

	Add-Type -TypeDefinition '
		using System;
		using System.Drawing;
		using System.Runtime.InteropServices;

		namespace System {
			public class IconExtractor {
				public static Icon Extract(string file, int number, bool largeIcon) {
					IntPtr large;
					IntPtr small;
					ExtractIconEx(file, number, out large, out small, 1);
					try {return Icon.FromHandle(largeIcon ? large : small);}
					catch {return null;}
				}
				[DllImport("Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall)]
				private static extern int ExtractIconEx(string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons);
			}
		}
	' -ReferencedAssemblies 'System.Drawing'

	$form.Icon = [System.IconExtractor]::Extract($icon.path, $icon.index, $TRUE)
}

function set_form_app_id {
	param (
		[parameter(Mandatory)] [object] $form,
		[parameter(Mandatory)] [string] $app_id
	)

	Add-Type -TypeDefinition '
		using System;
		using System.Runtime.InteropServices;
		using System.Runtime.InteropServices.ComTypes;

		public class PSAppID {
			[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")] private interface IPropertyStore {
				uint GetCount([Out] out uint cProps);
				uint GetAt([In] uint iProp, out PropertyKey pkey);
				uint GetValue([In] ref PropertyKey key, [Out] PropVariant pv);
				uint SetValue([In] ref PropertyKey key, [In] PropVariant pv);
				uint Commit();
			}
			[StructLayout(LayoutKind.Sequential, Pack = 4)] public struct PropertyKey {
				private Guid formatId;    // Unique GUID for property
				private Int32 propertyId; // Property identifier (PID)
				public Guid FormatId {get {return formatId;}}
				public Int32 PropertyId {get {return propertyId;}}
				public PropertyKey(Guid formatId, Int32 propertyId) {
					this.formatId = formatId;
					this.propertyId = propertyId;
				}
				public PropertyKey(string formatId, Int32 propertyId) {
					this.formatId = new Guid(formatId);
					this.propertyId = propertyId;
				}
			}
			[StructLayout(LayoutKind.Explicit)] public class PropVariant : IDisposable {
				[FieldOffset(0)] ushort valueType;     // Value type
				[FieldOffset(8)] IntPtr ptr;           // Value
				public VarEnum VarType {
					get {return (VarEnum)valueType;}
					set {valueType = (ushort)value;}
				}
				public bool IsNullOrEmpty {
					get {return (valueType == (ushort)VarEnum.VT_EMPTY || valueType == (ushort)VarEnum.VT_NULL);}
				}
				public string Value {get {return Marshal.PtrToStringUni(ptr);}}
				public PropVariant() {}
				public PropVariant(string value) {
					if (value == null) throw new ArgumentException("Failed to set value.");
					valueType = (ushort)VarEnum.VT_LPWSTR;
					ptr = Marshal.StringToCoTaskMemUni(value);
				}
				~PropVariant() {
					Dispose();
				}
				public void Dispose() {
					PropVariantClear(this);
					GC.SuppressFinalize(this);
				}
			}
			[DllImport("Ole32.dll", PreserveSig = false)] private extern static void PropVariantClear([In, Out] PropVariant pvar);
			[DllImport("shell32.dll")] private static extern int SHGetPropertyStoreForWindow(
				IntPtr hwnd,
				ref Guid iid /*IID_IPropertyStore*/,
				[Out(), MarshalAs(UnmanagedType.Interface)] out IPropertyStore propertyStore
			);
			public static void SetAppIdForWindow(int handle, string AppId) {
				Guid iid = new Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99");
				IPropertyStore prop;
				int result1 = SHGetPropertyStoreForWindow((IntPtr)handle, ref iid, out prop);
				PropertyKey AppUserModelIDKey = new PropertyKey("{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", 5);
				PropVariant pv = new PropVariant(AppId);
				uint result2 = prop.SetValue(ref AppUserModelIDKey, pv);
				Marshal.ReleaseComObject(prop);
			}
		}
	'
	
	[PSAppID]::SetAppIdForWindow($form.Handle, $app_id)
}

############################## RUN MAIN CODE ##############################

main
