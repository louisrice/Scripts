#Used to create a user account for Adobe and assign them a license
#Possible thanks to https://github.com/adobe-apiplatform/umapi-client.py
#Documentation: https://adobe-apiplatform.github.io/umapi-client.py/
#Confluence page: <redacted link>
import yaml,umapi_client
from umapi_client import IdentityTypes,UserAction


#Open the config.yaml file. \\ is needed because \ is an escape character in python. 1 \ would cause a syntax error
with open('\\\\file\\server\\Python\\Create Adobe account\\config.yaml', "r") as f:
    config = yaml.load(f, Loader=yaml.FullLoader)

#Connect to adobe servers using authentication info from the config.yaml file
conn = umapi_client.Connection(org_id=config["org_id"],auth_dict=config)

emailAddress = input("Please enter the user's email address:\n")
firstName = input("Please enter the user's First name:\n")
lastName = input("Please enter the user's Last name:\n")

user = UserAction(id_type=IdentityTypes.adobeID, email=emailAddress)
user.create(first_name=firstName, last_name=lastName, country="US")

allApps = input("Does the user need access to all Creative Cloud apps? [Y\\N]:\n").lower()

#if all creative cloud apps are needed, add to dummy group and CCLE group that grants CC all apps license
if allApps == "y":
    user.add_to_groups(groups=["Dummy_group", "CCLE Configuration"])
else: #check if Photoshop and Acrobat are needed
    Photoshop = input("Does the user need Photoshop? [Y\\N]:\n").lower()
    Acrobat = input("Does the user need Acrobat? [Y\\N]:\n").lower()
    if Photoshop == "y": #check if both photoshop and acrobat are needed
        if Acrobat == "y":
            user.add_to_groups(groups=["APAP-INDIRECT-ML Configuration", "PHSP-INDIRECT-ML Configuration"])
        else: #if just photoshop is needed
            user.add_to_groups(groups=["Dummy_group", "PHSP-INDIRECT-ML Configuration"])
            
            
    else: #if just acrobat is needed
        user.add_to_groups(groups=["Dummy_group", "APAP-INDIRECT-ML Configuration"])
        

#Send the commands to create the user
result = conn.execute_single(user, immediate=True)

print("~~~\nAccount should be created, please verify in admin console\n~~~")
