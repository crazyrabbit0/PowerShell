
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = '7z SFX Merge'
$global:args = $args

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }
	
	if (Test-Path $global:args[0] -PathType Leaf) {
		$filePathWithoutExt = $global:args[0] -Replace '(.+)[.].{2,4}?$', '$1'
		if ($global:debug) { $filePathWithoutExt }
		cmd /c copy /b "$filePathWithoutExt.sfx" + "$filePathWithoutExt.txt" + "$filePathWithoutExt.7z" "$filePathWithoutExt.exe" > $NULL
	}
	if ($global:debug) { ''; pause }
}

############################## RUN MAIN CODE ##############################

main