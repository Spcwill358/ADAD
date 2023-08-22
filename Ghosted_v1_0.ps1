#Check to see if user asked for help
if ($args[0] -eq 'help' -or $args.Count -ne 1) {
    #Print help information
    $help = @"

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                                                                               +
+---------------------- Ghosted AD User Finder v1.0 Help -----------------------+
+                                                                               +
+++++++++++++++++++++++++++++++++++++[usage]+++++++++++++++++++++++++++++++++++++
+                                                                               +
+ Checks for users in your Active Directory you've never logged in and          +
+ creates a report in a table format which can be saved in a .csv file, and     +
+ can automate the process of disabling those accounts.                         +
+                                                                               +
+ .\Ghosted_v1_0.ps1 <Action>                                                   +
+                                                                               +
+ <Action> = { help, report, export, disable }                                  +
+                                                                               +
+                                    [example]                                  +
+                                                                               +
+ .\Ghosted_v1_0.ps1 export                                                     +
+       This would create a .csv file with a log of all accounts that have      +
+       never logged into their accounts.                                       +
+                                                                               +
+++++++++++++++++++++++++++++++++++++[report]++++++++++++++++++++++++++++++++++++
+                                                                               +
+ This option creates a simple report but does not redirect the output into a   +
+ file. Use the report option when you want to run a simple search.             +
+                                                                               +
+                                [example output]                               +
+                                                                               +
+ Name,                 SamAccountName                                          +
+ --------------------- ---------------------                                   +
+ John Doe              jdoe                                                    +
+ Roboute Guilliman     rguilliman                                              +
+ Monkey D. Luffy       mluffy                                                  +
+                                                                               +
+++++++++++++++++++++++++++++++++++++[export]++++++++++++++++++++++++++++++++++++
+                                                                               +
+ The export option also creates a report and prompts the user to create a name +
+ of a file that the report will be redirected into. The format will be a .csv  +
+ file. Use this option if you are looking to create a log, but do not want to  +
+ disable any of the accounts.                                                  +
+                                                                               +
+++++++++++++++++++++++++++++++++++++[disable]+++++++++++++++++++++++++++++++++++
+                                                                               +
+ Disable option does both an export of the report and then disables all of the +
+ accounts that Ghosted finds. Use this option to automate the disabling of     +
+ accounts that have never been logged into before.                             +
+                                                                               +
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"@

    Write-Output $help
    exit
}

else {
    #Sets the paramaters of the script based on the user input
    $Action = $args[0].ToLower()

    if (-not (($Action -eq 'report') -or ($Action -eq 'export') -or ($Action -eq 'disable'))) {
        #ERROR: Not a valid action
        Write-Error ($Action + ' is not a valid action. If you need help try .\Ghosted_v1_0.ps1 help')
        exit
    }
}

#Creates the ASCII art title and displays it
$title = @"

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                                                                               +
+                      _____ _               _           _                      +
+                     / ____| |             | |         | |                     +
+                    | |  __| |__   ___  ___| |_ ___  __| |                     +
+                    | | |_ | '_ \ / _ \/ __| __/ _ \/ _` |                     +
+                    | |__| | | | | (_) \__ \ ||  __/ (_| |                     +
+                     \_____|_| |_|\___/|___/\__\___|\__,_|                     +
+                                                                               +
+-------------------------------------------------------------------------------+			
+---------------------     Ghosted AD User Finder v1.0     ---------------------+			
+-------------------------------------------------------------------------------+		      
+-------------------------------------------------------------------------------+
+---------------------    Created by: Michael Williams     ---------------------+
+---------------------        @ Divergence Academy       -----------------------+
+-------------------------------------------------------------------------------+
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"@
Write-Output $title

#Function to gather all users from the AD who've never logged in before
function Get-Report {
    Get-ADUser -Filter { (LastLogonTimeStamp -notlike "*") -and (enabled -eq $True) } -Properties * | Select-Object Name, SamAccountName 
}

function Get-Export {
    Write-Output ('NOTE: You do not need to add the .csv extention. This is done for you.')
    $global:Export = Read-Host ('What would you like to call the .csv export file?')
    Get-Report | Export-Csv -Path ~\$global:Export.csv -NoTypeInformation
}

#Creates a 1.5 second delay before displaying the next output text
Start-Sleep -Milliseconds 1500


if ($Action -eq 'report') {
    Write-Output ("Gathering your report of user who've never activated their account.")
    Write-Output ('One moment please.')
    Write-Output (' ')
    Start-Sleep -Milliseconds 500
    Get-Report
}
elseif ($Action -eq 'export') {
    Get-Export
}
else {
    Get-Export
    $Path = '~\' + $global:Export + '.csv'
    $ADUsers = Import-Csv -Path $Path
    foreach ($User in $ADUsers) {
        $Name = $User.SAMAccountName
        Disable-ADAccount -Identity "$Name"
    }
}