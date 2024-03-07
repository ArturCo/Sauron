# -----------------------------------------------------------------------------------------------------
# NAME: Ping.ps1
# AUTHOR: Gaël DENIZOT, ABISSA Informatique SA
# DATE:2016.04.25
# 
# COMMENTS: Powershell script to ping an IP using Zabbix Agent
#
# REQUIREMENTS:
# Execution Policy must be set on "remotesigned"
# Command line is : Ping.ps1 Mode (Discovery, Ping or Latency) IP (IP Address), Number of pings
# Host in zabbix should have the macro: {$IPADDRESSES} defined with IP Addresses that you want to ping followed by a comma, for ex: {$IPADDRESSES}  =>  8.8.8.8,195.186.1.110
#
# Add to Zabbix Agent
#   UserParameter=PING[*],%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -nologo -file "%programfiles%\Zabbix\Scripts\Ping.ps1" $1 $2 $3
#
#
# Version History:
# 2016.06.13 - GDE - Initial Script
# -----------------------------------------------------------------------------------------------------

$MODE = [string]$args[0]
$IP = [string]$args[1]
$COUNT = [string]$args[2]

switch ($MODE) {
  "Discovery" {
    # Open JSON object
    $output =  "{`"data`":["
		$IPARRAY=$IP.Split(",")
		$COUNTNB = $IPARRAY | Measure-Object
		$COUNTNB = $IPARRAY.count
      foreach ($object in $IPARRAY) {
        $IP=$object
        if ($COUNTNB -eq 1) {
          $output = $output + "{`"{#IP}`":`"$IP`"}"
        } else {
          $output = $output + "{`"{#IP}`":`"$IP`"},"
        }
        $COUNTNB--
    }
    # Close JSON object
    $output = $output + "]}"
    Write-Host $output
  }

  "Ping" {
    # Will return ping count depending on how many ping count. will let us know if there was packet loss
	$ping=test-connection $IP -count $COUNT -ErrorAction 'silentlycontinue' 
	$PingCount=$ping.count
	Write-Host $PingCount
	#if ($ping -eq "true") {
    #      write-host "1"
    #    } else {
    #     write-host "0"
    #    }
		}
    
  "Latency"{
  $ping=test-connection $IP -count $COUNT -ErrorAction 'silentlycontinue' 
  $LatencyAVG = $ping.ResponseTime | measure-object -Average | Select-Object -ExpandProperty Average
  if ($LatencyAVG -match "[0-9]") {
          write-host "$LatencyAVG"
        } else {
          write-host "0"
        }

  }
 
  default {
     Write-Host "Select Mode (Discovery, Ping or Latency) IP Address and number of pings"
 }
}