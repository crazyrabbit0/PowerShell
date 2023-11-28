
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Headphone Service'
$global:args = $args

############################## VARIABLES ##############################

$program_path = "$env:cr\Programs\Portables\Audio Repeater MME + KS\audiorepeater_ks.exe"

############################## MAIN CODE ##############################

function main {
	#run_as_admin
	#oneInstanceMode

	while ($true) {
		#restartEveryHour
		#if ($global:debug -gt 0) { pause; '' }
		$bluetooth_devices = Get-PnpDevice | Where-Object Description -eq 'Bluetooth Device'
		
		# DEVPKEY_Device_DevNodeStatus (Data)
		#    25190410 = Connected
		#    58744842 = Disconnected
		#
		# DEVPKEY_Bluetooth_LastConnectedTime (Type)
		#    Empty = Connected
		#    FileTime = Disconnected
		#
		$connected_device = $bluetooth_devices | Get-PnpDeviceProperty | Where-Object { $_.KeyName -eq 'DEVPKEY_Device_DevNodeStatus' -and $_.Data -eq '25190410' }
		if (-not $connected_device) { continue }
		
		Start-Sleep -Seconds 1.5	# Delay for device to be ready after connection
		$device_name = (Get-PnpDevice -InstanceId $connected_device.InstanceId).FriendlyName
		if ($global:debug -gt 0) { "Connected Headphones: $device_name"; '' }

		$program_running = Get-CimInstance Win32_Process | Where-Object CommandLine -Like "*$program_path*$device_name*"
		if ($program_running) { continue }

		if ($global:debug -gt 0) { 'Audio Repeater is not Running!  Restarting...'; '' }
		Stop-Process -Name (Get-Item $program_path).Basename	#Start-Process 'taskkill' "/im (Get-Item $program_path).Name" -Verb 'RunAs' -WindowStyle 'Hidden'
		Start-Process "$program_path" "/Input:`"VB-Audio Point`" /Output:`"$device_name Stereo`" /OutputPrefill:70 /SamplingRate:44100 /AutoStart"	#Start-Process "$env:comspec" "/c start /min `"`" `"$program_path`" /Input:`"VB-Audio Point`" /Output:`"$device_name Stereo`" /OutputPrefill:70 /SamplingRate:44100 /AutoStart" -WindowStyle 'Hidden'
	}
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

function oneInstanceMode {
	$other_instances = Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -Like "*powershell.exe*""$PSCommandPath""*" }
	$other_instances | Foreach-Object { Stop-Process -Id $_.ProcessId }
}

function restartEveryHour {
	$current_time = Get-Date
	$process_start_time = (Get-Process -id $PID).StartTime
	$process_runs_less_than_an_hour = ($current_time - $process_start_time).TotalHours -lt 1
	If ($process_runs_less_than_an_hour) { return }
	Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File ""$PSCommandPath"" $global:args"
	exit
}

############################## RUN MAIN CODE ##############################

main
