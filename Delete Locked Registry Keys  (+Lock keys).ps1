
############################## Runs as Admin ##############################

$has_admin_rights = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
if (-not $has_admin_rights) {Start-Process -Verb 'RunAs' -FilePath 'powershell' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args" -WorkingDirectory $pwd; exit}

############################## Variables ##############################


$ErrorActionPreference = 'SilentlyContinue'		# Override Exceptions
$keysPath = 'SOFTWARE\Classes\WOW6432Node\CLSID\.Test'	# Registry Root Path without Base  (Default: SOFTWARE\Classes\WOW6432Node\CLSID)

############################## Main Code ##############################

function main
{
	param ([string[]] $argz)
	
	#	Find Readable (Unlocked) Registry Keys
	$unlockedKeys = Get-ChildItem "HKCU:\$keysPath" -ErrorVariable Errors | Split-Path -Leaf
	#	Find Uneadable (Locked) Registry Keys
	$lockedKeys = $Errors.CategoryInfo.TargetName | Split-Path -Leaf
	
	#	Unlock Registry Keys
	foreach ($keyName in $lockedKeys)
	{
		#	Print Registry Key
		"HKEY_CURRENT_USER\$keysPath\$keyName"
		#	Override Access to set User as Owner  (without Output)
		Enable-Privilege SeTakeOwnershipPrivilege | Out-Null
		#	Open Registry Key
		$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("$keysPath\$keyName", 'ReadWriteSubTree', 'TakeOwnership')
		
		#	Get blank ACL  (since you don't have ownership)
		$acl = $key.GetAccessControl('None')
		#	Set User as Owner
		$acl.SetOwner([System.Security.Principal.NTAccount] "$env:userdomain\$env:username")
		$key.SetAccessControl($acl)
		
		#	Get actual ACL
		$acl = $key.GetAccessControl()
		#	Remove Permissions for Everyone & User
		$acl.PurgeAccessRules([System.Security.Principal.NTAccount] 'Everyone')
		$acl.PurgeAccessRules([System.Security.Principal.NTAccount] "$env:userdomain\$env:username")
		#	Allow Full Control for User  (Unnecessary)
		#$rule = New-Object System.Security.AccessControl.RegistryAccessRule ("$env:userdomain\$env:username", 'FullControl', 'ObjectInherit, ContainerInherit', 'None', 'Allow')
		#$acl.SetAccessRule($rule)
		#	Enable Inheritance
		$acl.SetAccessRuleProtection($FALSE, $TRUE)
		#	Apply ACL changes
		$key.SetAccessControl($acl)
		
		#	Close Registry Key
		$key.Close()
	}
	
	#	Delete Registry Keys that are Empty  (without Subkeys and Values)
	Get-ChildItem "HKCU:\$keysPath" | Where-Object {$_.SubKeyCount -eq 0 -and $_.ValueCount -eq 0} | Remove-Item
	
	#	Wait for Enter
	Pause
	
	#	Lock Registry Keys
	foreach ($keyName in $unlockedKeys)
	{
		#	Print Registry Key
		"HKEY_CURRENT_USER\$keysPath\$keyName"
		#	Override Access to set System as Owner  (without Output)
		Enable-Privilege SeRestorePrivilege | Out-Null
		#	Open Registry Key
		$key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("$keysPath\$keyName", 'ReadWriteSubTree', 'TakeOwnership')
		
		#	Get ACL
		$acl = $key.GetAccessControl()
		#	Disable Inheritance
		$acl.SetAccessRuleProtection($TRUE, $FALSE)
		#	Set System as Owner
		$acl.SetOwner([System.Security.Principal.NTAccount] 'System')
		#	Apply ACL changes
		$key.SetAccessControl($acl)
		
		#	Close Registry Key
		$key.Close()
	}
	
	#	Wait for Enter
	Pause
}

############################## Functions ##############################

#	Function to Enable Privileges  (Source: https://social.technet.microsoft.com/Forums/en-US/e718a560-2908-4b91-ad42-d392e7f8f1ad/take-ownership-of-a-registry-key-and-change-permissions)
function Enable-Privilege
{
	param(
		## The privilege to adjust. This set is taken from
		## http://msdn.microsoft.com/en-us/library/bb530716(VS.85).aspx
		[ValidateSet(
			"SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
			"SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
			"SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
			"SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege", "SeIncreaseBasePriorityPrivilege",
			"SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege", "SeLoadDriverPrivilege",
			"SeLockMemoryPrivilege", "SeMachineAccountPrivilege", "SeManageVolumePrivilege",
			"SeProfileSingleProcessPrivilege", "SeRelabelPrivilege", "SeRemoteShutdownPrivilege",
			"SeRestorePrivilege", "SeSecurityPrivilege", "SeShutdownPrivilege", "SeSyncAgentPrivilege",
			"SeSystemEnvironmentPrivilege", "SeSystemProfilePrivilege", "SeSystemtimePrivilege",
			"SeTakeOwnershipPrivilege", "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
			"SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
		$Privilege,
		## The process on which to adjust the privilege. Defaults to the current process.
		$ProcessId = $pid,
		## Switch to disable the privilege, rather than enable it.
		[Switch] $Disable
	)
	
	## Taken from P/Invoke.NET with minor adjustments.
	$definition = @'
	using System;
	using System.Runtime.InteropServices;

	public class AdjPriv
	{
		[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
		internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
			ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

		[DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
		internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
		[DllImport("advapi32.dll", SetLastError = true)]
		internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
		[StructLayout(LayoutKind.Sequential, Pack = 1)]
		internal struct TokPriv1Luid
		{
			public int Count;
			public long Luid;
			public int Attr;
		}

		internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
		internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
		internal const int TOKEN_QUERY = 0x00000008;
		internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
		public static bool EnablePrivilege(long processHandle, string privilege, bool disable)
		{
			bool retVal;
			TokPriv1Luid tp;
			IntPtr hproc = new IntPtr(processHandle);
			IntPtr htok = IntPtr.Zero;
			retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
			tp.Count = 1;
			tp.Luid = 0;
			if (disable)
			{
				tp.Attr = SE_PRIVILEGE_DISABLED;
			}
			else
			{
				tp.Attr = SE_PRIVILEGE_ENABLED;
			}
			retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
			retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
			return retVal;
		}
	}
'@
	
	$processHandle = (Get-Process -id $ProcessId).Handle
	$type = Add-Type $definition -PassThru
	$type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

############################## Run Main Code ##############################

main $args