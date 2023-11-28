
############################## GLOBALS ##############################

$global:debug = 0
$global:display = 'Normal'
$global:title = 'Add to Startup'
$global:args = $args

############################## VARIABLES ##############################

$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

############################## MAIN CODE ##############################

function main {
	if ($global:debug) { $global:args; '' }

	showTitle $global:title
	
	$EntryName = (Get-Item $global:args[0]).BaseName
	$EntryValue = "`"$($global:args[0])`"" + ($global:args | Select-Object -Skip 1 | ForEach-Object { " `"$_`"" })
	
	If ((Get-Item $RegistryPath -ErrorAction Ignore).Property -contains $EntryName) {
		showTitle "Deleting Key: `"$EntryName`""
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName -Force
	}
	else {
		showTitle "Creating Key: `"$EntryName`""
		New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType String -Force
	}
	
	if ($global:debug) { ''; pause }
	showTitle 'Finish'
	quit
}

############################## FUNCTIONS ##############################

function showTitle {
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n===============  $title  ===============`n"
}

function wait {
	param (
		[ValidateNotNullOrEmpty()] [int] $seconds = 3,
		
		[ValidateNotNullOrEmpty()] [string] $text = ' Waiting'
	)
	
	Write-Host -NoNewLine $text
	for ($i = 0; $i -le $seconds; $i++) {
		Start-Sleep 1
		Write-Host -NoNewLine '.'
	}
}

function quit {
	param (
		[ValidateNotNullOrEmpty()] [string] $text = ' Exiting',
		
		[string] $runPath,
		
		[string] $runArgument
	)
	
	''
	wait -text $text
	if ($runPath -ne $NULL) {
		Start-Process $runPath $runArgument
	}
	''
	exit
}

############################## RUN MAIN CODE ##############################

main