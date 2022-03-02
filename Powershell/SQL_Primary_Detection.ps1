#Checks if SQL1 is currently the primary SQL server

import-module sqlserver

$svr = "SQLListener" # this can be any server involved in Availability Group
$AGPath = "sqlserver:\SQL\$svr\default\AvailabilityGroups" #Availibility group path
$result = dir -path $AGPath | select-object Name, PrimaryReplicaServerName #Get availibility grouyps
$Primary = $result.PrimaryReplicaServerName #get the Primary server from the availibility group 


if ($Primary -eq "sql1"){ #Check if primary is currently SQL1
    Write-Host "SQL1 is primary"
}

else { #if SQL1 is not primary
    $Pingable = "True"

    $JobUriParameters = @(
        @{ Name = 'Pingable'; Value = $Pingable})

    #Convert to JSON parameters
    $MSFlowParam = ConvertTo-Json -InputObject $JobUriParameters

	#Trigger a power automate function that sends a text message alerting us that SQL1 is not primary
    Invoke-WebRequest -Uri 'https://prod-113.westus.logic.azure.com:443/workflows/<Trigger>' -ContentType "application/json" -Method POST -Body $MSFlowParam
}