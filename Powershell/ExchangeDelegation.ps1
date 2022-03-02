#This script lets you add or remove delegates for someones Exchange mailbox, rather than having to use the Exchange Admin Center

function 30_second_sleep{ #Source: https://www.reddit.com/r/PowerShell/comments/b2n23e/powershell_count_down_timer/eitx9h5/
    [int]$Time = 30
    $Length = $Time / 100
    For ($Time; $Time -gt 0; $Time--) {
        $min = [int](([string]($Time/60)).split('.')[0])
        $text = " " + $min + " minutes " + ($Time % 60) + " seconds left"
        Write-Progress -Activity "Watiting for..." -Status $Text -PercentComplete ($Time / $Length)
        Start-Sleep 1
    }
}

function AddDelegation {
    $delegated_mailbox = Read-Host "Enter the mailbox address that people need access to" 
    $email = ""
    $done = $False
    $delegates = New-Object System.Collections.Generic.List[System.Object] #Create an empty list to store email addresses in later
    while ($done -ne $True){
        $email = Read-Host "Enter the email address of someone that needs access to the mailbox and press enter. If you are done entering emails, type 'done' and hit enter"
        
        if ($email.ToLower() -eq "done"){ #Check if user is done inputting email addresses
            $done = $True
        } #end of if statement
        else {
            $delegates.Add($email) #Add email address to $delegates
        }
    }

    $verified = $False
    while ($verified -ne $True){ #Loops until user enters 1 for the Read-Host on line 38
    write-host ""
    write-host -NoNewLine "Mailbox we are giving access to is: "
    write-host  $delegated_mailbox -ForegroundColor Yellow
    write-host -NoNewLine "Addresses getting access to that mailbox are: "
    write-host  $delegates -ForegroundColor Yellow
    write-host ""
    $choice = Read-Host "Is this correct? 1 for Yes, 2 for No"

        switch ($choice){
            1{ $verified = $True }
            2{ $choice2 = Read-Host "Do you need to change the mailbox we are giving access to? 1 for Yes, 2 for No"
                if ($choice2 -eq "1"){ #If the delegated mailbox needs to change
                    $delegated_mailbox = Read-Host "Enter the mailbox address that people need access to" 
                }
                $choice3 = Read-Host "Do you need to change the addresses that get access to the mailbox? 1 for Yes, 2 for No"
                if ($choice3 -eq "1"){ #if the people getting access to the delegated mailbox needs to change
                    $delegates.Clear() #Empty the list of delegates
                    $done2 = $False
                    while ($done2 -ne $True){ #get the list of delegates again
                        $email = Read-Host "Enter the email address of someone that needs access to the mailbox and press enter. If you are done entering emails, type 'done' and hit enter"
                        
                        if ($email.ToLower() -eq "done"){
                            $done2 = $True
                        } #end of if statement
                        else {
                            $delegates.Add($email)
                        }
                    } #end of while loop
                }
            } #end of switch option 2
            Default { Write-Host "Unknown input, please enter a choice from above"}
        } #end of switch ($choice)
    } #end of while ($verified)

    Write-Host "Attempting to add delegation. . ." -Foregroundcolor Red
    foreach ($delegate in $delegates){ #Give delegation to all addresses in the $delegates list 
        Add-MailboxPermission -Identity $delegated_mailbox -User $delegate -AccessRights FullAccess -InheritanceType All -AutoMapping $false -Confirm:$false > $null
        Add-RecipientPermission -Identity $delegated_mailbox -Trustee $delegate -AccessRights SendAs -Confirm:$false > $null
        }
        30_second_sleep #calls custom sleep function

    Write-Host "Checking that the delegation has been added. . ." -ForegroundColor Green
    CheckDelegation($delegated_mailbox)

}#end of AddDelegation function


Function RemoveDelegation { #removes all delegation from the specified mailbox
    $mailbox = Read-Host "Enter the email address you want to remove delegation from"

    $verified2 = $False
    while ($verified2 -ne $True){  #Loops until user enters 1 ffor the Read-Host on line 97
        #Gets delegation info for the specified mailbox, excluding "NT AUTHORITY\SELF" as this needs to stay
        $delegates = Get-MailboxPermission -identity $mailbox | where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false } 

        Write-Host ""
        Write-Host -NoNewLine "Mailbox we are removing delegation from: "
        Write-Host $mailbox -ForegroundColor Yellow
        Write-Host -NoNewLine "Addresses that will lose access to the mailbox: "
        Write-host ""
        foreach ($address in $delegates){
            Write-Host -NoNewLine $address.user -ForegroundColor Yellow
            Write-Host -NoNewLine " "
        }
        Write-Host ""
        $choice2 = Read-Host "Is this correct? 1 for Yes, 2 for No"
        switch($choice2){
            1{
                #Loop through all elements in $delegates and remove the delegation
                foreach ($address in $delegates) { 
                Remove-MailboxPermission -Identity $mailbox -User $address.user -AccessRights FullAccess -InheritanceType All -Confirm:$false
                Remove-RecipientPermission -Identity $mailbox -Trustee $address.user -AccessRights SendAs -Confirm:$false
                Write-Host ""
                Write-Host "Attempting to remove delegation. . ." -Foregroundcolor Green
                Write-Host "Sleeping for 30 seconds. . ." -ForegroundColor Red
                30_second_sleep #calls custom sleep function
                Write-host ""
                Write-host "Checking that the delegation has been removed. . ."
                CheckDelegation($mailbox) #calls CheckDelegation function, passing the $mailbox variable to it

                }#end of foreach loop
                $verified2 = $True
            }
            
            2{  write-host ""
                $choice2 = Read-Host "Do you need to change the mailbox we are removing access from? 1 for Yes, 2 for No"
                    if ($choice2 -eq "1"){ #If the delegated mailbox needs to change
                        $mailbox = Read-Host "Enter the mailbox address to remove access from" 
                        Write-host ""
                    }
                } #end of switch option 2
            Default { Write-Host "Unknown input, please enter a choice from above"}
     } #end of switch
    } 
} #end of RemoveDelegation function

function CheckDelegation { #Gets current delegates for a given email address
    param ([string]$mailbox)
    if ($mailbox -eq ""){
    $mailbox = Read-Host "Enter the email address you want to check the delegation status of"
    }
    $delegates = Get-MailboxPermission -identity $mailbox | where {$_.user.tostring() -ne "NT AUTHORITY\SELF" -and $_.IsInherited -eq $false } #get delegates

    
    if ($delegates -eq $null){ #if there are no delegates
        Write-Host -Nonewline "No one is delegated to "
        Write-Host $mailbox -ForegroundColor Yellow
    }#end of if
    else { #if there are delegates
        Write-Host -NoNewLine "Addresses currently delegated to "
        Write-host $mailbox -Foregroundcolor Red
        foreach ($address in $delegates){
            Write-Host -NoNewLine $address.user -ForegroundColor Yellow
            Write-Host -NoNewLine " "
            }
    } #end of Else
}#end of CheckDelegation function

function Main-Menu {
    Write-Host ""
    Write-Host "----------- Main Menu -----------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1 - Add delegataion"
    Write-Host "2 - Remove delegation"
    Write-Host "3 - Check delegation status"
    Write-Host "4 - Exit"
    Write-Host ""
    Write-Host "----------- End of Main Menu -----------" -ForegroundColor Yellow
    Write-Host ""
}

Connect-ExchangeOnline
#Main loop of script
while($true){ #runs until user exits script with option 3 at the main menu choice selection
    Main-Menu #call Main-Menu function
    $menu_choice = Read-Host "Choose an option" #get choice from user

    switch ($menu_choice) {
        1 { AddDelegation }
        2 { RemoveDelegation }
        3 { CheckDelegation }
        4 {  #User wants to exit
            Disconnect-ExchangeOnline -Confirm:$false
            Exit 
            }
        Default { Write-Host "Unknown input, please enter a choice from above"}
    } #end of switch ($menu_choice)
} #end of infinite loop
