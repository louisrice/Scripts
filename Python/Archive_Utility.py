#This script can be used to search through archive logs to locate a file.
#It is designed to be built into a .EXE using Pyinstaller and then distributed to end users. 

from tkinter import *
from pywinauto.application import Application
from pywinauto.keyboard import send_keys
from os import path
from shutil import move
from tkinter.ttk import Progressbar
from threading import Thread
import tkinter as tk
import tkinter.messagebox
import tkinter.scrolledtext as tkscrolled
import glob, path, csv, pdb, pyperclip, os, time, os.path, sys, threading, multiprocessing, time

global searchFinished
searchFinished = False

VERSION = 'Version 1.1'

window = tk.Tk()
window.title('Archived File Utility')

#Set the icon in taskbar to a Magnifying Glass
try:
    window.iconbitmap('\\\\\file\\server\\Archived File Finder\\z_icon.ico')
except: #if the file can't be loaded, we assume the user isn't on the VPN
    tk.messagebox.showinfo("ERROR",  "You must be connected to the VPN for this program to work.")
    window.destroy()
    sys.exit()

#Check if the currently running version is outdated. If so, tell the user and offer to open File Explorer to the folder containing the new version
fileObject = open("\\\\file\\server\\Archived File Finder\\Latest_Version.txt", "r")
latestVersion = fileObject.read()
if (latestVersion != VERSION):
    result = tk.messagebox.askquestion("Update available!", "A new version of this program is available! Would you like to open File Explorer to the folder with the new .EXE? If you select Yes, please copy the .EXE to your computer and overwrite the current one. ")
    if result == 'yes': #if the user clicked Yes on the pop up
        os.startfile('\\\\file\\server\\Archived File Finder') #Open file explorer to the specified folder

#Loop that creates our rows and columns. Change the number in range() to change the number of columns, which will change the window size
for i in range(18):
    for j in range(18):
        frame = tk.Frame(master=window,relief=tk.RAISED,borderwidth=1)
    frame.grid(row=i, column=j, padx=10, pady=10)
    window.columnconfigure(i, weight=1, minsize=40) #Controls how long the row is
    window.rowconfigure(i, weight=1, minsize=40)#Controls how tall each row is


#List containing the options for our drive letter dropdown box
DRIVELETTERS = [
"All drives", "A", "FTP", "I", "J", "K", "L", "P-Drive2", "R", "S", "U", "V"
]


#Function that runs when the user right clicks the file name entry box and selects Paste
def paste():
    fileNameEntryBox.insert(tk.END, pyperclip.paste())

#Creates drive letter dropdown list for the user to select what drive to search
driveList = StringVar(window) #used below to change what the default value of the drop down list is
driveList.set(DRIVELETTERS[0]) #sets the default value of our dropdown list to the first item in our list (All drives)
driveOptionMenu = OptionMenu(window, driveList, *DRIVELETTERS) #creates the OptionMenu object
driveOptionMenu.grid(row=1, column=8, sticky="n") #Places the drop down menu on the UI

#Creates the text line about contacting us for help and what version the program is
helpTextContents = 'Email ticket@contoso.com for help. {}'.format(VERSION)
helpText = tk.Label(window, text=helpTextContents)
helpText.config(font=('helvetica', 9))
helpText.grid(row=18, column=8, columnspan=2)

#Creates the text line asking for the user to select a drive
driveText = tk.Label(window, text='Select the drive to search')
driveText.config(font=('helvetica', 10))
driveText.grid(row=0, column=8, sticky="n")

#Creates the text line asking for file name
fileNameText = tk.Label(window, text='Enter the file name')
fileNameText.config(font=('helvetica', 10))
fileNameText.grid(row=0, column=9, sticky="n")

#Creates the entry box for inputting file name
global fileNameEntryBox
fileNameEntryBox = tk.Entry(window, width=40) 
fileNameEntryBox.grid(row=1, column=9, sticky="n")

#Creates the right click menu with "Paste" as an option
rightClickMenu = Menu(window, tearoff = 0)
#rightClickMenu.add_command(label = "Cut", command=cut)
#ightClickMenu.add_command(label = "Copy", command=copy)
rightClickMenu.add_command(label = "Paste", command=paste)




#Creates the right click pop up menu (containing Paste) when the user right clicks in the File name entry box
def do_popup(event):
    try:
        rightClickMenu.tk_popup(event.x_root, event.y_root)
    finally:
        rightClickMenu.grab_release()

fileNameEntryBox.bind("<Button-3>", do_popup) #This line has to be located after def do_popup(event) to work

#Runs when the user clicks Locate Files
def createProgressBarAndSearchForFiles():
    all_processes = [] #Used to later store all the running procsses
    progressThread = Thread(target = progressBar).start() #Start a thread to run our progress bar
    searchThread = Thread(target = searchForFile).start() #Start a thread to search for the file

#Progress bar that runs while the logs are beiing searched
def progressBar():
    global searchFinished
    toplevel = Toplevel(window)
    progressbar = Progressbar(toplevel, orient = HORIZONTAL, mode = 'indeterminate') #Indeterminate means the bar doesn't show the real progress, it just bounces back and forth endlessly
    label = Label(toplevel, text="Searching, please wait. . .", font=('helvetica', 9, 'bold'))
    label.place(x=75,y=0)
    progressbar.pack(side="bottom", fill="x")
    toplevel.wm_geometry("300x50")
    progressbar.start()
    for i in range(500): #Every 1 second for 500 seconds, the loop checks if searchFinished is equal to True. When it is, it kills the progress bar window
        #breakpoint()
        if searchFinished == True:
            toplevel.destroy()
            break
        else: #If searchFinished is currently equal to False, we wait 1 second and then check again
            time.sleep(1)

#Function for when the "Open selected results in file explorer" button is clicked
def openInFileExplorer ():
    if mylistbox.curselection() == (): #If the user hasn't selected anything
        tk.messagebox.showinfo("ERROR",  "Please select at least 1 result to open in File Explorer")
        return #Exit this function early
    
    #initialize variables for letter use
    locations_string = "" #this will store all of the selected locations as 1 big string with \n between locations
    path_and_file_list = [] #used to store the data from locations_string as a list
    path_list = [] #used to store just the folder path, after removing the file name and extension
    deduped_list = [] #used to store our deduped list of selected folders

    
    for selection in mylistbox.curselection(): #gets all selected locations and adds them to the values string seperated by \n
        locations_string += mylistbox.get(selection)
        locations_string += "\n"

    #seperates our locations_string into a list. Splitlines() splits on the \n    
    path_and_file_list = locations_string.splitlines() 
    for location in path_and_file_list: #loop through all elements in list
        path, file = os.path.split(location) #split the file location into folder path and file name
        path_list.append(path) #append the folder path into path_list

    #Used to eliminate duplicate folder paths from being opened    
    for path in path_list:
        if path not in deduped_list:
            deduped_list.append(path)

    #Open all the unique folder paths
    for path in deduped_list:
        os.startfile(path)

#Function for when the "Open selected results in notepad" button is clicked
def openInNotepad ():
    
    if mylistbox.curselection() == ():
        tk.messagebox.showinfo("ERROR",  "Please select at least 1 result to open in Notepad")
        return
    
    values = ""
    
    for selection in mylistbox.curselection(): #gets all selected locations and adds them to the values string
        values += mylistbox.get(selection)
        values += "\n"
    pyperclip.copy(values) #copy the file locations into the clipboard https://pypi.org/project/pyperclip/
    app = Application(backend="uia").start("notepad.exe") #start notepad
    send_keys('^v') #Simulates the user pressing Ctrl and V (paste) keys to paste the file locations into the notepad window we opened


#Function that runs when the "Find files" button is clicked
def searchForFile ():
    #clears the file results from the previous search, so we don't have overlapping text
    global searchFinished
    searchFinished = False #Used by our progress bar to know when to close
    
    for label in window.grid_slaves(column=1): #only our search results are in column 1, so clearing all of column 1 just clears our results
        label.grid_forget()
    driveLetter = driveList.get() #get the selected drive letter from the drop down options
    desiredFile = fileNameEntryBox.get().lower() #convert the file name to all lowercase

    #If the user didn't input any text
    if (desiredFile == ''):
        tk.messagebox.showinfo("ERROR",  "Please enter a file name before clicking Locate Files")
        return #Exits function early

    #Check what drive should be searched and set what CSV files we search accordingly
    if driveLetter == 'All drives':
        path = r'\\file\server\archiving\archivelogs\*.csv'.format(driveLetter)
    elif driveLetter == 'P-Drive2':
        path = r'\\file\server\archiving\archivelogs\P_Drive2*'
    elif driveLetter == "FTP":
        path = r'\\file\server\archiving\archivelogs\FTP*'
    else:
        path = r'\\file\server\archiving\archivelogs\{}_Drive*'.format(driveLetter)

        
    row_string = ""
    global locations_string
    global mylistbox
    locations_string = ""
    location_array = []
    for filename in glob.glob(path):
        csv_file = csv.reader(open(filename, "r", encoding='utf-8'))
        for row in csv_file:
            row_string = row_string.join(row)
            row_string = row_string.lower()
            #print(row_string)
            if (desiredFile in row_string):
                #print('File found')
                #print(row_string)
                #breakpoint()
                location_array.append(row_string)
                row_string = row_string + "\n"
                locations_string = locations_string + row_string
                
    #Displays the results in a Listbox
    mylistbox = Listbox(window, selectmode=EXTENDED, width=165, height=30)
    for items in location_array: #For each file in location_array, insert it into the Listbox
        mylistbox.insert(END,items)
    mylistbox.grid(row=3, column=0, columnspan=22, rowspan=10)
        

    #Create button to open results in File Explorer
    openFileExplorerButton = tk.Button(text='Open selected results in File Explorer', command=openInFileExplorer, bg='brown', fg='white', font=('helvetica', 9, 'bold'))
    openFileExplorerButton.grid(row=1, column=4, sticky="nwe")

    #Create button to open results in Notepad
    openResultsNotepad = tk.Button(text='Open selected results in Notepad', command=openInNotepad, bg='brown', fg='white', font=('helvetica', 9, 'bold'))
    openResultsNotepad.grid(row=2, column=4, sticky="nwe")

    #Create button to unarchive selected files
    unArchiveButton = tk.Button(text='Unarchive selected results', command=unArchive, bg='brown', fg='white', font=('helvetica', 9, 'bold'))
    unArchiveButton.grid(row=2, column=13, sticky="nwe")

    searchFinished = True #Setting this to True triggers code in the function progressBar() that kills the window containing the progress bar
### END OF searchForFile() ###


#Function for when the "Unarchive selected results" button is clicked
def unArchive ():
    filesMoved = "FILES MOVED:\n"
    filesAlreadyInHot = "FILES THAT ARE ALREADY ON A NETWORK DRIVE:\n"
    filesNotFound = "FILES NOT FOUND IN ANY LOCATION:\n"
    popUpMessage = ""
    locations_string = ""

    if mylistbox.curselection() == ():
        tk.messagebox.showinfo("ERROR",  "Please select at least 1 file to unarchive")
        return
    
    for selection in mylistbox.curselection(): #gets all selected locations and adds them to the values string seperated by \n
        locations_string += mylistbox.get(selection)
        locations_string += "\n"
    #seperates our locations_string into a list. Splitlines() splits on the \n    
    path_and_file_list = locations_string.splitlines()

    #Loop through all selected files
    for file in path_and_file_list:
        isFileInHot = os.path.exists(file) #check if the file is on the network drive
        if isFileInHot:
            print("File is on a network drive already")
            filesAlreadyInHot += file
            filesAlreadyInHot += "\n"
            
        else: #Replace server name in the file path
            warmLocation = file.replace('file_server', 'contoso.local\\warm')
            warmLocation = file.replace('ftp_server', 'contoso.local\\warm')
            isFileInWarm = os.path.exists(warmLocation) #check if the file is in Warm
            if (isFileInWarm == True):
                try:
                    move(warmLocation, file) #move the file from Warm to the original location (on a network drive)
                    filesMoved += file
                    filesMoved += "\n"
                except Exception as e:
                    tk.messagebox.showinfo("ERROR1",  "ERROR while trying to move a file. Please email ticket@contoso.com with a screenshot of this window.\n\nFile:{}\n\nError:{}".format(file,e))
            else:
                coldLocation = file.replace('contoso.local\\warm', 'contoso.local\\cold')
                coldLocation = file.replace('FTP_server', 'contoso.local\\cold')
                isFileInCold = os.path.exists(coldLocation) #Check if the file is in Cold
                if isFileInCold:
                    try:
                        move(coldLocation, file) #move the file from Cold to the original location (on a network drive)
                        filesMoved += file
                        filesMoved += "\n"
                    except Exception as e:
                        tk.messagebox.showinfo("ERROR2",  "ERROR while trying to move a file. Please email ticket@contoso.com with a screenshot of this window.\n\nFile:{}\n\nError:{}".format(file,e))
                else:
                    print("Unable to locate file anywhere")
                    filesNotFound += file

    if (filesNotFound == "FILES NOT FOUND IN ANY LOCATION:\n"):
        filesNotFound = ""

    if (filesAlreadyInHot == "FILES THAT ARE ALREADY ON A NETWORK DRIVE:\n"):
        filesAlreadyInHot = ""
    if (filesMoved == "FILES MOVED:\n"):
        filesMoved = ""
        
    #Adds all of our result strings together into 1 big string, then displays it in a pop up window    
    popUpMessage = popUpMessage + filesMoved + "\n" + filesAlreadyInHot + "\n" + filesNotFound
    if (popUpMessage == "\n\n"):
        pass
    else:
        tk.messagebox.showinfo("Unarchive Results",  popUpMessage)


#Creates the button labeled "Locate files"
locateFileButton = tk.Button(text='Locate files', command=createProgressBarAndSearchForFiles, bg='brown', fg='white', font=('helvetica', 9, 'bold'))
locateFileButton.grid(row=2, column=8, columnspan=2, sticky="nwe")    

window.mainloop()
