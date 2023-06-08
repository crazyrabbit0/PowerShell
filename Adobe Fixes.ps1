
#-----------------------------------------------------------Administrator-----------------------------------------------------------#

$debug = 0
$has_admin_rights = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $has_admin_rights) {Start-Process -Verb RunAs -WindowStyle $(if ($debug) {"Normal"} else {"Minimized"}) -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -WorkingDirectory $pwd; exit}

#-----------------------------------------------------------Variables-----------------------------------------------------------#

$scriptTitle = (Get-Item $PSCommandPath).Basename
$icon = @{
	file = "$env:SystemRoot\System32\imageres.dll"
	index = 102
}

$adobe = @{
	sync = @{
		apps = @(
			"${env:ProgramFiles(x86)}\Adobe\Adobe Sync\CoreSync\CoreSync.exe",
			"$env:ProgramFiles\Adobe\Adobe Creative Cloud Experience\CCXProcess.exe",
			"$env:CommonProgramFiles\Adobe\Creative Cloud Libraries\CCLibrary.exe"
		)
		rights = @{
			user = "Everyone"
			right = "ReadAndExecute"
			access = "Deny"
		}
		is_blocked = {}
	}
	system_library_folders = @(
		"${env:CommonProgramFiles(x86)}\Adobe\SLCache",
		"$env:ProgramData\Adobe\SLStore"
	)
}
$adobe.sync.is_blocked = (Get-Acl -Path $adobe.sync.apps).Access | Where-Object {
	$_.IdentityReference -eq $adobe.sync.rights.user -and
	$_.FileSystemRights -eq $adobe.sync.rights.right -and
	$_.AccessControlType -eq $adobe.sync.rights.access
}

$global:actual_top = 0
$global:padding = @{
	top = 1
	bottom = 50
}

$views = @{
	title = @{
		top = 30
		left = 10
		font = "Segoe UI, 13"
		color = "Black"
	}
	wait = @{
		top = 30
		left = 30
		text = " Please wait..."
		font = "Segoe UI Semibold, 10"
		color = "RoyalBlue"
	}
	success = @{
		top = 30
		left = 30
		text = " Completed"
		font = "Segoe UI Semibold, 10"
		color = "DarkGreen"
	}
	fail = @{
		top = 30
		left = 30
		text = " Aborted"
		font = "Segoe UI Semibold, 10"
		color = "Crimson"
	}
	exit = @{
		top = 30
		left = 30
		text = "You can close the window"
		font = "Segoe UI Semibold, 10"
		color = "RoyalBlue"
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
		left = 175
		text = "[Deselect all]"
		font = "Segoe UI Symbol, 10"
		color = "RoyalBlue"
	}
	ok_button = @{
		top = 40
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
}

$actions = @(
	@{
		title = " Close all Adobe Apps"
		checkbox = {}
		code = {
			Get-Process "Acrobat*" | Stop-Process -Force
			Get-Process | Where-Object Company -Match ".*Adobe.*" | Stop-Process -Force
		}
		code_arguments = {}
	},
	@{
		title = If ($adobe.sync.is_blocked) {" Unblock Adobe Sync Apps"} else {" Block Adobe Sync Apps"}
		checkbox = {}
		code = {
			foreach ($app in $args.apps) {
				$app_permissions = Get-Acl -Path $app
				$block_permission = New-Object System.Security.AccessControl.FileSystemAccessRule($args.rights.user, $args.rights.right, $args.rights.access)
				If ($args.is_blocked) {$app_permissions.RemoveAccessRule($block_permission)} else {$app_permissions.SetAccessRule($block_permission)}
				Set-Acl -Path $app -AclObject $app_permissions
			}
		}
		code_arguments = $adobe.sync
	},
	@{
		title = " Clean Adobe System Library"
		checkbox = {}
		code = {Remove-Item -Path ($args | ForEach-Object {"$_\*"}) -Force -ErrorAction SilentlyContinue}
		code_arguments = $adobe.system_library_folders
	}
)

#-----------------------------------------------------------Main Code-----------------------------------------------------------#

function main {
	param ([String[]] $argz)
	
	if (-not $debug) {hide_powershell}
	
	Write-Host "`n===============  $scriptTitle  ===============`n"
	$form = make_form $scriptTitle $icon "280, 0"
	$select_all_button = add_control $form "button" $views.select_all_button
	$select_all_button.Add_Click({$actions | ForEach-Object {$_.checkbox.checked = $true}})
	$deselect_all_button = add_control $form "button" $views.deselect_all_button
	$deselect_all_button.Add_Click({$actions | ForEach-Object {$_.checkbox.checked = $false}})
	$actions | ForEach-Object {$_.checkbox = add_control $form "checkbox" $views.title $_.title}
	$ok_button = add_control $form "button" $views.ok_button
	$ok_button.Add_Click({if ($actions | Where-Object {$_.checkbox.checked}) {$form.DialogResult = "Ok"}})
	#$cancel_button = add_control $form "button" $views.cancel_button
	#$cancel_button.DialogResult = "Cancel"
	$form.Add_KeyDown({if ($_.KeyCode -eq "Enter") {$ok_button.PerformClick()}})
	$form_result = $form.ShowDialog()
	
	if ($form_result -eq "Cancel") {exit}
	
	$form = make_form $scriptTitle $icon
	$actions | ForEach-Object {if ($_.checkbox.Checked) {
		$null = add_control $form "label" $views.title $_.title
		$null = add_control $form "label" $views.wait -name $_.title
	}}
	$form.Add_Shown({
		$actions | ForEach-Object {if ($_.checkbox.Checked) {run_action $form $views $_}}
		finish $form $views
	})
	$form.ShowDialog()
}

#-----------------------------------------------------------Functions-----------------------------------------------------------#

function hide_powershell {
	param (
		[bool]$hide = $true
	)
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
		
        [string]$back_color = "#ffffff"
    )
	Add-Type -AssemblyName System.Windows.Forms
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form = New-Object System.Windows.Forms.Form -Property @{
		Text = $title
		ClientSize = $client_size
		BackColor = $back_color
		StartPosition = "CenterScreen"
		FormBorderStyle = 1	# Not resizable
		KeyPreview = $true
	}
	$form.Add_KeyDown({
        if ($_.KeyCode -eq "Escape") {$form.close()}
    })
	if ($icon) {set_form_icon $form $icon}
	set_form_app_id $form $title # Set Form Icon as Taskbar Icon
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
		
        [string]$name
    )
	$global:actual_top += $(if ($global:actual_top -eq 0) {$global:padding.top} else {$view.top})
	$control = New-Object System.Windows.Forms.$type -Property @{
		Top = $global:actual_top
		Left = $view.left
		Name = $name
	}
	$control | ForEach-Object {
		if ($type -in @("label", "checkbox", "button")) {
			$_.Text = $text
			$_.Font = $view.font
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
		if ($view.back -ne $null) {$_.BackColor = $view.back}
		if ($view.height -eq $null -and $view.width -eq $null) {$control.AutoSize = $true}
		else {
			$_.height = $view.height
			if ($view.width -eq "full") {$_.width = $form.width - $view.left * 2 - 18}
			else {$_.width = $view.width}
		}
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
	add_control $form $new_type $new_view -name $control_name
	$form.Controls[$control_name].Top = $top
	$global:actual_top -= $new_view.top
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
	Write-Host "`n $($action.title)"
	replace_control $form $action.title "progressbar" $views.progressbar
	$job = Start-Job -ScriptBlock $action.code -ArgumentList $action.code_arguments #| Receive-Job -AutoRemoveJob -Wait
	do {[System.Windows.Forms.Application]::DoEvents()} until ($job.State -eq "Completed")
	Remove-Job -Job $job
	Write-Host "`n --- $($views.success.text) ---" -ForegroundColor "DarkGreen"
	replace_control $form $action.title "label" $views.success
	$form.Cursor = "Default"
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
	Write-Host "`n --- $($views.exit.text) ---" -ForegroundColor "DarkCyan"
	add_control $form "label" $views.exit
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