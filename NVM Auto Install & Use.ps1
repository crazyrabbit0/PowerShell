######################################  README  ######################################
#
# 1. Execute the command below in PowerShell to enable running scripts on the system:
#
#    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
#
#
# 2. Put this file in the Profile Path below and restart PowerShell:
#
#    "%UserProfile%/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
#

Function My-Cd {
    param (
        $path
    )
    
    # Run default "cd" command
    Set-Location -Path $path
    if (-not $?) { return }
    
    $nvm = @{
        folder      = "$env:AppData/nvm/"
        isInstalled = $null
        url         = 'https://github.com/coreybutler/nvm-windows/releases/latest'
        webdata     = $null
        download    = $null
        tmp         = "$env:TMP/nvm-setup.exe"
    }

    $node = @{
        folder      = "$env:ProgramFiles\nodejs"
        isPresent   = $null
        newest      = $null
        current     = $null
        isCurrent   = $null
    }
    
    $project = @{
        package     = 'package.json'
        nvmrc       = '.nvmrc'
        isFound     = $null
        version     = $null
        isInstalled = $null
        isCurrent   = $null
    }
    
    # Check for NVM Installation
    $nvm.isInstalled    = Test-Path $nvm.folder -PathType Container
    $node.isPresent     = Test-Path $node.folder -PathType Container
    if (-not $nvm.isInstalled) {
        # Check for Node.js Installation & display error
        if ($node.isPresent) {
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            [System.Windows.MessageBox]::Show(
                "Uninstall ""Node.js"" and delete ""$($node.folder)""",
                'Node.js installation found!',
                'Ok',
                'Warning'
            )
            return
        }
        
        # Download & Install NVM for Windows
        $nvm.webdata    = Invoke-RestMethod $nvm.url
        $nvm.download   = (($nvm.webdata | Select-String 'app-argument=(.*?)"').Matches.Groups[1].Value).Replace('tag', 'download') + '/nvm-setup.exe'
        #$ProgressPreference = "SilentlyContinue"   # Hide download progress
        'Downloading latest NVM for Windows...'
        Start-BitsTransfer -Source $nvm.download -Destination $nvm.tmp -DisplayName 'Downloading latest NVM for Windows...'
        'Installing latest NVM for Windows...'
        Start-Process $nvm.tmp '/SP- /VERYSILENT /SUPPERMSGSBOXES /NORESTART' -Wait
        Remove-Item $nvm.tmp
        
        # Update Environment Variables
        $env:NVM_HOME = [System.Environment]::GetEnvironmentVariable("NVM_HOME","Machine")
        $env:NVM_SYMLINK = [System.Environment]::GetEnvironmentVariable("NVM_SYMLINK","Machine")
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
    }
    else {
        # Get Current Node version
        if ($node.isPresent) {
            $node.current = (Get-Item $node.folder).target[0]
        }
    }
    
    # If package.json exist: Set as Project's Node.js version
    if (Test-Path $project.package -PathType Leaf) {
        $packageNodeVersion = Select-String -Path $project.package -Pattern '"node":\s*"(.*?)[.x]*"'
        $project.version = $(if ($packageNodeVersion) { 'v' + $packageNodeVersion.Matches.Groups[1].Value })
    }
    # If package.json isn't found & .nvmrc exist: Set as Project's Node.js version
    if (!$project.version -and (Test-Path $project.nvmrc -PathType Leaf)) {
        $project.version = Get-Content $project.nvmrc -First 1
    }
    
    # If Project's Node.js version is set: Install/Use Project's Node.js version
    if ($project.version) {
        $project.isInstalled = ([array](Get-ChildItem $nvm.folder -Directory).Name -Match "^$($project.version)")[0]
        if (-not $project.isInstalled) {
            "Installing Node.js $($project.version)..."
            Start-Process nvm "install $($project.version)" -WindowStyle Hidden -Wait
        }
        $project.isCurrent = $(if ($node.isPresent) { $node.current.Contains($project.version) })
        if (-not $project.isCurrent) {
            "Using Node.js $($project.version)..."
            Start-Process nvm "use $($project.version)" -Verb RunAs -WindowStyle Hidden -Wait
        }
    }
    # If Project's Node.js version isn't set: Install/Use Latest/Newest Node.js version
    else {
        $node.newest = ([array](Get-ChildItem $nvm.folder -Directory).Name -Match '^v\d+')[-1]
        if (-not $node.newest) {
            'Downloading latest Node.js version...'
            Start-Process nvm "install latest" -WindowStyle Hidden -Wait
            $node.newest = ([array](Get-ChildItem $nvm.folder -Directory).Name -Match '^v\d+')[-1]
        }
        $node.isCurrent = $(if ($node.isPresent) { $node.current.Contains($node.newest) })
        if (-not $node.isCurrent) {
            "Using Node.js $($node.newest)..."
            Start-Process nvm 'use newest' -Verb RunAs -WindowStyle Hidden -Wait
        }
    }
    
    # Update Path Environment Veriable to match Current Node version
    $node.current   = (Get-Item $node.folder).target[0]
    $env:Path       = $env:Path.Replace($env:NVM_SYMLINK, $node.current)
}

# Override "cd" alias
Set-Alias -Name 'cd' -Value 'My-Cd' -Option AllScope
cd .
