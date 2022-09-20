
#--------------- Variables ---------------

$debug = 0

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
    $bluetooth_devices = Get-PnpDevice -Class 'Bluetooth'
	if($debug) { $bluetooth_devices;"" }
    $device_list = @('Evi Headphones', 'ZV Headphones')
    ForEach($device_name in $device_list)
    {
        # DEVPKEY_Device_DevNodeStatus (Data)
        #    25190410 = Connected
        #    58744842 = Disconnected
        #
        # DEVPKEY_Bluetooth_LastConnectedTime (Type)
        #    Empty = Connected
        #    Not Empty = Disconnected

        #$device_connected = ($bluetooth_devices | Where-Object {$_.FriendlyName -eq $device_name}  | Get-PnpDeviceProperty -KeyName "DEVPKEY_Device_DevNodeStatus").Data -eq 25190410
        $device_connected = ($bluetooth_devices | Where-Object {$_.FriendlyName -eq $device_name}  | Get-PnpDeviceProperty -KeyName "DEVPKEY_Bluetooth_LastConnectedTime").Type -eq "Empty"

        if($device_connected)
        {
	        if($debug) { $device_name;"" }
            Start-Process -FilePath "taskkill" -ArgumentList "/fi ""windowtitle eq Headphones"" " -WindowStyle Hidden #Stop-Process -Name "audiorepeater_ks"
            Start-Process -FilePath "$env:comspec" -ArgumentList "/c start /min """" ""audiorepeater_ks.exe"" /Input:""VB-Audio Point"" /Output:""$device_name Stereo"" /OutputPrefill:70 /SamplingRate:44100 /WindowName:""Headphones"" /AutoStart" -WorkingDirectory "$env:cr\Programs\Portables\Audio Repeater MME + KS" -WindowStyle Hidden
        }
        else
        {
            continue
        }
    }
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args
