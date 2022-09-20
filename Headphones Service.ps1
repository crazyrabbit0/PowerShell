
#--------------- Variables ---------------

$debug = 0
$device_list = @("ZV Headphones", "Evi Headphones")
$program_path = "$env:cr\Programs\Portables\Audio Repeater MME + KS\audiorepeater_ks.exe"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runHiddenWithAdminRights $argz
    oneInstanceMode
    $program_file = Split-Path $program_path -Leaf
    $program_directory = Split-Path $program_path -Resolve
	while($true)
	{
        $bluetooth_devices = Get-PnpDevice -Class "Bluetooth"
		foreach($device_name in $device_list)
		{
			if($debug) { $device_name;"" }
			#
            # DEVPKEY_Device_DevNodeStatus (Data)
			#    25190410 = Connected
			#    58744842 = Disconnected
			#
			# DEVPKEY_Bluetooth_LastConnectedTime (Type)
			#    Empty = Connected
			#    Not Empty = Disconnected
            #
			#$device_connected = ($bluetooth_devices | Where-Object {$_.FriendlyName -eq $device_name}  | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_DevNodeStatus").Data -eq 25190410
			$device_connected = ($bluetooth_devices | Where-Object {$_.FriendlyName -eq $device_name}  | Get-PnpDeviceProperty -KeyName "DEVPKEY_Bluetooth_LastConnectedTime").Type -eq "Empty"
            $program_running = Get-CimInstance Win32_Process -Filter "name = ""$program_file""" | Where CommandLine -Like "*$device_name*"
			if(-not $device_connected -or $program_running) { continue }
			if($debug) { $program_running;"" }
			Start-Process -FilePath "taskkill" -ArgumentList "/pid $($program_running.ProcessId)" -WindowStyle Hidden
			Start-Sleep -Seconds 1.5 # Delay for device to be ready after connection
			Start-Process -FilePath "$env:comspec" -ArgumentList "/c start /min """" ""$program_file"" /Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" -WorkingDirectory $program_directory -WindowStyle Hidden
		}
        Start-Sleep -Seconds 1
		#if($debug) { "";pause }
	}
}

#--------------- Functions ---------------

function runHiddenWithAdminRights
{
    param ([String[]] $argz)
	
	$process_is_admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
	$process_is_hidden = Get-CimInstance Win32_Process -Filter "name = ""powershell.exe""" | Where ProcessId -eq $PID | Where CommandLine -Like "*-WindowStyle Hidden*"
	if($process_is_admin -and $process_is_hidden) { return }
	Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File ""$PSCommandPath"" $argz"
	exit
}

function oneInstanceMode
{
	$all_instances = Get-CimInstance Win32_Process -Filter "name = ""powershell.exe""" | Where CommandLine -Like "*$PSCommandPath*"
	$all_instances | Where ProcessId -ne $PID | foreach { Stop-Process -Id $_.ProcessId }
}

#--------------- Run Code ---------------

main $args
