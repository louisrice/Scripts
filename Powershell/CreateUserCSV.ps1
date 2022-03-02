#This script takes a CSV file from our new hire form and creates a new AD user
#Has 2 module dependencies
#Requires -Modules MSOnline, AzureAD


$csv=Import-Csv "\\path\to\file\newhire.csv" #open CSV so we can get data from it
$employeeName = $csv | select -ExpandProperty "Name" #get employee name from CSV
$firstName, $lastName = -split $employeeName #split the employee name into First/Last, stored into firstName and lastName
$workLocation = $csv | select -ExpandProperty "Office" 
$department = $csv | select -ExpandProperty "Department" 
$jobTitle = $csv | select -ExpandProperty "JobTitle" 
$gender = $csv | select -ExpandProperty "Gender"

Remove-Item -Path "\\path\to\file\newhire.csv" #Delete the CSV now that we have gotten the required info

$localUser = $env:USERNAME

#Assign default variables
$OUpath = "OU=contoso,DC=contoso,DC=local"
$scriptpath = "3D.bat"
$dom = $env:userdomain

#Location Specific Assignments
Switch ($workLocation)
{
    'Tampa'{$usageLocation="US"; $locationID = "1"}
    'Remote'{$usageLocation="US"; $locationID = "1"}
    'India'{$usageLocation="IN"; $locationID = "2"}
}

If ($workLocation -like "Tampa" -Or $workLocation -like "Remote"){ #Checks if the new hire is in USA or India
        Switch ($department) #Set OU Path, logon script, and group based on the new hire's department
        {
            '2D - Floorplans'{$department="2D"; $OUpath="OU=2D,OU=contoso,DC=contoso,DC=local"; $scriptpath = "2D.bat"; $group = "2D_BASE"; $positionId = 20}
            '2D - Graphics'{$department="2D"; $OUpath="OU=2D,OU=contoso,DC=contoso,DC=local"; $scriptpath = "2D.bat"; $group = "2D_BASE"; $positionId = 20}
            '3D'{$department="3D"; $OUpath="OU=3D,OU=contoso,DC=contoso,DC=local"; $scriptpath = "3D.bat"; $group = "3D_BASE"; $positionId = 10}
            'Account Coordinator'{$department="Client Services"; $OUpath="OU=Account Coordinators,OU=contoso,DC=contoso,DC=local"; $scriptpath = "AM.bat"; $group = "AC_BASE"; $positionId = 26}
            'Account Executive'{$department="Client Services"; $OUpath="OU=Account Executives,OU=contoso,DC=contoso,DC=local"; $scriptpath = "AM.bat"; $group = "AE_BASE"; $positionId = 95}
            'Account Manager'{$department="Client Services"; $OUpath="OU=Account Managers,OU=contoso,DC=contoso,DC=local"; $scriptpath = "AM.bat"; $group = "AM_BASE"; $positionId = 28}
            'Director'{$department="Administrative"; $OUpath="OU=Administrative,OU=contoso,DC=contoso,DC=local"; $scriptpath = "Admin.bat"; $group = "ADMIN_BASE"; $positionId = 120}
            'Studio'{$department="Studio"; $OUpath="OU=3D,OU=contoso,DC=contoso,DC=local"; $scriptpath = "3D.bat"; $group = "STUDIO_BASE"; $positionId = 13}
            'Contractor'{$department="Contractor"; $OUpath="OU=Contractors,OU=contoso,DC=contoso,DC=local"; $scriptpath = ""; $group = "_All contoso"; $positionId = 117}
            'Development'{$department="Development"; $OUpath="OU=Development,OU=contoso,DC=contoso,DC=local"; $scriptpath = "Development.bat"; $group = "DEV_BASE"; $positionId = 39}
            'IT'{$department="IT"; $OUpath="OU=IT,OU=contoso,DC=contoso,DC=local"; $scriptpath = "IT.bat"; $group = "IT_BASE"; $positionId = 42}
            'Marketing'{$department="Creative Services"; $OUpath="OU=Marketing Dept,OU=contoso,DC=contoso,DC=local"; $scriptpath = "AM.bat"; $group = "CS_BASE"; $positionId = 105}
            'Print'{$department="Print"; $OUpath="OU=Print,OU=contoso,DC=contoso,DC=local"; $scriptpath = "Print.bat"; $group = "PRINT_BASE"; $positionId = 41}
            'Product Engineering'{$department="Product Engineering"; $OUpath="OU=R&D,OU=contoso,DC=contoso,DC=local"; $scriptpath = "development.bat"; $group = "PE_BASE"; $positionId = 111}
            'Sales'{$department="Sales"; $OUpath="OU=Sale,OU=contoso,DC=contoso,DC=local"; $scriptpath = "am.bat"; $group = "SALES_BASE"; $positionId = 35}
            'Other'{$department="Other"; $OUpath="OU=Other,OU=contoso,DC=contoso,DC=local"; $scriptpath = "Other.bat"; $group = "OTHER_BASE"; $positionId = 72}
        }   
}

ElseIf ($workLocation -like "India"){ #This is where you will add any other assignments specific to India
        $OUpath = "OU=Active,OU=ODC,OU=contoso,DC=contoso,DC=local"
        $department="ODC"
        $scriptpath = "ODCWS.bat"
}

$accountName = $firstName[0]+$lastName #Gets first letter of first name and entire last name and combines them. For example, Louis Rice would have the username LRice
$oldAccountName =(($firstName+$lastName[0]).ToLower()) #Creates username in the old format of first letter of first name and full last name. Used to check if the user already exists in AD
$accountName = ($accountName.ToLower())
$firstInitial = $firstName.Substring(0,1) #get first letter of $firstName
$lastInitial = $lastName.Substring(0,1) #get first letter of $lastName
$password = $firstInitial + $lastInitial + "contoso`$1234!"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

If (dsquery user -samid $accountName) #Check if user already exists in AD
{
    $addDigit = Read-Host -Prompt "Error: Username already exists in Active Directory, would you like to add a digit? (Y/N)"
    Switch ($addDigit)
    {
       Y{$accountName = $accountName + "1"}
       N{"Goodbye";exit} 
    }
}
ElseIf (dsquery user -samid $oldAccountName){"Error: Username already exists in Active Directory (old method)"; pause ; exit}


$emailAddress = $accountName + "@contoso.com"
#Detemine manager from department
if ($department -like "2D"){$manager = "lrice"}
ElseIf($department -Like "3D"){$manager = "lrice"}
ElseIf($department -Like "Client Services"){$manager = "lrice"; $ccU = "lrice"}
ElseIf($department -Like "Administrative"){$manager = "lrice"}
ElseIf($department -Like "Studio"){$manager = "lrice"}
ElseIf($department -Like "Contractor"){$manager = "lrice"}
ElseIf($department -Like "Development"){$manager = "lrice"}
ElseIf($department -Like "IT"){$manager = "lrice"}
ElseIf($department -Like "Creative Services"){$manager = "lrice"}
ElseIf($department -Like "Print"){$manager = "lrice"}
ElseIf($department -Like "Product Engineering"){$manager = "lrice"}
ElseIf($department -Like "Sales"){$manager = "lrice"}

$managerName = ([adsi]"WinNT://$dom/$manager,user").fullname #Get name of manager from AD


Write-Host ""
Write-Host "Below are the attributes set for the account." -ForegroundColor Red
Write-Host ""
Write-Host ""
Write-Host "First name: " -ForegroundColor Green -NoNewLine
Write-Host $firstname #outputs first name so script runner can verify it was set correctly
Write-Host "Last name: " -ForegroundColor Green -NoNewLine 
Write-Host $lastName #outputs last name so script runner can verify it was set correctly
Write-Host "Windows Username: " -ForegroundColor Green -NoNewLine 
Write-Host $accountName #outputs username so script runner can verify it was set correctly
Write-Host "Password: " -ForegroundColor Green -NoNewLine 
Write-Host $password #outputs the password so that the script runner can verify it was set correctly
Write-Host "Email address: " -ForegroundColor Green -NoNewLine
Write-Host $emailAddress #outputs email address so script runner can verify it was set correctly
Write-Host "Extension: " -ForegroundColor Green -NoNewLine
Write-Host $extension #outputs extension address so script runner can verify it was set correctly
Write-Host "Department: " -ForegroundColor Green -NoNewLine 
Write-Host $department #outputs department so script runner can verify it was set correctly
Write-Host "Job Title: " -ForegroundColor Green -NoNewLine 
Write-Host $jobTitle #outputs job title so script runner can verify it was set correctly
Write-Host "Manager: " -ForegroundColor Green -NoNewLine 
Write-Host $managerName #outputs managerlocation so script runner can verify it was set correctly
Write-Host "Work Location: " -ForegroundColor Green -NoNewLine 
Write-Host $workLocation #outputs work location so script runner can verify it was set correctly
Write-Host "OU Path is " -ForegroundColor Green -NoNewLine 
Write-Host $OUpath #outputs OU path so script runner can verify it was set correctly
Write-Host "Logon Script is " -ForegroundColor Green -NoNewLine 
Write-Host $scriptpath #outputs script path so script runner can verify it was set correctly
Write-Host "Assigned Group is " -ForegroundColor Green -NoNewLine 
Write-Host $group #outputs group so script runner can verify it was set correctly
Write-Host ""
Write-Host ""

$CurrentDate = Get-Date
$CurrentDate = $CurrentDate.ToString('MM-dd-yyyy')
$CurrentTime = Get-Date
$CurrentTime = $CurrentTime.ToString('hh:mm:ss')
$DateHired = Get-Date
$DateHired = $DateHired.ToString('yyyy-MM-ddThh:mm:ss')

#Append some data to a CSV file for logging purposes
New-Object -TypeName PSCustomObject -Property @{
Name = $employeeName
AccountName = $accountName
Password = $password
Email = $emailAddress
Department = $department
JobTitle = $jobTitle
Location = $workLocation
OU = $OUpath
Script = $scriptpath
Date = $CurrentDate
Time = $CurrentTime
Extension = $extension
Manager = $managerName
Group = $group
Gender = $gender
} | Export-Csv -Path \\path\to\file\createdUsers.csv -NoTypeInformation -Append -Force

#Check some cases that require additional actions
if ($department -like "2D - Graphics") {
    Add-ADGroupMember -Identity "*2D Graphics" -Members $accountName 
}
elseIf ($department -like "2D - Floorplans") {
Add-ADGroupMember -Identity "*FloorPlans" $accountName
}
elseIf ($department -like "Client Services") {
    Add-ADGroupMember -Identity "_AM" $accountName
}

#the below command uses all the variables that contain data from the CSV to create an AD object with the correct attributes and in the correct OU 
New-ADUser -Name $employeeName -GivenName $firstName -Surname $lastName -DisplayName $employeeName -SamAccountName $accountName -Department $department -Title $jobTitle -UserPrincipalName $emailAddress -EmailAddress $emailAddress -Path $OUpath -AccountPassword $securePassword

Set-ADUser $accountName -Add @{ProxyAddresses="SMTP:$emailAddress", "smtp:$accountName@contoso.local", "smtp:$accountName@contoso.mail.onmicrosoft.com"} #Add SMTP proxy addresses in AD
Add-ADGroupMember -Identity $group $accountName #Add user to the group set in the Switch block on line 32
Add-ADGroupMember -Identity "_All contoso" $accountName #Add user to group that contains all employees
Get-ADUser $accountName | Set-ADUser -Manager $manager #Set the manager in AD
Import-Module activedirectory
Start-Sleep -s 10

Enable-ADAccount -Identity $accountName #enables the AD account. Otherwise the account would be disabled

#Run AD Sync
Invoke-Command -ComputerName int-p-exch1 -ScriptBlock{
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta
}

exit