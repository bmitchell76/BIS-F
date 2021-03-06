
<#
    .SYNOPSIS
        Personalize Altiris Agent for Image Managemement Software
	.Description
      	if image is in shared mode the service will be started
    .EXAMPLE
    .Inputs
    .Outputs
    .NOTES
		Author: Matthias Schlimm
      	Company: Login Consultants Germany GmbH
		
		History
      	Last Change: 14.10.2014 MS: function created
		Last Change: 29.09.2015 MS: rewritten script with standard .SYNOPSIS, use central BISF function to configure service
		Last Change:
	.Link
#>

Begin {
	$script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
	$script_name = [System.IO.Path]::GetFileName($script_path)
	$servicename = "Altiris Deployment Agent"
}

Process {
	$svc = Test-BISFService -ServiceName "$servicename" -ProductName "$servicename"
	IF ($svc)
	{
		Invoke-BISFService -ServiceName "$servicename" -Action Start -CheckDiskMode RW
	}
}

End {
	Add-BISFFinishLine
}