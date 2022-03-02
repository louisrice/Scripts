 # This script lets you easily perform actions on our FTP site, such as creating a user or folder

$MLPassword = ''

function Choice-Menu{ #Ask what we need to change
    Write-Host "`nWhat do you need to change?"
    Write-Host "1 - Username"
    Write-Host "2 - Password"
    Write-Host "3 - Nothing"
}

function Command-Copied {
    Write-Host "Command has been copied to clipboard, use it in the Jar file before proceeding" -ForegroundColor Red
}

function Get-ftpPW {
    $temp = Read-Host "Enter FTP admin password"
    return $temp
}

function Get-RandomCharacters($length, $characters) { #Select random characters from the strings of characters in function Random-Password
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $private:ofs="" 
    return [String]$characters[$random]
}

function Main-Menu {
    Write-Host ""
    Write-Host "----------- Main Menu -----------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1 - Make FTP User"
    Write-Host "2 - Create folder in F drive"
    Write-Host "3 - Give access to a folder"
    Write-Host "4 - Delete User"
    Write-Host "5 - Change FTP login password (currently " -NoNewline
    Write-Host "$MLPassword" -ForegroundColor Blue -NoNewline
    Write-Host ")"
    Write-Host "6 - Connect to FTP"
    Write-Host "7 - Exit"
}

function Random-Password($randomPassword) { #generate a random password
    $randomPassword = Get-RandomCharacters -length 4 -characters 'abcdefghiklmnoprstuvwxyz'
    $randomPassword += Get-RandomCharacters -length 4 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $randomPassword += Get-RandomCharacters -length 4 -characters '1234567890'
    $randomPassword += Get-RandomCharacters -length 3 -characters '$&/()=?}][{@#*+'
    return $randomPassword
}

function Scramble-String([string]$inputString){ #randomize the password string
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

function Start-Jar($MLPassword) { #runs jar file to connect to FTP server, using provided password
    Start-Process -FilePath java -ArgumentList "-jar \\path\to\file\CrushTunnel.jar https://username:$MLPassword@ftp.contoso.com"
}

function Verify-Info($newUserName, $randomScrambledPassword){ #prints info given by user for verification
    Write-Host "`nPlease verify the below information" -ForegroundColor Red
    Write-Host "Username: $newUserName"
    Write-Host "Password: $randomScrambledPassword"
}

#Asks you to enter FTP admin password and then connects to the FTP using the .jar file
$MLPassword = Get-ftpPW
Start-Jar $MLPassword

while($true) { #runs until user exits
    Main-Menu #prints main menu
    Write-Host "`nChoose an option: " -ForegroundColor Blue -NoNewline
    $menu_choice = Read-Host #get choice from user

    switch ($menu_choice) {
        #create user
        1 { Write-Host "`n`nYou chose: Make user" -ForegroundColor Green

            $newUserName = Read-Host "Enter new username"
            $newPassword = Read-Host "Enter desired password or 1 for a randomly generated password"

            if ($newPassword -eq 1){ #choice is to make a random password
                $randomPassword = Random-Password($randomPassword) #generate a random password
                $randomScrambledPassword = Scramble-String -$randomPassword #scramble the random password
                
                Verify-Info $newUserName $randomScrambledPassword
                Write-Host "`nDo you need to change anything? Y/N " -ForegroundColor Blue -NoNewline
                $changeNeeded = Read-Host 
                while ($changeNeeded -eq 'y'){
                    Choice-Menu #prints list of choices
                    $changeChoice = Read-host #get choice from user
                    switch ($changeChoice){ #check what option was selected
                        1 { $newUserName = Read-Host "Enter new username"
                            Write-Host "`n"
                            Verify-Info $newUserName $randomScrambledPassword }
                        2 { $randomScrambledPassword = Read-Host "Enter desired password or 1 for a randomly generated password"
                            if ($randomScrambledPassword -eq '1'){
                                $randomScrambledPassword = Random-Password($randomScrambledPassword)
                                Scramble-String($randomScrambledPassword)
                                    }
                                Verify-Info $newUserName $randomScrambledPassword }
                        3 { $changeNeeded = 'n'} #exits loop
                            }
                        }#end of switch to change info
                    }#end of if $newPassword -eq 1

                    if ($newPassword -eq 1){ #check if password was randomly generated
                        Set-Clipboard "user user_add MainUsers $newUserName password=$randomScrambledPassword"
                    }
                    else {
                        Set-Clipboard "user user_add MainUsers $newUserName password=$newPassword"
                    }

                    Command-Copied #writes that the command has been copied to clipboard
                    Start-Sleep -Seconds 5 #wait to give script runner time to run command before asking another question
                    Write-Host "`nWould you like to create and assign a folder for user $newUserName in the F drive? Y/N " -NoNewline
                    $createFolderChoice = Read-Host
                    if ($createFolderChoice -eq 'y'){
                        New-Item -Path f:\$newUserName -ItemType Directory #create the folder using same name as created user
                        Set-Clipboard "user vfs_add MainUsers $newUserName path=/$newUserName/ privs=(read)(write)(resume)(delete)(deletedir)(makedir)(rename)(view) url=FILE://E:/Users/$newUserName/ name=$newUserName"
                        Command-Copied #writes that the command has been copied to clipboard
                    }
                
                }#end of create user
        
        #create folder in F drive
        2 { Write-Host "`nYou chose: Create folder in F drive" -ForegroundColor Green
            $newFolder = Read-Host "Enter desired name for the new folder" 
            New-Item -Path f:\$newFolder -ItemType Directory #create the folder using the given name
            } #end of create folder 

        #give access to a folder
        3 { Write-Host "`nYou chose: Give access to a folder" -ForegroundColor Green
            Write-Host "`nEnter file path to give access to: " -NoNewline
            $filePath = Read-Host

            #if first 2 characters of file path are not \\ then it is not a network drive path, which needs to be changed
            if ($filePath.Substring(0,2) -ne "\\"){ 
                $filePath = $filePath.Insert(1,"-drive") #insert -drive after first letter. Ex: if input was a:\folder, it is now a-drive:\folder
                $filePath = $filePath.Replace(":", "") #replace : with nothing (deleting it)
                $filePath = $filePath.replace("\", "/") #replace backward slashes with forward due to required syntax
                $filePath = $filePath.Insert(0, "////fileserver/") #add fileserver name to beginning of string
                }

            #if first 2 characters of file path are \\ we have gotten a network drive path
            else {
                $filePath = $filePath -replace "\\", "/" #replace backslash with forward slash due to API syntax
                $filePath = $filePath.Insert(0,"//") #add 2 forward slashes so the beginning of the file path is //// (API syntax)
            }

                #check if the file path given is mlfs07
            if ($filePath.Substring(0,8) -eq "////mlfs"){ 
                $directoryPath = $filePath.Substring(18) #removes ////server/X-drive from string and stores in $directoryPath
                }

                #if the path isn't server it is mapdrives, which requires a different starting index for the substring
            else {
                $directoryPath = $filePath.Substring(22) #removes ////mapdrives/X-drive from string and stores in $directoryPath
                }  

            #if the last character of $directoryPath is not a slash, add one
            if ($directoryPath.Substring($directoryPath.Length-1) -ne '/'){
                $directoryPath = $directoryPath + "/"
            }
            $name = $directoryPath.Substring(0,$directoryPath.Length-1) #removes the last / from $directoryPath and stores in $name
            $name = $name.Substring($name.LastIndexOf('/')+1) #gets the last sub-folder name by grabbing a substring containing everything after the last /
             
            Write-Host "`nEnter username that needs access: " -NoNewline
            $userName = Read-Host #get username from user
            Write-Host "`nIs full access needed? [Y/N] " -NoNewline
            $fullAccess = Read-Host
            if ($fullAccess -eq 'y'){
                Set-Clipboard "user vfs_add MainUsers $userName path=$directoryPath privs=(view)(read)(write)(resume)(delete)(deletedir)(makedir)(rename) url=FILE:$filePath name=$name"
                Command-Copied #writes that the command has been copied to clipboard  
            }

            else { #user shouldn't have full permissions
                $privs = "privs=(read)(view)(resume)" #read/view/resume are default when giving access via web interface, so i set it by default here too
                $shouldUserHave = "Should the user have "
                $shouldUserHave2 = " permissions? [Y/N] "

                #check if user needs Write permission
                Write-Host $shouldUserHave -NoNewline
                Write-Host "Write" -ForegroundColor Green -NoNewline
                Write-Host $shouldUserHave2 -NoNewline
                switch (Read-Host) {
                    'y' { $privs = $privs + "(write)"  }
                    'n' { Write-Host "Unknown input"}
                    }
                
                #check if user needs delete permission
                Write-Host $shouldUserHave -NoNewline
                Write-Host "Delete" -ForegroundColor Green -NoNewline
                Write-Host $shouldUserHave2 -NoNewline
                switch (Read-Host) {
                    'y' { $privs = $privs + "(delete)" }
                    'n' { Write-Host "Unknown input" }
                    }

                #check if user needs delete directory permission
                Write-Host $shouldUserHave -NoNewline
                Write-Host "Delete Directory" -ForegroundColor Green -NoNewline
                Write-Host $shouldUserHave2 -NoNewline
                switch (Read-Host) {
                    'y' { $privs = $privs + "(deletedir)" }
                    'n' { Write-Host "Unknown input" }
                    }
                    
                #check if user needs create directory permission
                Write-Host $shouldUserHave -NoNewline
                Write-Host "Create Directory" -ForegroundColor Green -NoNewline
                Write-Host $shouldUserHave2 -NoNewline
                switch (Read-Host) {
                    'y' { $privs = $privs + "(makedir)" }
                    'n' { Write-Host "Unknown input" }
                    }
                
                #check if user needs rename permission
                Write-Host $shouldUserHave -NoNewline
                Write-Host "Rename" -ForegroundColor Green -NoNewline
                Write-Host $shouldUserHave2 -NoNewline
                switch (Read-Host) {
                    'y' { $privs = $privs + "(rename)"}
                    'n' { Write-Host "Unknown input" }
                    }

                Set-Clipboard "user vfs_add MainUsers $userName path=$directoryPath privs=$privs url=FILE:$filePath name=$name"
                Command-Copied #writes that the command has been copied to clipboard  
                }#end of else
            }#end of give access to folder

        #delete user
        4 { Write-Host "You chose: Delete user" -ForegroundColor Green
                $userNameDelete = Read-Host "Enter username to delete"
                Set-Clipboard "user user_delete MainUsers $userNameDelete"
                Command-Copied #writes that the command has been copied to clipboard
            }
        
        #change FTP login password
        5 { $MLPassword = Get-ftpPW } 

        #Connect to FTP
        6 { Write-Host "Starting Jar . . ." -ForegroundColor Green
            Start-Jar $MLPassword 
            }
        
        Default { Write-Host "Unknown input, please enter a choice from above"}

    }#end of switch $menuChoice
}#end of infinite loop