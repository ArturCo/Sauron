# -----------------------------------------------------------------------------------------------------
# NAME: Test-DFS.ps1
# AUTHOR: Gaël DENIZOT, ABISSA Informatique SA
# DATE:2016.04.25
# 
# COMMENTS: Powershell script to check access to the DFS Share
# 1) If more that 1 share is accessible using the provided Domain name FQDN and DFS Name, return "1", if none found, return 0
#
# REQUIREMENTS:
# Execution Policy must be set on "remotesigned"
# Command line is : Test-DFS.ps1 DomainFQDN domain-name-in-fqdn DFSName dfs-share-name (ex: abissa.local Files to check \\abissa.local\Files)
# Version History:
# 2016.04.25 - GDE - Initial Script
# -----------------------------------------------------------------------------------------------------


param (
	[Parameter(Mandatory=$True,Position=1)]
    [string]$DomainFQDN,
	[Parameter(Mandatory=$True)]
    [string]$DFSName
 )

$ErrorActionPreference = 'SilentlyContinue'

if (Test-Path -Path \\$DomainFQDN\$DFSName)
{
    $Count = (Get-ChildItem -Path \\$DomainFQDN\$DFSName -Force).Count
    if ($Count -gt 0)
    {
        $Result = "1"
         write-host $Result
         Exit 0
    }
    else
    {
        $Result = "0"
         write-host $Result
         Exit 2

    }
}
else
{
    write-host "0"
    Exit 2

}