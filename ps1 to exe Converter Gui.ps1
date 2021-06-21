
#--------------- Variables ---------------

$debug = 0

#--------------- Main Code ---------------

function main {
	if($debug) { $args;"" }
	win-ps2exe
	if($debug) { "";pause }
}

#--------------- Run Main Code ---------------

main $args