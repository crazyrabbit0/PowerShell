
#--------------- Variables ---------------

$debug = 0
$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
$EntryName = Split-Path (Get-Location) -Leaf
$EntrypPath = '"' + (Get-Location) + "\$EntryName.exe" + '"'

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)

	# Create the Key Folder if it does not exist
	If (-NOT (Test-Path $RegistryPath)) {
	  New-Item -Path $RegistryPath -Force | Out-Null
	}

	# Create or Replace the Key
	New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntrypPath -PropertyType String -Force
	
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args