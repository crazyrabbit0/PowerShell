
#--------------- Variables ---------------

$debug = 0

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
    
    if($debug) { $argz }

    $Env:__COMPAT_LAYER = "RunAsInvoker"
    Start-Process ("""$($argz[0])""" + ($argz | Select -Skip 1 | ForEach-Object{ " ""$_""" }))
	
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args