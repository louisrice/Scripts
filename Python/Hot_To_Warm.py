"""
This script requires the path module to be installed - it does not come installed by defult. It can be installed with pip install path
https://github.com/jaraco/path
https://path.readthedocs.io/en/latest/
Moves old files from the main file server to Warm storage
Made by Louis Rice
"""

import time, csv, datetime, os, stat, sys, subprocess, pdb
import os.path
from path import Path
from shutil import move


"""
USER VARIABLES
"""

driveLetter = sys.argv[1] #get the drive letter given as a paramater when the script was called
num_days_to_move = int(sys.argv[2]) #get the cutoff day value that determines how old a file has to be for it to be archived

#used to manually set the drive or days to archive if needed. If you do need to do this, comment out the above lines since you probably won't be passing parameters
#driveLetter = "J-Drive"
#num_days_to_move = 365 #How old a file has to be (in days) for it to be moved

whiteListFile = open(r"\\file\server\Archiving\Whitelists\{}.txt".format(driveLetter), "r") #open the relevant whitelist file for the drive that was passed as a parameter

filePath_whitelist = whiteListFile.read().splitlines() #read the text file and use splitlines() to remove the \n character from each string

filePath_whitelist = [x.lower() for x in filePath_whitelist] #convert all entries in the list to lowercase

fileType_whitelist = ['.db', '.lnk']#file extensions we don't want to move, no matter how old it is



"""
STATIC VARIABLES (!!!NO TOUCHY!!!)
"""


#time.time() gets current time. There are 86400 seconds in a day, so by multiplying 86400 by number of days and subtacting it from the current time we change the num_days_ago variable to X days in the past
num_days_ago = time.time() - num_days_to_move * 86400

#Current date/time
current_date = datetime.datetime.now() #get current date/time
current_date = current_date.strftime("%Y-%m-%d") #format current_date to be YYYY-MM-DD

#Directory we are moving files from. The r means raw string, which gets around the issue of \ being an escape character
base = Path(r"\\fileserver\{}".format(driveLetter))


"""
END OF STATIC VARIABLES
"""


"""
FUNCTIONS
"""

def J_K_S_Drives(): #used when the drive letter is J K or S
    #Some specific folders have restrictions on what file types can be moved. See below ticket
    # <Redacted link>
    allowedExtensions = ['.3ds', '.mp4', '.wmv', '.psd', '.tif', '.pdf']
    specialFolders = ['01_production', '02_production', '02_post-production', '03_post-production']
    
    with open('\\\\file\\server\\Archiving\\ArchiveLogs\\{}-{}.csv'.format(driveLetter,current_date), mode='a', newline='', encoding='utf-8') as csv_file: #open or create the CSV log file. {} inserts the variables listed after .format
        csv_writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for somefile in base.walkfiles():
            file_extension = os.path.splitext(somefile)[1] #gets the file extension. This is used later to check if the file type is in the whitelist
                    
            if somefile.mtime < num_days_ago: #somefile.mtime is the last time the file was modified. This is compared with num_days_ago to see if the file should be moved
            #if somefile.atime < num_days_ago: #somefile.atime gets the last time the file was accessed. This is compared with num_days_ago to see if the file should be moved
                
                move_file_path = Path.realpath(somefile) #get file path of the file to move
                #file_size = somefile.getsize() #get the file size
                
                if file_extension not in fileType_whitelist: #check if the file type is whitelisted
                    whitelist_check = any(substring in Path.dirname(somefile).lower() for substring in filePath_whitelist) #check if any elements in the white list are substrings of our current file path. If so, this path is whitelisted and nothing should be archived. This returns either True or False into whitelist_check
                    if not whitelist_check: #if whitelist_check is False, the below code is executed
                        whitelist_check2 = any(substring in Path.dirname(somefile).lower() for substring in specialFolders) #check if any elements in the white list are substrings of the specialFolders list. If so the folder has special rules on what can be archived
                        if whitelist_check2: #if the folder is in our specialFolders variable run the below if statement
                            if file_extension in allowedExtensions: #Check if the file extension is in allowedExtensions
                                moveFile(move_file_path, csv_writer) #Move the file
                            else: #if the file isn't in allowedExtensions, we can't move the file. Continue to the next loop iteration
                                continue
                        else: #if the folder is not in our specialFolders variable, just move the file without any further checks
                            moveFile(move_file_path, csv_writer)

def All_Other_Drives(): #Used for drives that aren't J K or S
    #for loop that goes through all files in the directory
    with open('\\\\file\\server\\Archiving\\ArchiveLogs\\{}-{}.csv'.format(driveLetter,current_date), mode='a', newline='', encoding='utf-8') as csv_file: #open or create the CSV log file. {} inserts the variables listed after .format
        csv_writer = csv.writer(csv_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        for somefile in base.walkfiles():
            file_extension = os.path.splitext(somefile)[1] #gets the file extension. This is used later to check if the file type is in the whitelist
                    
            if somefile.mtime < num_days_ago: #somefile.mtime is the last time the file was modified. This is compared with num_days_ago to see if the file should be moved
            #if somefile.atime < num_days_ago: #somefile.atime gets the last time the file was accessed. This is compared with num_days_ago to see if the file should be moved
                
                move_file_path = Path.realpath(somefile) #get file path of the file to move
                #file_size = somefile.getsize() #get the file size
                
                if file_extension not in fileType_whitelist: #check if the file type is whitelisted
                    #breakpoint()
                    whitelist_check = any(substring in Path.dirname(somefile).lower() for substring in filePath_whitelist) #check if any elements in the white list are substrings of our current file path. If so, this path is whitelisted and nothing should be archived. This returns either True or False into whitelist_check
                    if not whitelist_check: #if whitelist_check is False, the below code is executed
                        moveFile(move_file_path, csv_writer)


#Function that takes a file path and our csv as an input. It then moves the file to Warm storage
def moveFile(move_file_path, csv_writer):
    try: #try-catch block for copying the file
        destination_file_path = move_file_path
        destination_file_path = destination_file_path.replace('fileserver', 'fileserver\\archive') #replace fileserver with fileserver\Archive
        move(move_file_path, destination_file_path) #move the file to the destination
        #print(destination_file_path) #can be enabled for debugging/testing. Outputs the files original (current) location
        csv_writer.writerow([move_file_path]) #write file name to CSV
        #print(move_file_path) #Outputs the files new (moved) location to console
                                
    except IOError as e:
        print(e)
        
"""
END OF FUNCTIONS
"""


"""
MAIN PROGRAM EXECUTION
"""

#Used to check if the given drive letter is J K or S
JKS_List = ['j-drive', 'k-drive', 's-drive']
if driveLetter.lower() in JKS_List: #Check if drive letter is J K or S, and then call the appropiate function
    J_K_S_Drives()
else:
    All_Other_Drives()


