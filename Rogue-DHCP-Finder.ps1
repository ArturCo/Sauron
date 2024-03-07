# -----------------------------------------------------------------------------------------------------
# NAME: Rogue-DHCP-Finder.ps1
# AUTHOR: Gaël DENIZOT
# DATE:2022.05.03
# 
# COMMENTS: Powershell script to check if there is a Rogue DHCP
# 1) If no Rogue DHCP found, returns "none" otherwise, it returns the Rogue DHCP IP
#
# REQUIREMENTS:
# Execution Policy must be set on "remotesigned"
# Command line is : Rogue-DHCP-Finder.ps1 list_of_trusted_dhcp_ip_addresses
# Version History:
# 2022.05.03 - GDE - Initial Script
# -----------------------------------------------------------------------------------------------------


param([String[]] $AllowedDHCPServers)


$BinLocation = "%programfiles%\Zabbix\Scripts\"

$Tests = 0
$ListedDHCPServers = do {
    & "$BinLocation\DHCPTest.exe" --quiet --query --print-only 54 --wait --timeout 3
    $Tests ++
} while ($Tests -lt 2)

$ListedDHCPServers = $ListedDHCPServers | sort -unique

#$DHCPHealth = foreach ($ListedDHCPServer in $ListedDHCPServers) {
#	foreach ($AllowedDHCPServer in $AllowedDHCPServers){
#		if ($ListedDHCPServer -ne $AllowedDHCPServer) {
#			$ListedServers = $ListedServers + $ListedServer 
#			write-host $ListedServers 
#			#"Rogue DHCP Server found. IP of rogue server is $ListedServer" 
#			}
#	}
#}

$DHCPHealth = foreach ($ListedDHCPServer in $ListedDHCPServers){
	if ($AllowedDHCPServers.Contains("$ListedDHCPServer") -eq $false) {
		$ListedServers = $ListedServers + $ListedDHCPServer }
}

if ($ListedServers -eq $null){
write-host "none"}else{write-host "$ListedServers"}
