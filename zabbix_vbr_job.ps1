# Script: zabbix_vbr_job
# Author: Gaël Denizot
# Description: Query Veeam job information
# License: GPL2
#
# This script is intended for use with Zabbix > 2.0
# Added License Expiry date calculations and Veeam Agents discovery
# Added multiple monitoring options
#
# RETURNED DATA:
#
#      Id                     : 5e6063aa-49b1-4515-9711-01e6d3083443
#      Name                   : KHP-BCK-JOB-007 - MyJob
#      IsScheduleEnabled      : True
#
# USAGE:
#   as a script:    C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe -command  "& C:\Zabbix\zabbix_vbr_job.ps1 <ITEM_TO_QUERY> <JOBID>"
#   as an item:     vbr[<ITEM_TO_QUERY>,<JOBID>]
#
# Add to Zabbix Agent
#   UserParameter=vbr[*],%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -nologo -file "%programfiles%\Zabbix\Scripts\zabbix_vbr_job.ps1" $1 $2
#
# Change Log:
# 1.0.9 : Add of options for monitoring of Scale-Out repositories
# 1.0.10: Change the comportment regarding warnings and add computer jobs backup monitoring
# 1.0.11: Add of Tape Jobs monitoring

$version = "1.0.11"

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference="SilentlyContinue"

$ITEM = [string]$args[0]
$ID = [string]$args[1]

#* Load Veeam snapin
# Check if PsSNapin is present otherwise rollback to module (v7-v8-v9-v10 vs v11)
$SnapinPresent = if (Add-PsSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue){$true}else{$false}


if ($SnapinPresent -eq $true)
    {Add-PsSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue}
    else{
    Import-Module veeam.backup.powershell  -ErrorAction SilentlyContinue -DisableNameChecking
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
      $query = Get-VBRJob | Where-Object {$_.IsScheduleEnabled -eq "true" -and $_.TypeToString -ne "Windows Agent Policy" } | Select-Object Id,Name, IsScheduleEnabled -EA 0 -WA 0
      #$queryrep = Get-VBREPJob | Where-Object {$_.IsEnabled -eq "true"} | Select-Object Id,Name, IsEnabled -EA 0 -WA 0
      $count = $query | Measure-Object
      $count = $count.count
      $countrep = $queryrep | Measure-Object
      $countrep = $countrep.count
      foreach ($object in $query) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.IsScheduleEnabled
        if ($count -eq 1) {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`",`"{#JOBSCHEDULED}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`",`"{#JOBSCHEDULED}`":`"$Schedule`"},"
        }
        $count--
        }
       # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}
# Query VEEAM Veeam Agent operating in a standalone mode. jobs (only enabled jobs)
"DiscoveryREP" {
    # Open JSON object
    $output =  "{`"data`":["
      $queryrep = Get-VBREPJob | Where-Object {$_.IsEnabled -eq "true"} | Select-Object Id,Name, IsEnabled
      $countrep = $queryrep | Measure-Object
      $countrep = $countrep.count
      foreach ($object in $queryrep) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.IsEnabled
        if ($countrep -eq 1) {
          $output = $output + "{`"{#JOBREPID}`":`"$Id`",`"{#JOBREPNAME}`":`"$Name`",`"{#JOBREPENABLED}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBREPID}`":`"$Id`",`"{#JOBREPNAME}`":`"$Name`",`"{#JOBREPENABLED}`":`"$Schedule`"},"
        }
        $countrep--

    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

"DiscoveryCloudTenant" {
    # Open JSON object
    $output =  "{`"data`":["
      $querytenant = Get-VBRCloudTenant | Where-Object {$_.Enabled -eq "true"} | Select-Object Id,Name,Enabled
      $counttenant = $querytenant | Measure-Object
      $counttenant = $counttenant.count
      foreach ($object in $querytenant) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.Enabled
		
        if ($counttenant -eq 1) {
          $output = $output + "{`"{#JOBCLOUDTENANTID}`":`"$Id`",`"{#JOBCLOUDTENANTNAME}`":`"$Name`",`"{#JOBCLOUDTENANTENABLED}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBCLOUDTENANTID}`":`"$Id`",`"{#JOBCLOUDTENANTNAME}`":`"$Name`",`"{#JOBCLOUDTENANTENABLED}`":`"$Schedule`"},"
        }
        $counttenant--

    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

  "DiscoveryScaleOut" {
    # Open JSON object
    $output =  "{`"data`":["
      $query = Get-VBRBackupRepository -ScaleOut | Select-Object Id,Name
      $count = $query | Measure-Object
      $count = $count.count
      foreach ($object in $query) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        if ($count -eq 1) {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`"}"
        } else {
          $output = $output + "{`"{#JOBID}`":`"$Id`",`"{#JOBNAME}`":`"$Name`"},"
        }
        $count--
        }
       # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

"DiscoveryComputerJobs" {
    # Open JSON object
    $output =  "{`"data`":["
      $querycj = Get-VBRComputerBackupJob | Where-Object {$_.ScheduleEnabled -eq "True"} | Select-Object Id,Name, ScheduleEnabled
      $countcj = $querycj | Measure-Object
      $countcj = $countcj.count
      foreach ($object in $querycj) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.ScheduleEnabled
        if ($countcj -eq 1) {
          $output = $output + "{`"{#JOBCJID}`":`"$Id`",`"{#JOBCJNAME}`":`"$Name`",`"{#JOBCJENABLED}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBCJID}`":`"$Id`",`"{#JOBCJNAME}`":`"$Name`",`"{#JOBCJENABLED}`":`"$Schedule`"},"
        }
        $countcj--

    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}

"DiscoveryTapeJobs" {
    # Open JSON object
    $output =  "{`"data`":["
      $querytj = Get-VBRTapeJob | Select-Object Id,Name, Enabled
      $counttj = $querytj | Measure-Object
      $counttj = $counttj.count
      foreach ($object in $querytj) {
        $Id = [string]$object.Id
        $Name = [string]$object.Name
        $Schedule = [string]$object.Enabled
        if ($counttj -eq 1) {
          $output = $output + "{`"{#JOBTJID}`":`"$Id`",`"{#JOBTJNAME}`":`"$Name`",`"{#JOBTJENABLED}`":`"$Schedule`"}"
        } else {
          $output = $output + "{`"{#JOBTJID}`":`"$Id`",`"{#JOBTJNAME}`":`"$Name`",`"{#JOBTJENABLED}`":`"$Schedule`"},"
        }
        $counttj--

    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
}


"CloudTenantVmCount" {
	[string](Get-VBRCloudTenant -Id "$ID").VmCount
}
"CloudTenantReplicaCount" {
	[string](Get-VBRCloudTenant -Id "$ID").ReplicaCount
}
"CloudTenantLastResult" {
	[string](Get-VBRCloudTenant -Id "$ID").LastResult
}
"CloudTenantThrottlingValue" {
	[string](Get-VBRCloudTenant -Id "$ID").ThrottlingValue
}
"CloudTenantRepositoryQuota" {
	[string](Get-VBRCloudTenant -Id "$ID").Resources.RepositoryQuota
}
"CloudTenantUsedSpace" {
	[string](Get-VBRCloudTenant -Id "$ID").Resources.UsedSpace
}
"CloudGatewayCertificateExpiryDate" {
	$CloudGatewayEnabled = try {(Get-VBRCloudGateway).Enabled} catch {}
	if ($CloudGatewayEnabled -eq $true) {
	[string](New-TimeSpan -End (Get-VBRCloudGatewayCertificate).NotAfter).Days
	} else {
	# Write a value of 99999 to say it's not enabled
	Write-Host "99999"
	}
}


  "Result"  {
  $query = Get-VBRJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsScheduleEnabled -eq "true"}
    if ($query) {switch ([string]$query.GetLastResult()) {
      "Failed" {
        return "0"
      }
      "Warning" {
        return "1"
      }
      default {
        return "2"
      }

    }
  }
    else {"2"}
  }
  "ResultREP"  {
  $query = Get-VBRepJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
    if ($query) {switch ([string]$query.LastResult) {
      "Failed" {
        return "0"
      }
      "Warning" {
        return "1"
      }
      default {
        return "2"
      }

    }
  }
    else {"2"}
  }
  "ResultCJ"  {
  $query = Get-VBRepJob | Where-Object {$_.Id -like "*$ID*" -and $_.IsEnabled -eq "true"}
    if ($query) {switch ([string]$query.LastResult) {
      "Failed" {
        return "0"
      }
      "Warning" {
        return "1"
      }
      default {
        return "2"
      }

    }
  }
    else {"2"}
  }

 "ResultTJ"  {
  $query = Get-VBRTapeJob | Where-Object {$_.Id -like "*$ID*" -and $_.Enabled -eq "true"}
    if ($query) {switch ([string]$query.LastResult) {
      "Failed" {
        return "0"
      }
      "Warning" {
        return "1"
      }
      default {
        return "2"
      }

    }
  }
    else {"2"}
  }

  "RunStatus" {
  $query = Get-VBRJob | Where-Object {$_.Id -like "*$ID*"}
  if ($query.IsRunning) { return "1" } else { return "0"}
  }
  "IncludedSize"{
  $query = Get-VBRJob | Where-Object {$_.Id -like "*$ID*"}
  [string]$query.Info.IncludedSize
  }
  "ExcludedSize"{
  $query = Get-VBRJob | Where-Object {$_.Id -like "*$ID*"}
  [string]$query.Info.ExcludedSize
  }
  "VmCount" {
  $query = Get-VBRBackup | Where-Object {$_.JobId -like "*$ID*"}
  [string]$query.VmCount
  }
  "Type" {
  $query = Get-VBRBackup | Where-Object {$_.JobId -like "*$ID*"}
  [string]$query.JobType
  }
  "RunningJob" {
  $query = Get-VBRBackupSession | where { $_.isCompleted -eq $false } | Measure
  if ($query) {
	[string]$query.Count
    } else {
	return "0"
    }
  }
  "ScaleOutRepStatus" {
  $query = Get-VBRCapacityExtent -Repository "$ID"
  [string]$query.Status
  }
  "ExpiryDays" {
  $regBinary = (Get-Item 'HKLM:\SOFTWARE\VeeaM\Veeam Backup and Replication\license').GetValue('Lic1')
  $VeeamLicInfo = [string]::Join($null, ($regBinary | % { [char][int]$_; }))
  $patternv9 = "Support expiration date\=\d{1,2}\/\d{1,2}\/\d{1,4}"
  $patternv10 = "Support expires\=\d{1,2}\/\d{1,2}\/\d{1,4}"
  $patternv12 = "License expires\=\d{1,2}\/\d{1,2}\/\d{1,4}"
  
  Try{
	  try{
	$expirationDate = [regex]::matches($VeeamLicInfo, $patternv9)[0].Value.Split("=")[1]
	}Catch{ 
	$expirationDate = $null
	}
	 try{
	$expirationDate = [regex]::matches($VeeamLicInfo, $patternv10)[0].Value.Split("=")[1]
	}Catch{
	$expirationDate = $null
	}
	 Try{$expirationDate = [regex]::matches($VeeamLicInfo, $patternv12)[0].Value.Split("=")[1]
	}Catch{
	$expirationDate = $null
	}
  }Finally{
 }

  $EndDate="$expirationDate"
  using-culture fr-CH {NEW-TIMESPAN –End $EndDate | Select-Object -ExpandProperty "Days"}
  }
  default {
      Write-Host "-- ERROR -- : Need an option to work !"
  }
}
