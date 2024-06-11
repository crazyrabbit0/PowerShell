
############################## GLOBALS ##############################

$global:debug	= 0
$global:display = 'Normal'
$global:title = 'Image to Base64 on Clipboard'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	
	if ($global:debug) { $global:args; '' }
    
    if ($global:args.Length -eq 0) {
        $global:args += "$env:tmp\temp.png"
        (Get-Clipboard -Format Image).Save($global:args[0])
    }

	Foreach ($arg in $global:args) {
		if (Test-Path $arg -PathType Leaf) {
			$base64 = 'data:image;base64,' + [convert]::ToBase64String((get-content $arg -encoding byte))
            $base64 | Set-Clipboard
			if ($global:debug) {
                $arg
                $base64
            }
		}
	}
	
	if ($global:debug) { ''; pause }
	exit
}

############################## RUN MAIN CODE ##############################

main