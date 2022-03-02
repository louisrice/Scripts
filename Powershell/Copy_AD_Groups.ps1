#This script adds a specified user to all AD groups that another specified user is a member of.
$newuser = Read-Host -Prompt "Please enter the username of the user you would like to add the groups to"
$likeUser = Read-Host -Prompt "Please enter the username of a similar user"

#get the groups of the like user
$groups = Get-ADPrincipalGroupMembership $likeuser | select name
$groupnames = $groups.name

foreach($group in $groupnames){
    if($group -notcontains "*All MediaLab" -And $group -notcontains "Domain Users"){
    #Try{Add-ADGroupMember -Identity $group -Members $newuser}
    Try{Add-ADPrincipalGroupMembership -Identity $newuser -MemberOf $group}
    Catch{"Could not add $newuser to $group"}
    }
}