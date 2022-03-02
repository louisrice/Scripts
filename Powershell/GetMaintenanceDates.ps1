#This script outputs all planned Windows update maintenance dates for the year

Write-Host("Monthly Server Windows Updates dates:")
ForEach ($i in 1..12) #Loop runs 12 times
    {
    
    $date = Get-Date -month $i -day 1 #Starts on the 1st of each month
    do
        {
        $date = $date.AddDays(1) #Adds 1 day 
        }
    until  ($date.DayOfWeek -like 'Wednesday' -and $date.Day -ge '15' -and $date.Day -le '21') #Find the 3rd Wednesday of the month
     
    switch($i){
        1{ Write-host "January " -NoNewline }
        2{ Write-host "February " -NoNewline }
        3{ Write-host "March " -NoNewline }
        4{ Write-host "April " -NoNewline }
        5{ Write-host "May " -NoNewline }
        6{ Write-host "June " -NoNewline }
        7{ Write-host "July " -NoNewline }
        8{ Write-host "August " -NoNewline }
        9{ Write-host "September " -NoNewline }
        10{ Write-host "October " -NoNewline }
        11{ Write-host "November " -NoNewline }
        12{ Write-host "December " -NoNewline }
    }#end of switch
    write-host $date.day
}

write-host("")
write-host("")

Write-Host("Monthly Desktop Windows Updates dates:")
ForEach ($i in 1..12)
    {
    
    $date = Get-Date -month $i -day 1
    do
        {
        $date = $date.AddDays(1)
        }
    until  ($date.DayOfWeek -like 'Sunday' -and $date.Day -ge '15' -and $date.Day -le '21') #Find the 3rd Sunday of the month

    switch($i){
        1{ Write-host "January " -NoNewline }
        2{ Write-host "February " -NoNewline }
        3{ Write-host "March " -NoNewline }
        4{ Write-host "April " -NoNewline }
        5{ Write-host "May " -NoNewline }
        6{ Write-host "June " -NoNewline }
        7{ Write-host "July " -NoNewline }
        8{ Write-host "August " -NoNewline }
        9{ Write-host "September " -NoNewline }
        10{ Write-host "October " -NoNewline }
        11{ Write-host "November " -NoNewline }
        12{ Write-host "December " -NoNewline }
    }#end of switch
    write-host $date.day
}
write-host("")
write-host("")

Write-Host("Monthly Render Farm Windows Updates dates:")
ForEach ($i in 1..12)
    {
    
    $date = Get-Date -month $i -day 1
    do
        {
        $date = $date.AddDays(1)
        }
    until  ($date.DayOfWeek -like 'Monday' -and $date.Day -ge '15' -and $date.Day -le '21') #Find the 3rd Monday of the month
     
    switch($i){
        1{ Write-host "January " -NoNewline }
        2{ Write-host "February " -NoNewline }
        3{ Write-host "March " -NoNewline }
        4{ Write-host "April " -NoNewline }
        5{ Write-host "May " -NoNewline }
        6{ Write-host "June " -NoNewline }
        7{ Write-host "July " -NoNewline }
        8{ Write-host "August " -NoNewline }
        9{ Write-host "September " -NoNewline }
        10{ Write-host "October " -NoNewline }
        11{ Write-host "November " -NoNewline }
        12{ Write-host "December " -NoNewline }
    }#end of switch
    write-host $date.day
}