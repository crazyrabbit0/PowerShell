
#--------------- Variables ---------------

$debug = 0
$program_path = "$env:cr\Programs\Portables\Audio Repeater MME + KS\audiorepeater_ks.exe"

#--------------- Main Code ---------------

function main
{
	param ([String[]] $argz)
	
	#runAsAdmin $argz
	#runAsAdminHidden $argz
	#oneInstanceMode
	while($true)
	{
		#restartEveryHour
		#if($debug) {pause;""}
		$bluetooth_devices = Get-PnpDevice | Where Description -eq "Bluetooth Device"
		#
		# DEVPKEY_Device_DevNodeStatus (Data)
		#    25190410 = Connected
		#    58744842 = Disconnected
		#
		# DEVPKEY_Bluetooth_LastConnectedTime (Type)
		#    Empty = Connected
		#    FileTime = Disconnected
		#
		$connected_device = $bluetooth_devices | Get-PnpDeviceProperty | Where-Object {$_.KeyName -eq "DEVPKEY_Device_DevNodeStatus" -and $_.Data -eq "25190410"}
		if(-not $connected_device) {continue}
		Start-Sleep -Seconds 1.5 # Delay for device to be ready after connection
		$device_name = (Get-PnpDevice -InstanceId $connected_device.InstanceId).FriendlyName
		if($debug) {"Connected Headphones: $device_name";""}
		$program_running = Get-CimInstance Win32_Process | Where CommandLine -Like "*$program_path*$device_name*"
		if($program_running) {continue}
		if($debug) {"Audio Repeater is not Running!  Restarting...";""}
		Stop-Process -Name (Get-Item $program_path).Basename #Start-Process -Verb RunAs -FilePath "taskkill" -ArgumentList "/im (Get-Item $program_path).Name" -WindowStyle Hidden
		Start-Process -FilePath "$program_path" -ArgumentList "/Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" #Start-Process -FilePath "$env:comspec" -ArgumentList "/c start /min """" ""$program_path"" /Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" -WindowStyle Hidden
		
	}
}

#--------------- Functions ---------------

function runAsAdmin
{
	param ([String[]] $argz)
	
	$process_is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	if($process_is_admin) {return}
	Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}

function runAsAdminHidden
{
	param ([String[]] $argz)
	
	$process_is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	$process_is_hidden = Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -eq $PID -and $_.CommandLine -Like "*-WindowStyle Hidden*"}
	if($process_is_admin -and $process_is_hidden) {return}
	Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}

function oneInstanceMode
{
	$other_instances = Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -ne $PID -and $_.CommandLine -Like "*powershell.exe*""$PSCommandPath""*"}
	$other_instances | foreach {Stop-Process -Id $_.ProcessId}
}

function restartEveryHour
{
	$current_time = Get-Date
	$process_start_time = (Get-Process -id $PID).StartTime
	$process_runs_less_than_an_hour = ($current_time - $process_start_time).TotalHours -lt 1
	If($process_runs_less_than_an_hour) {return}
	Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}

#--------------- Run Code ---------------

main $args
