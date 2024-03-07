# Script: Get-VBRJob
# Author: Gaël Denizot
# Description: Query Veeam job information
# License: GPL2
#
# This script is intended for use with Zabbix > 2.0
#
# USAGE:
#   as a script:    C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -command  "& C:\Zabbix\zabbix_vbo_job.ps1 <ITEM_TO_QUERY> <JOBID>"
#   as an item:     vbr[<ITEM_TO_QUERY>,<JOBID>]
#
# Add to Zabbix Agent
#   UserParameter=vbo[*],%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -nologo -file "%programfiles%\Zabbix\Scripts\zabbix_vbo_job.ps1" $1 $2
#
# Change Log:
# 27.07.2023: Add Repository discovery

$version = "1.0.10"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference="SilentlyContinue"

$ITEM = [string]$args[0]
$ID = [string]$args[1]

#* Load Veeam snapin
$productName = "Veeam Backup for Microsoft 365 PowerShell Toolkit"
$moduleName = "Veeam.Archiver.PowerShell"
$host.ui.RawUI.WindowTitle = "$productName"

Import-Module $moduleName

$powershellModules = @("Veeam.Exchange.PowerShell", "Veeam.SharePoint.PowerShell", "Veeam.Teams.PowerShell");
$powershellModulesTargetVersion = '2.0'

$warningMessages = @()

foreach($module in $powershellModules)
{
    $availableModule = Get-Module -ListAvailable -Name $module;
    if($availableModule)
    {
		$compatibleModule = $availableModule  | Where-Object { $_.Version -eq $powershellModulesTargetVersion };
		if($compatibleModule)
		{
			$compatibleModule | Import-Module | out-null
		}
		else
		{
			$warningMessages += "{0} module is not compatible with current version VBO PowerShell" -f $module
		}
    }
}




# Function to set the culture for a part of the script
Function Using-Culture (
[System.Globalization.CultureInfo]$culture = (throw “USAGE: Using-Culture -Culture culture -Script {scriptblock}”),
[ScriptBlock]$script= (throw “USAGE: Using-Culture -Culture culture -Script {scriptblock}”))
{
    $OldCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    trap 
    {
        [System.Threading.Thread]::CurrentThread.CurrentCulture = $OldCulture
    }
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
    Invoke-Command $script
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $OldCulture
}



# Query VEEAM for Job. Include only enabled jobs
switch ($ITEM) {
  "Discovery" {
    # Open JSON object
    $output =  "{`"data`":["
      $query = get-vbojob | Where-Object {$_.IsEnabled -eq "true"} | Select-Object Id,Name, SchedulePolicy -EA 0 -WA 0
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.SchedulePolicy
        if ($count -eq 1) {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`",`"{#JOBSCHEDPOLICY}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`",`"{#JOBSCHEDPOLICY}`":`"$Schedule`"},"
        }
        $count--
        }
       # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}


"RepoDiscovery" {
    # Open JSON object
    $output =  "{`"data`":["
      $query = Get-VBORepository | Select-Object Id,Name -EA 0 -WA 0
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.SchedulePolicy
        if ($count -eq 1) {
          $output = $output + "{`"{#REPOID}`":`"$Id`",`"{#REPONAME}`":`"$Name`"}"
        } else {
          $output = $output + "{`"{#REPOID}`":`"$Id`",`"{#REPONAME}`":`"$Name`"},"
        }
        $count--
        }
       # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

"RepoInfo"{
# Open JSON object
    $output =  "{`"data`":["
      $query = Get-VBORepository | Where-Object {$_.Id -like "*$ID*"}
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $IsOutdated = [string]$object.IsOutdated
        $Capacity = [string]$object.Capacity
        $FreeSpace = [string]$object.FreeSpace
        $RetentionType = [string]$object.RetentionType
        $RetentionPeriod = [string]$object.RetentionPeriod
        $RetentionFrequencyType = [string]$object.RetentionFrequencyType
        $EnableObjectStorageEncryption = [string]$object.EnableObjectStorageEncryption
        $IsOutOfSync = [string]$object.IsOutOfSync
        $IsLongTerm = [string]$object.IsLongTerm

        if ($count -eq 1) {
          $output = $output + "{`"{#REPOID}`":`"$Id`",`"{#REPONAME}`":`"$Name`",`"{#REPOISOUTDATED}`":`"$IsOutdated`",`"{#REPOCAPACITY}`":`"$Capacity`",`"{#REPOFREESPACE}`":`"$FreeSpace`",`"{#REPORETENTIONTYPE}`":`"$RetentionType`",`"{#REPORETENTIONPERIOD}`":`"$RetentionPeriod`",`"{#REPORETENTIONFREQUENCYTYPE}`":`"$RetentionFrequencyType`",`"{#REPOENABLEOBJECTSTORAGEENCRYPTION}`":`"$EnableObjectStorageEncryption`",`"{#REPOISOUTOFSYNC}`":`"$IsOutOfSync`",`"{#REPOISLONGTERM}`":`"$IsLongTerm`"}"
        } else {
          $output = $output + "{`"{#REPOID}`":`"$Id`",`"{#REPONAME}`":`"$Name`",`"{#REPOISOUTDATED}`":`"$IsOutdated`",`"{#REPOCAPACITY}`":`"$Capacity`",`"{#REPOFREESPACE}`":`"$FreeSpace`",`"{#REPORETENTIONTYPE}`":`"$RetentionType`",`"{#REPORETENTIONPERIOD}`":`"$RetentionPeriod`",`"{#REPORETENTIONFREQUENCYTYPE}`":`"$RetentionFrequencyType`",`"{#REPOENABLEOBJECTSTORAGEENCRYPTION}`":`"$EnableObjectStorageEncryption`",`"{#REPOISOUTOFSYNC}`":`"$IsOutOfSync`",`"{#REPOISLONGTERM}`":`"$IsLongTerm`"},"
        }
        $count--
        }
       # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

# Query VEEAM Job Status
  "Result"  {
  $query = Get-VBOJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
    if ($query) {switch ([string]$query.LastStatus) {
      "Failed" {
        return "0"
      }
      "Warning" {
        return "1"
      }
	  "Running" {
		return "2"
	  }
      "Success" {
        return "3"
      }
      default {
        return "4"
      }

    }
    else {"4"}
  }
}

# Query VEEAM Job Last Run
  "LastRun"  {
  $query = Get-VBOJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
  $LastRun=([string]$query.LastRun)
  using-culture en-US {NEW-TIMESPAN -Start $LastRun | Select-Object -ExpandProperty "TotalSeconds"}
        
}

# Query VEEAM Job Last Run
  "NextRun"  {
  $query = Get-VBOJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
  $NextRun=([string]$query.NextRun)
  using-culture en-US {NEW-TIMESPAN -End $NextRun | Select-Object -ExpandProperty "TotalSeconds"}   
}


# Query VEEAM Job Scheduled Policy # Can be Daily, Perodically and <Not Scheduled>
  "SchedulePolicy"  {
  $query = Get-VBOJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
  ([string]$query.SchedulePolicy)
  
      
}

  "ExpiryDays" {
  Try{
  $expirationDate = (Get-VBOLicense).ExpirationDate
  }Catch{ 
	$expirationDate = $null
  }
  $EndDate="$expirationDate"
  using-culture en-US {NEW-TIMESPAN –End $EndDate | Select-Object -ExpandProperty "Days"}
  }
  default {
      Write-Host "-- ERROR -- : Need an option to work !"
  }
}
