
#--------------- Variables ---------------

$debug = 0
$device_list = @("ZV Headphones", "Evi Headphones")
$program_path = "$env:cr\Programs\Portables\Audio Repeater MME + KS\audiorepeater_ks.exe"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	runWithAdminRights $argz
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
            $program_running = [boolean]((Get-CimInstance Win32_Process -Filter "name = ""$program_file""" | Select CommandLine) -Like "*$device_name*")
			if(-not $device_connected -or $program_running) { continue }
			if($debug) { $program_running;"" }
			Start-Process -FilePath "taskkill" -ArgumentList "/im $program_file" -WindowStyle Hidden
			Start-Process -FilePath "$env:comspec" -ArgumentList "/c start /min """" ""$program_file"" /Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" -WorkingDirectory $program_directory -WindowStyle Hidden
		}
        Start-Sleep -Seconds 1
		#if($debug) { "";pause }
	}
}

#--------------- Functions ---------------

function runWithAdminRights {
    param ([String[]] $argz)

	if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process -Verb RunAs powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argz"
		exit
	}
}

#--------------- Run Main Code ---------------

main $args
