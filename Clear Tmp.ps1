
#--------------- Variables ---------------

$debug = 0
$tmpFolder = ".\tmp\"

#--------------- Main Code ---------------

function main {
	if([string]::IsNullOrWhiteSpace($args[0])) { $args[0] = $tmpFolder }
	if($debug) { $args;"" }
	Foreach($arg in $args) {
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