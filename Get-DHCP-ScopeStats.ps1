# -----------------------------------------------------------------------------------------------------
# NAME: Get-DHCP-ScopeStats.ps1
# AUTHOR: Gaël DENIZOT, ABISSA Informatique SA
# DATE:2016.04.29
# 
# COMMENTS: Query DHCP Informations (because SNMP Monitoring is not supported by Windows 2012 anymore)
#
# REQUIREMENTS:
# Execution Policy must be set on "remotesigned"
#
# USAGE:
#   as a script:    C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -command  "& %programfiles%\Zabbix\Scripts\Get-DHCP-ScopeStats.ps1 <ITEM_TO_QUERY> <ScopeID>"
#   as an item:     vbr[<ITEM_TO_QUERY>,<ScopeID>]
#  EX:
#  Get-DHCP-ScopeStats.ps1 Discovery 
#    #(will return a JSON object with all the scopes. Will be used by Zabbix Dynamic Discovery"
#  Get-DHCP-ScopeStats.ps1 FreeIPV4Addresses "scope_ID" 
#    #(will return Free IPV4 Addresses for the specified Scope ID.
#  Get-DHCP-ScopeStats.ps1 UsedIPV4Addresses "scope_ID" 
#    #(will return Used IPV4 Addresses for the specified Scope ID.
#  Get-DHCP-ScopeStats.ps1 ScopeState "scope_ID" 
#    #(will return Scope Status of the Scope ID (either Active or Inactive)
#
# Add to Zabbix Agent
#   UserParameter=DHCPMON[*],%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -nologo -file "%programfiles%\Zabbix\Scripts\Get-DHCP-ScopeStats.ps1" $1 $2
#
#
# Version History:
# 2016.04.29 - GDE - Initial Script
# -----------------------------------------------------------------------------------------------------


$version = "1.0.0"

$ITEM = [string]$args[0]
$ID = [string]$args[1]

Import-Module DhcpServer



# Query DHCP for scopes
switch ($ITEM) {
  "Discovery" {
    # Open JSON object
    $output =  "{`"data`":["
      $query = Get-DhcpServerv4Scope | Select-Object ScopeId,Name
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
        $Id = [string]$object.ScopeId
        $Name = [string]$object.Name
        if ($count -eq 1) {
          $output = $output + "{`"{#SCOPEID}`":`"$Id`",`"{#SCOPENAME}`":`"$Name`"}"
        } else {
          $output = $output + "{`"{#SCOPEID}`":`"$Id`",`"{#SCOPENAME}`":`"$Name`"},"
        }
        $count--
    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
  }
  "FreeIPV4Addresses"{
  $query =  Get-DhcpServerv4ScopeStatistics | Where-Object {$_.ScopeId -like "*$ID*"}
  [string]$query.Free
  }
  "UsedIPV4Addresses"{
  $query = Get-DhcpServerv4ScopeStatistics | Where-Object {$_.ScopeId -like "*$ID*"}
  [string]$query.InUse
  }
  "ScopeState"{
  $query = Get-DhcpServerv4Scope | Where-Object {$_.ScopeId -like "*$ID*"}
  [string]$query.State
  }
   default {
      Write-Host "-- ERROR -- : Need an option to work !"
  }
}
