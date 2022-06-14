
#--------------- Variables ---------------

$textPrefix = " "
$scriptTitle = (Get-Item $PSCommandPath).Basename

#--------------- Main Code ---------------

function main {
	param ([String[]] $argz)
	
	showTitle $scriptTitle
	Get-Process "Acro*" | Stop-Process -Force -PassThru
	Get-Process "Adobe*" | Stop-Process -Force -PassThru
	""
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