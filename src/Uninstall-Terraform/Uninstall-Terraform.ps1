
<#PSScriptInfo

.VERSION 0.1.0

.GUID 573ec3ba-ce2f-411f-a18f-4af3202dae58

.AUTHOR Marius Storhaug

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<#

.DESCRIPTION
    Uninstalls Terraform

#>
[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'CurrentUser'
)

if ($Scope -eq 'AllUsers') {
    $terraformPath = "$env:ProgramFiles/terraform"
    Get-Item "$terraformPath/terraform.exe" | Remove-Item -Force
    $env:PATH = $env:PATH.replace(";$terraformPath", '')
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)
} else {
    $terraformPath = "$env:USERPROFILE/.terraform"
    Get-Item "$terraformPath/terraform.exe" | Remove-Item -Force
    $env:PATH = $env:PATH.replace(";$terraformPath", '')
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::User)
}
