
############################## Variables ##############################

$debug = 0

############################## Main Code ##############################

function main
{
	param ([string[]] $argz)
	if ($debug) {$argz; ''}
	
	if (Test-Path $argz[0] -PathType Leaf)
	{
		$filePathWithoutExt = $argz[0] -Replace '(.+)[.].{2,4}?$', '$1'
		if ($debug) {$filePathWithoutExt}
		cmd /c copy /b "$filePathWithoutExt.sfx" + "$filePathWithoutExt.txt" + "$filePathWithoutExt.7z" "$filePathWithoutExt.exe" > $NULL
	}
	if ($debug) {''; pause}
}

############################## Run Main Code ##############################

main $args