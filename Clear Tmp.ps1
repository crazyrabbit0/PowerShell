
#--------------- Variables ---------------

$debug = 0
$tmpFolder = "${PSScriptRoot}\tmp\"

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	if($argz.count -eq 0) { $argz = @($tmpFolder) }
	if($debug) { $argz;"" }
	Foreach($arg in $argz) {
		if(Test-Path $arg -PathType Container) {
			Get-ChildItem $arg -Recurse -Force | Where {$_.LastWriteTime -lt (get-date).AddHours(-1)} | Foreach {
				if($debug) { $_ | format-list }
				Remove-Item $_.FullName -Force
			}
		}
	}
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args