
<# Personalization of the  BaseImage for Image Management Software like PVS, MCS,VMware View, Mirosofft only environemnts, sysprep images

 
 Author: Matthias Schlimm
 Login Consultants Germany GmbH
 Date: 24.09.2012

  History
  Last Change: 24.09.2012 MS: Script created
  Last Change: 26.08.2013 MS: Removed $XA_GenPVS_Folder = $SubCall_Folder + "30_XA_GenPVS\"
  Last Change: 16.09.2013 MS: Added customfolder 99_XX_Custom\30_XX_PersPVS
  Last Change: 16.09.2013 MS: Load_PS_Folder -def_load_PS_Folder $LIB_Folder
  Last Change: 17.09.2013 MS: Removed unused variable and get Foldernames fom LIB_Config
  Last Change: 18.09.2013 MS: Replaced $date with $(Get-date) to get current timestamp at running scriptlines write to the logfile
  Last Change: 18.09.2013 MS: Predefined $LIB & $Subcall folder
  Last Change: 19.09.2013 MS: IF ($scripts -ne $null)
  Last Change: 28.01.2014 MS: Changed Line 87 to $return = load_PS_Folder -def_load_PS_Folder $psfolder to get GlobalValues from LIB
  Last Change: 10.03.2014 MS: Reviewed code
  Last Change: 21.03.2014 MS: Last code change, before release to web
  Last Change: 11.08.2014 MS: Defined single logf ile for Personalization like Pers_PVS_Target_Scripts_YYYYMMDD-HHMMSS.log
  Last Change: 12.08.2014 MS: Changed from Logfilename from .log to .bis (BIS = BaseImageScripts)
  Last Change: 14.08.2014 MS: Changed ForegroundColor Green Write-Host "Import Modules $Modules" -ForegroundColor Green
  Last Change: 18.08.2014 MS: Added computername to logfilename $Global:LogFileName = "Pers_BIS_$($computer)_$timestamp.bis"
  Last Change: 16.02.2015 MS: Changed to new structur to import modules
  Last Change: 21.08.2015 MS: Changed Request 77 - remove all XX,XA,XD from al files and Scripts
  Last Change: 04.10.2016 MS: Renamed Folder names for global architectural re-design
  Last Change: 09.01.2017 MS: IF $DiskMode -eq "MCSPrivate" no personalization is running
  Last Change: 16.08.2017 MS: Skip Device Personalization, based on Diskmode selected in ADMX
  Last Change: 11.09.2017 MS: Writing PersSate "PersRunning" and "PersFinished" to BISF Registry to control running prep after pers first
  Last Change: 12.09.2017 MS: Using array $PersState = $TaskStates[0-4] to set the right State in the registry instead of hardcoded value
  Last Change: 03.10.2017 MS: Bugfix 215: writing wrong PersState to registry, preparation does not run in that case
#>#-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x-x 

Begin {
    $error.Clear()
    If ( $TerminateScript -is [system.object] ) {Remove-Variable TerminateScript}
    Clear-Host
    $computer = gc env:computername
    $timestamp = Get-Date -Format yyyyMMdd-HHmmss
    
    # Setting default variables ($PSScriptroot/$logfile/$PSCommand,$PSScriptFullname/$scriptlibrary/LogFileName) independent on running script from console or ISE and the powershell version. 
    If ($($host.name) -like "* ISE *") { # Running script from Windows Powershell ISE
        $PSScriptFullName = $psise.CurrentFile.FullPath.ToLower()
        $PSCommand = (Get-PSCallStack).InvocationInfo.MyCommand.Definition
    } ELSE {
        $PSScriptFullName = $MyInvocation.MyCommand.Definition.ToLower()
        $PSCommand = $MyInvocation.Line
    }
    [string]$PSScriptName = (Split-Path $PSScriptFullName -leaf).ToLower()
    If (($PSScriptRoot -eq "") -or ($PSScriptRoot -eq $null)) { [string]$PSScriptRoot = (Split-Path $PSScriptFullName).ToLower()}
        
    # define environment
	$Global:State = "Personalization"
    $Global:LogFileName = 
    $Global:Main_Folder = $PSScriptRoot
    $Global:SubCall_Folder = $PSScriptRoot + "\SubCall\"
    $Global:LIB_Folder = $SubCall_Folder + "Global\"
    $Global:LogFileName = "Pers_BIS_$($computer)_$timestamp.bis"
    $Global:LOGFile="C:\Windows\Logs\$LogFileName"
    $Global:LOG=$LOGFile

}

Process {
    #load BISF Modules
    try {
        $Modules = @(Get-ChildItem -path $LIB_Folder -filter "*.psd1" -Force)
        ForEach ($module in $Modules) {
            $modulename = (Test-ModuleManifest $($Module.FullName) -Verbose:$false).Name
            $global:mainmodulename = $modulename
            $modulecompany = (Test-ModuleManifest $($Module.FullName) -Verbose:$false).CompanyName
            Write-Host "--- Importing Module $modulename ---" -ForegroundColor Green -BackgroundColor DarkGray
            Import-Module -Name $($Module.FullName) -Force
        }
    }
    catch {
        Throw "An error occured while loading modules. The error is: $_"
        Exit 1
    }
    
    # Initialize all variables used by BISF
    Initialize-BISFConfiguration

	$PersState = $TaskStates[2]
	Write-BISFLog -Msg "Write PersState to registry location Path: $hklm_software_LIC_CTX_BISF_SCRIPTS -Name: LIC_BISF_PersState -Value: $PersState"
	Set-ItemProperty -Path $hklm_software_LIC_CTX_BISF_SCRIPTS -Name "LIC_BISF_PersState" -value "$PersState" -Force #-ErrorAction SilentlyContinue

    
    #Migrate Settings from PVS to BISF
    Convert-BISFSettings

#Load Global environment
$psfolder = $LIB_Folder
Invoke-BISFFolderScripts -Path "$psfolder" -Verbose:$VerbosePreference
$PersState = $TaskStates[3]
Switch ($LIC_BISF_CLI_DM) #Skip Device Personalization, based on ADMX configuration
	{
		All {
			Start-BISFCDS
			Write-BISFLog -Msg "Write PersState to registry location Path: $hklm_software_LIC_CTX_BISF_SCRIPTS -Name: LIC_BISF_PersState -Value: $PersState"
			Set-ItemProperty -Path $hklm_software_LIC_CTX_BISF_SCRIPTS -Name "LIC_BISF_PersState" -value "$PersState" -Force #-ErrorAction SilentlyContinue
			Write-BISFLog -Msg "Image in Mode $DiskMode, skip device personalization (configured: all)" -Type E -SubMsg;Exit
		}
		Never {Write-BISFLog -Msg "Image in Mode $DiskMode, device personalization would not being skipped (configured: never)" -ShowConsole -Color DarkCyan}
		ReadWrite {
			IF (($DiskMode -match "Private") -or ($DiskMode -match "ReadWrite"))
			{
				Start-BISFCDS
				Write-BISFLog -Msg "Write PersState to registry location Path: $hklm_software_LIC_CTX_BISF_SCRIPTS -Name: LIC_BISF_PersState -Value: $PersState"
				Set-ItemProperty -Path $hklm_software_LIC_CTX_BISF_SCRIPTS -Name "LIC_BISF_PersState" -value "$PersState" -Force #-ErrorAction SilentlyContinue
				Write-BISFLog -Msg "Image in Mode $DiskMode, skip device personalization (configured: Private Mode) " -Type E -SubMsg;Exit
			} ELSE 
			{Write-BISFLog -Msg "Image in Mode $DiskMode, device personalization would not being skipped (configured: Private Mode)" -ShowConsole -Color DarkCyan}
		}
		Default {Write-BISFLog -Msg "Default Action selected, device personalization would not being skipped (not configured in ADMX)" -ShowConsole -Color DarkCyan}
	}
Add-BISFFinishLine

#load predefined scripts from LOGIN Consultants
$psfolder = $SubCall_Folder + "Personalization"
 Invoke-BISFFolderScripts -Path "$psfolder" -Verbose:$VerbosePreference

Add-BISFFinishLine

#load custom scripts
$psfolder = $SubCall_Folder + "Personalization\Custom"
 Invoke-BISFFolderScripts -Path "$psfolder" -Verbose:$VerbosePreference

Start-BISFCDS # Start the Citrix Desktop Service, if configured through ADMX

$PersState = $TaskStates[3]
Write-BISFLog -Msg "Write PersState to registry location Path: $hklm_software_LIC_CTX_BISF_SCRIPTS -Name: LIC_BISF_PersState -Value: $PersState"
Set-ItemProperty -Path $hklm_software_LIC_CTX_BISF_SCRIPTS -Name "LIC_BISF_PersState" -value "$PersState" -Force #-ErrorAction SilentlyContinue

}

 End {
    try {
        Write-BISFLog -Msg "- - - End Of Script - - - "
		#unload BISF Modules
        $Modules = @(Get-ChildItem -path $LIB_Folder -filter "*.psd1" -Force)
        ForEach ($module in $Modules) {
            $modulename = (Test-ModuleManifest $($Module.FullName)).Name
            $modulecompany = (Test-ModuleManifest $($Module.FullName)).CompanyName
            Write-Host "--- Removing Module $modulename ---" -ForegroundColor Green -BackgroundColor DarkGray
            Remove-Module -Name $modulename -Force -ErrorAction Stop
        }
    }
    catch {
        Throw "An error occured while unloading modules. The error is:`r`n$_"
        Exit 1
    }
}