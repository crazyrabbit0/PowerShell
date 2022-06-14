
#--------------- Variables ---------------

$debug = 0
$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename
$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
    
	showTitle $scriptTitle
    if($debug) { $argz }

    $EntryName = Split-Path (Split-Path $argz[0]) -Leaf
    $EntrypPath = $argz[0] + ($argz | Select -Skip 1 | ForEach-Object{ " $_" })
    
	showTitle "Creating the Startup Folder"
	If (-NOT (Test-Path $RegistryPath)) {
	  New-Item -Path $RegistryPath -Force | Out-Null
	}
    
	showTitle "Setting the Startup Key"
	New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntrypPath -PropertyType String -Force
	
	if($debug) { "";pause }
	showTitle "Finish"
	quit
}

#--------------- Functions ---------------

function showTitle {
	param (
        [Parameter(Mandatory)]
        [string]$title
    )
	""
	"===============  $title  ==============="
	""
}

function wait {
	param (
        [ValidateNotNullOrEmpty()]
        [int]$seconds = 3,
		
        [ValidateNotNullOrEmpty()]
        [string]$text = "${textPrefix}Waiting"
    )
	Write-Host -NoNewLine "$text"
	for($i=0; $i -le $seconds; $i++) {
		Start-Sleep 1
		Write-Host -NoNewLine "."
	}
}

function quit {
	param (
        [ValidateNotNullOrEmpty()]
        [string]$text = "${textPrefix}Exiting",
		
        [string]$runPath,
		
        [string]$runArgument
    )
	""
	wait -text $text
	if($runPath -ne $null) {
		Start-Process $runPath $runArgument
	}
	""
	exit
}

#--------------- Run Main Code ---------------

main $args