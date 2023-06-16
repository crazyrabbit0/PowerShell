
#-----------------------------------------------------------Administrator-----------------------------------------------------------#

$debug = 0
$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $has_admin_rights) {Start-Process -Verb RunAs -WindowStyle $(if ($debug) {"Normal"} else {"Minimized"}) -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -WorkingDirectory $pwd; exit}

#-----------------------------------------------------------Variables-----------------------------------------------------------#

$scriptTitle = (Get-Item $PSCommandPath).Basename
$icon = @{
	file = "$env:SystemRoot\System32\imageres.dll"
	index = 143
}

$views = @{
	title = @{
		top = 35
		left = 10
		font = "Segoe UI, 13"
		color = "Black"
	}
	queued = @{
		top = 30
		left = 30
		text = " Queued"
		font = "Segoe UI Semibold, 10"
		color = "RoyalBlue"
	}
	success = @{
		top = 30
		left = 30
		text = " Completed"
		font = "Segoe UI Semibold, 10"
		color = "DarkGreen"
		console_color = "DarkGreen"
	}
	fail = @{
		top = 30
		left = 30
		text = " Aborted"
		font = "Segoe UI Semibold, 10"
		color = "Crimson"
		console_color = "DarkRed"
	}
	select_all_button = @{
		top = 30
		left = 10
		text = "[Select all]"
		font = "Segoe UI Symbol, 10"
		color = "RoyalBlue"
	}
	deselect_all_button = @{
		top = 0
		left = "end"
		text = "[Deselect all]"
		font = "Segoe UI Symbol, 10"
		color = "RoyalBlue"
	}
	ok_button = @{
		top = 45
		left = 10
		width = "full"
		height = 30
		text = ""
		font = "Segoe UI Symbol, 13"
		color = "White"
		back = "DarkGreen"
	}
	cancel_button = @{
		top = 0
		left = 140
		text = ""
		font = "Segoe UI Symbol, 13"
		color = "White"
		back = "Crimson"
	}
	progressbar = @{
		top = 30
		left = 15
		width = "full"
		height = 10
	}
	open_log_button = @{
		top = 0
		left = 30
		text = "  Open Log"
		font = "Segoe UI Semibold, 10"
		color = "RoyalBlue"
		#back = "RoyalBlue"
	}
	textarea = @{
		top = 20
		left = 15
		width = "full"
		height = "full"
		multiline = $true
		scrollbars = "both"
		wordwrap = $false	# increases loading speed dramatically
	}
	exit = @{
		top = 30
		left = 30
		text = "A restart is required to finish the repair!"
		font = "Segoe UI Semibold, 10"
		color = "RoyalBlue"
		console_color = "DarkCyan"
	}
	restart_button = @{
		top = 30
		left = 10
		width = "full"
		height = 30
		text = " Restart Now"
		font = "Segoe UI Semibold, 10"
		color = "White"
		back = "Crimson"
	}
}
$global:padding = @{
	top = 1
	bottom = 50
}
$global:actual_top = 0

$actions = @(
	@{
		title = " Clean Disk"
		code = {
			Start-Process -FilePath "CleanMgr" -Wait
			#Start-Process -FilePath "CleanMgr" -ArgumentList "/LowDisk" -Wait
			#Start-Process -FilePath "CleanMgr" -ArgumentList "/VeryLowDisk" -Wait
		}
	},
	@{
		title = " Check Disk"
		code = {
			ChkDsk /Scan /Perf #/R
			#ChkDsk /F #/R
		}
		percentage_code = {
			Param ([object]$job)
			try {
				$last_stage = [int](Receive-job -Job $job -Keep | Select-String 'Stage (\d+)').Matches[-1].Groups[1].Value
				return $last_stage * 33
			}
			catch {return 0}
		}
		log_code = {if ($LastExitCode -eq 0) {return [string](Get-EventLog -LogName "Application" -Source "ChkDsk")[0].Message}}
	},
	@{
		title = " Repair Windows Image"
		code = {
			#Dism /Cleanup-Wims
			#Dism /Online /Cleanup-Image /CheckHealth
			#Dism /Online /Cleanup-Image /ScanHealth
			#Dism /Online /Cleanup-Image /StartComponentCleanup #/ResetBase
			#Dism /Online /Cleanup-Image /AnalyzeComponentStore
			Dism /Online /Cleanup-Image /RestoreHealth #/Source:D:\sources\install.wim /LimitAcces
		}
		percentage_code = {
			Param ([object]$job)
			try {
				$percentage = [int](Receive-job $job -Keep | Select-String '(\d+)\.\d+%').Matches[-1].Groups[1].Value
				return $percentage
			}
			catch {return 0}
		}
		log_code = {return (Get-Content -Path "$env:WinDir\Logs\DISM\DISM.log") -Join "`r`n"}
	},
	@{
		title = " Repair System Files"
		code = {
			Sfc /ScanNow
		}
		percentage_code = {
			Param ([object]$job)
			try {
				$percentage_string = (Receive-job $job -Keep | Select-String '\s+(.+)%').Matches[-1].Groups[1].Value
				$percentage = [int]($percentage_string -Replace $percentage_string[0], '')
				return $percentage
			}
			catch {return 0}
		}
		log_code = {return (Get-Content -Path "$env:WinDir\Logs\CBS\CBS.log") -Join "`r`n"}
	},
	@{
		title = " Optimize Disk"
		code = {
			Start-Process -FilePath "DfrGui" -Wait
		}
	}
)
$global:error_check_code = {if (-not ($? -and $LastExitCode -in (0, $null))) {Throw "Operation failed, with exit code: $LastExitCode"}}

#-----------------------------------------------------------Main Code-----------------------------------------------------------#

function main {
	param ([String[]] $argz)
	
	if (-not $debug) {hide_powershell}
	
	Write-Host "`n===============  $scriptTitle  ===============`n"
	$form = make_form $scriptTitle $icon "260, 0"
	$form.Add_KeyDown({if ($_.KeyCode -eq "Enter") {$this.DialogResult = "OK"}})
	$form.Add_Closing({if ($this.DialogResult -eq "OK" -and -not ($actions | Where-Object {$_.checkbox.checked})) {$_.Cancel = $true}})
	add_control $form "button" $views.select_all_button | ForEach-Object {
		$_.Add_Click({
			if ($actions | Where-Object {$_.checkbox.checked}) {$form.DialogResult = "OK"}
			else {$actions | ForEach-Object {$_.checkbox.checked = $true}}
		})
	}
	add_control $form "button" $views.deselect_all_button | ForEach-Object {
		$_.Add_Click({$actions | ForEach-Object {$_.checkbox.checked = $false}})
	}
	$actions | ForEach-Object {$_.checkbox = add_control $form "checkbox" $views.title $_.title}
	add_control $form "button" $views.ok_button | ForEach-Object {
		$_.Add_Click({$form.DialogResult = "OK"})
	}
	$null = $form.ShowDialog()
	
	if ($form.DialogResult -eq "Cancel") {exit}
	
	$form = make_form $scriptTitle $icon
	$form.Add_Closing({
		$exit_prompt = [System.Windows.Forms.MessageBox]::Show("You are about to exit the application!", "Exit Application", "OKCancel", "Warning")
		if ($exit_prompt -eq "OK") {Start-Process -FilePath "TaskKill" -ArgumentList "/f /t /pid $pid" -WindowStyle "Hidden"}
		else {$_.Cancel = $true}
	})
	$actions | ForEach-Object {if ($_.checkbox.Checked) {
		$null = add_control $form "label" $views.title $_.title
		$null = add_control $form "label" $views.queued -name $_.title
	}}
	$form.Add_Shown({
		$actions | ForEach-Object {
			if ($_.checkbox.Checked) {run_action $this $views $_}
		}
		finish $this $views
	})
	$form.ShowDialog()
}

#-----------------------------------------------------------Functions-----------------------------------------------------------#

function hide_powershell {
	param ([bool]$hide = $true)
	if (-not (Test-Path variable:global:console_handle)) {$global:console_handle = (get-process -id $pid).mainWindowHandle}
	Add-Type -Name user32 -NameSpace win32 -MemberDefinition '
		[DllImport("user32.dll")]
		public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
	[win32.user32]::ShowWindow($global:console_handle, $(if ($hide) {0} else {5}))
}

function make_form {
	param (
        [Parameter(Mandatory)]
        [string]$title,
		
        [object]$icon,
		
        [string]$client_size = "300, 0",
		
		[string]$border = "FixedSingle",	# Not resizable
		
        [string]$back_color = "#ffffff"
    )
	Add-Type -AssemblyName System.Windows.Forms
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form = New-Object System.Windows.Forms.Form -Property @{
		Text = $title
		ClientSize = $client_size
		FormBorderStyle = $border
		BackColor = $back_color
		StartPosition = "CenterScreen"
		KeyPreview = $true
		MaximizeBox = $false
	}
	$form.Add_KeyDown({if ($_.KeyCode -eq "Escape") {$form.close()}})
	if ($icon) {set_form_icon $form $icon}
	set_form_app_id $form $title	# Set Form Icon as Taskbar Icon
	$global:actual_top = 0
	$form
}

function add_control {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [object]$type,
		
        [Parameter(Mandatory)]
        [object]$view,
		
        [string]$text = $view.text,
		
        [string]$name,
		
        [switch]$anchored
    )
	$global:actual_top += $(if ($global:actual_top -eq 0) {$global:padding.top} else {$view.top})
	$control = New-Object System.Windows.Forms.$type -Property @{
		Top = $global:actual_top
		Name = "$type $name"
	}
	$control | ForEach-Object {
		if ($type -in @("label", "checkbox", "button", "textbox")) {
			$_.Text = $text
			$_.Font = $view.font
		}
		if ($type -in @("label", "checkbox", "button")) {
			$_.ForeColor = $view.color
			$_.UseCompatibleTextRendering = $true
		}
		if ($type -in @("checkbox", "button")) {
			$_.Cursor = "Hand"
		}
		if ($type -eq "button") {
			$_.FlatStyle = "Flat"
			$_.FlatAppearance.BorderSize = 0
		}
		elseif ($type -eq "progressbar") {
			$_.Style = "Marquee"
			$_.MarqueeAnimationSpeed = 20
		}
		elseif ($type -eq "textbox") {
			$_.MultiLine = $view.multiline
			$_.ScrollBars = $view.scrollbars
			$_.WordWrap = $view.wordwrap
		}
		if ($view.back -ne $null) {$_.BackColor = $view.back}
		if ($view.height -eq $null -and $view.width -eq $null) {$control.AutoSize = $true}
		else {
			if ($view.height -eq "full") {$_.height = $form.height - $view.top * 2 - 16}
			else {$_.height = $view.height}
			if ($view.width -eq "full") {$_.width = $form.width - $view.left * 2 - 16}
			else {$_.width = $view.width}
		}
		if ($view.left -eq "end") {$_.Left = $form.width - $control.width - 44} else {$_.Left = $view.left}
		if ($anchored) {$_.Anchor = "Top, Left, Right, Bottom"}
	}
	$form.Controls.Add($control)
	if ($view.bottom -ne $null) {$global:actual_top += $view.bottom}
	$form.Height = $global:actual_top + $control.height + $global:padding.bottom
	[System.Windows.Forms.Application]::DoEvents()
	$control
}

function replace_control {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [string]$control_name,
		
        [Parameter(Mandatory)]
        [object]$new_type,
		
        [Parameter(Mandatory)]
        [object]$new_view
    )
	$top = $form.Controls[$control_name].top
	$form.Controls[$control_name].Dispose()
	$new_control = add_control $form $new_type $new_view -name $control_name.split(" ", 2)[-1]
	$new_control.Top = $top
	$global:actual_top -= $new_view.top
	$new_control
}

function add_log_button {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [object]$views,
		
        [Parameter(Mandatory)]
        [object]$action,
		
        [Parameter(Mandatory)]
        [object]$result_label
    )
	add_control $form "button" $views.open_log_button -name $action.title | ForEach-Object {
		$_.Top = $result_label.Top - 6
		$_.Left += $result_label.Left + $result_label.Width
		$_.BringToFront()
		$_.Add_Click({
			$action_title = $this.Name.split(" ", 2)[-1]
			make_form "$action_title - Log" $icon "1000, 500" "Sizable" | ForEach-Object {
				$_.MaximizeBox = $true
				add_control $_ "textbox" $views.textarea -anchored | ForEach-Object {
					$_.AppendText(($actions | Where-Object {$_.title -eq $action_title}).log)
				}
				$_.ShowDialog()
			}
		})
	}
}

function run_action {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [object]$views,
		
        [Parameter(Mandatory)]
        [object]$action
    )
	$form.Cursor = "WaitCursor"
	if ($debug) {$form.Add_KeyDown({if ($_.KeyCode -eq "Escape" -and $job.State -eq "Running") {Stop-Job -Job $job}})}
	Write-Host "`n $($action.title)"
	$progressbar = replace_control $form "label $($action.title)" "progressbar" $views.progressbar
	if ($action.percentage_code) {$progressbar.Style = "Continuous"}
	$job = Start-Job -ScriptBlock ([ScriptBlock]::Create("$($action.code) `n ${global:error_check_code}")) -ArgumentList $action.code_arguments #| Receive-Job -AutoRemoveJob -Wait
	do {
		if ($action.percentage_code) {$progressbar.Value = Invoke-Command -ScriptBlock $action.percentage_code -ArgumentList $job}
		[System.Windows.Forms.Application]::DoEvents()
	} until ($job.State -ne "Running")
	$action.log = ((Receive-Job -Job $job -AutoRemoveJob -Wait) -Join "`r`n") + $(if ($action.log_code) {"`r`n"*5 + "="*60 + "Verbose Log" + "="*60 + "`r`n"*5 + (Invoke-Command -ScriptBlock $action.log_code)})
	$result_view = $(If ($job.State -eq "Completed") {$views.success} else {$views.fail})
	Write-Host "`n --- $($result_view.text) ---" -ForegroundColor $result_view.console_color
	$result_label = replace_control $form "progressbar $($action.title)" "label" $result_view
	if ($action.percentage_code) {add_log_button $form $views $action $result_label}
	$form.ResetCursor()
}

function finish {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [object]$views,
		
        [string]$text = " Process Finished"
    )
	Write-Host "`n`n===============  $text  ===============`n"
	add_control $form "label" $views.title "$text"
	Write-Host "`n --- $($views.exit.text) ---" -ForegroundColor $views.exit.console_color
	add_control $form "label" $views.exit
	add_control $form "button" $views.restart_button | ForEach-Object {
		$_.Add_Click({Start-Process -FilePath "ShutDown" -ArgumentList "\R \T 0"})
	}
}

function set_form_icon {
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [object]$icon
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
	' -ReferencedAssemblies System.Drawing
	$form.Icon = [System.IconExtractor]::Extract($icon.file, $icon.index, $true)
}

function set_form_app_id{
	param (
        [Parameter(Mandatory)]
        [object]$form,
		
        [Parameter(Mandatory)]
        [string]$app_id
    )
	Add-Type -TypeDefinition '
		using System;
		using System.Runtime.InteropServices;
		using System.Runtime.InteropServices.ComTypes;

		public class PSAppID {
			[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
				private interface IPropertyStore {
					uint GetCount([Out] out uint cProps);
					uint GetAt([In] uint iProp, out PropertyKey pkey);
					uint GetValue([In] ref PropertyKey key, [Out] PropVariant pv);
					uint SetValue([In] ref PropertyKey key, [In] PropVariant pv);
					uint Commit();
				}
			[StructLayout(LayoutKind.Sequential, Pack = 4)]
				public struct PropertyKey {
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
			[StructLayout(LayoutKind.Explicit)]
				public class PropVariant : IDisposable {
					[FieldOffset(0)]ushort valueType;     // Value type
					[FieldOffset(8)]IntPtr ptr;           // Value
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
			[DllImport("Ole32.dll", PreserveSig = false)]private extern static void PropVariantClear([In, Out] PropVariant pvar);
			[DllImport("shell32.dll")]
				private static extern int SHGetPropertyStoreForWindow(
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

#-----------------------------------------------------------Run Main Code-----------------------------------------------------------#

main $args