<#
    For best results set this as a Logoff Script:

    1. Open the Local Group Policy Editor:
       - Press Win + R, type 'gpedit.msc', and press Enter.

    2. Navigate to the Script Location:
       - Go to: User Configuration > Windows Settings > Scripts (Logon/Logoff).

    3. Open Logoff Properties:
       - In the right pane, double-click on "Logoff".

    4. Configure the PowerShell Script:
       - In the "Logoff Properties" window, click on the "PowerShell Scripts" tab.
       - Click the "Add..." button.
       - Browse to the location of this script file and select it.
       - Click "OK" to save and apply the policy.
#>

$RegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$FlagsToAdd = ' --disable-features=ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled'

Get-ItemProperty -Path $RegistryPath | ForEach-Object {
    $_.PSObject.Properties | Where-Object { $_.Name -like 'GoogleChromeAutoLaunch*' } | ForEach-Object {
        
        $CurrentValue = $_.Value
        
        # Check if the flags are already present to avoid adding them multiple times
        if ($CurrentValue -notlike "*ExtensionManifestV2Disabled*") {
            $NewValue = $CurrentValue + $FlagsToAdd
            
            Set-ItemProperty -Path $RegistryPath -Name $_.Name -Value $NewValue
            Write-Host "Updated $($_.Name): Added Manifest V2 flags."
        }
        else {
            Write-Host "Skipped $($_.Name): Flags already present."
        }
    }
}