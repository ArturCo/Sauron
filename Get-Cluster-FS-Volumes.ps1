# -----------------------------------------------------------------------------------------------------
# NAME: Get-Cluster-FS-Volumes.ps1
# AUTHOR: Gaël DENIZOT, ABISSA Informatique SA
# DATE:2016.05.25
# 
# COMMENTS: Query Volumes and search for CSVFS volumes which are not detected by Zabbix by default
#
# REQUIREMENTS:
# Execution Policy must be set on "remotesigned"
#
# USAGE:
#   as a script:    C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -command  "& %programfiles%\Zabbix\Scripts\Get-Cluster-FS-Volumes.ps1 <ITEM_TO_QUERY> <ScopeID>"
#  EX:
#  Get-Cluster-FS-Volumes.ps1 Discovery 
#    #(will return a JSON object with all the scopes. Will be used by Zabbix Dynamic Discovery"
#  Get-Cluster-FS-Volumes.ps1 SizeTotal "Volume Name" 
#    #(will return Total Size for the specified Volume Name).
#  Get-Cluster-FS-Volumes.ps1 SizeAvailable "Volume Name" 
#    #(will return Total Size for the specified Volume Name).

# Add to Zabbix Agent
#   UserParameter=CSVFSMON[*],%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -nologo -file "%programfiles%\Zabbix\Scripts\Get-Cluster-FS-Volumes.ps1" $1 $2
#
#
# Version History:
# 2016.05.25 - GDE - Initial Script
# -----------------------------------------------------------------------------------------------------


$version = "1.0.0"

$ITEM = [string]$args[0]
$ID = [string]$args[1]


# Query Volumes for CSVFS volumes
switch ($ITEM) {
  "Discovery" {
    # Open JSON object
    $output =  "{`"data`":["
      $query = Get-Volume | where FileSystem -eq CSVFS | Select-Object FileSystemLabel,SizeRemaining,Size
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
	    $UniqueID = [string]$object.UniqueId
        $FSLabel = [string]$object.FileSystemLabel
        $SizeAvailable = [string]$object.SizeRemaining
		$SizeTotal = [string]$object.Size
        if ($count -eq 1) {
          $output = $output + "{`"{#UNIQUEID}`":`"$UniqueID`",`"{#FSLABEL}`":`"$FSLabel`",`"{#SIZEAVAILABLE}`":`"$SizeAvailable`",`"{#SIZETOTAL}`":`"$SizeTotal`"}"
        } else {
          $output = $output + "{`"{#UNIQUEID}`":`"$UniqueID`",`"{#FSLABEL}`":`"$FSLabel`",`"{#SIZEAVAILABLE}`":`"$SizeAvailable`",`"{#SIZETOTAL}`":`"$SizeTotal`"},"
        }
        $count--
    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
  }
"SizeTotal"{
 $query =  Get-Volume | Where-Object {$_.UniqueId -like "*$ID*"}
 [string]$query.Size
 }
 "SizeAvailable"{
 $query = Get-Volume | Where-Object {$_.UniqueId -like "*$ID*"}
 [string]$query.SizeRemaining
 }
  default {
     Write-Host "-- ERROR -- : Need an option to work !"
 }
}
