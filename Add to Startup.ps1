
############################## Variables ##############################

$debug = 0
$scriptTitle = (Get-Item $PSCommandPath).Basename
$RegistryPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'

############################## Main Code ##############################

function main
{
	param ([string[]] $argz)
	
	showTitle $scriptTitle
	if ($debug) {$argz; ''}
	
	$EntryName = (Get-Item $argz[0]).BaseName
	$EntryValue = "`"$($argz[0])`"" + ($argz | Select -Skip 1 | ForEach-Object{ " `"$_`"" })
	
	If ((Get-Item $RegistryPath -ErrorAction Ignore).Property -contains $EntryName)
	{
		showTitle "Deleting Key: `"$EntryName`""
		Remove-ItemProperty -Path $RegistryPath -Name $EntryName -Force
	}
	else
	{
		showTitle "Creating Key: `"$EntryName`""
		New-ItemProperty -Path $RegistryPath -Name $EntryName -Value $EntryValue -PropertyType String -Force
	}
	
	if ($debug) {''; pause}
	showTitle 'Finish'
	quit
}

############################## Functions ##############################

function showTitle
{
	param (
		[Parameter(Mandatory)] [string] $title
	)
	
	"`n===============  $title  ===============`n"
}

function wait
{
	param (
		[ValidateNotNullOrEmpty()] [int] $seconds = 3,
		
		[ValidateNotNullOrEmpty()] [string] $text = ' Waiting'
	)
	
	Write-Host -NoNewLine $text
	for ($i = 0; $i -le $seconds; $i++)
	{
		Start-Sleep 1
		Write-Host -NoNewLine '.'
	}
}

function quit
{
	param (
		[ValidateNotNullOrEmpty()] [string] $text = ' Exiting',
		
		[string] $runPath,
		
		[string] $runArgument
	)
	
	''
	wait -text $text
	if ($runPath -ne $NULL)
	{
		Start-Process $runPath $runArgument
	}
	''
	exit
}

############################## Run Main Code ##############################

main $args