
#--------------- Variables ---------------

$debug = 0
#$device_list = @("ZV Headphones", "Evi Headphones")
$program_path = "$env:cr\Programs\Portables\Audio Repeater MME + KS\audiorepeater_ks.exe"
$powershell_path = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"

#--------------- Main Code ---------------

function main
{
	param ([String[]] $argz)
	
	runAsAdminHidden $argz
    oneInstanceMode
	while($true)
	{
		restartEveryHour
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
		if($debug) {$connected_device;""}
		$device_name = (Get-PnpDevice -InstanceId $connected_device.InstanceId).FriendlyName
		$program_running = Get-CimInstance Win32_Process | Where CommandLine -Like """$program_path""*$device_name*"
		if($program_running) {continue}
		if($debug) {$program_running;""}
		Start-Process -FilePath "taskkill" -ArgumentList "/pid $($program_running.ProcessId)" -WindowStyle Hidden
		Start-Sleep -Seconds 1.5 # Delay for device to be ready after connection
		Start-Process -FilePath "$env:comspec" -ArgumentList "/c start /min """" ""$program_path"" /Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" -WindowStyle Hidden
		#if($debug) { "";pause }
	}
}

#--------------- Functions ---------------

function runAsAdminHidden
{
    param ([String[]] $argz)
	
	$process_is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	$process_is_hidden = Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -eq $PID -and $_.CommandLine -Like "*-WindowStyle Hidden*"}
	if($process_is_admin -and $process_is_hidden) {return}
	Start-Process -Verb RunAs -FilePath "$powershell_path" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}

function oneInstanceMode
{
	$other_instances = Get-CimInstance Win32_Process | Where-Object {$_.ProcessId -ne $PID -and $_.CommandLine -Like """$powershell_path""*""$PSCommandPath""*"}
	$other_instances | foreach {Stop-Process -Id $_.ProcessId}
}

function restartEveryHour
{
	$current_time = Get-Date
	$process_start_time = (Get-Process -id $PID).StartTime
	$process_runs_less_than_an_hour = ($current_time - $process_start_time).TotalHours < 1
	If($process_runs_less_than_an_hour) {return}
	Start-Process -Verb RunAs -FilePath "$powershell_path" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}


#--------------- Run Code ---------------

main $args
