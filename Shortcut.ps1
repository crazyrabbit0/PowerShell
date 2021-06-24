
#--------------- Variables ---------------

$debug = 0
$destinationFolder = [Environment]::GetFolderPath("Desktop")

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	if($argz.count -eq 0) { $argz = @($PSCommandPath) }
	if($debug) { $argz;"" }
	Foreach($arg in $argz) {
		if(Test-Path $arg -PathType Leaf) {
			$destinationFile = $destinationFolder + "\" + (Get-Item $arg).Basename + ".lnk"
			if($debug) { $destinationFile }
			ps1Shortcut "$arg" "$destinationFile"
		}
	}
	if($debug) { "";pause }
}

#--------------- Functions ---------------

function ps1Shortcut {
	param (
        [Parameter(Mandatory)]
        [string]$Source,
		
		[Parameter(Mandatory)]
        [string]$Destination
    )
	$Shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($Destination)
	$Shortcut.TargetPath = "powershell.exe"
	$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"${Source}`""
	$Shortcut.Save()
}

#--------------- Run Main Code ---------------

main $args