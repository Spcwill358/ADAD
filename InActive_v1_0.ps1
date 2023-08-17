#Check to see if user asked for help
if ($args[0] -eq 'help' -or $args.Count -ne 2) {
    #Print help information
    $help = @"

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                                                                               +
+---------------------- Inactive AD User Finder v1.0 Help ----------------------+
+                                                                               +
+++++++++++++++++++++++++++++++++++++[usage]+++++++++++++++++++++++++++++++++++++
+                                                                               +
+ Checks the Last Login of the users in your Active Directory, creates a report +
+ in a table format which is saved in a .csv file, and can automate the process +
+ of disabling those accounts.                                                  +
+                                                                               +
+ .\InActive_v1_0.ps1 <Action> <Days>                                           +
+                                                                               +
+ <Action> = { help, report, export, disable }                                  +
+ <Days> = Specify a whole number from 1-365 to determine how far back the      +
+          the script should search for inactive accounts.                      +
+                                                                               +
+                                    [example]                                  +
+                                                                               +
+ .\InActive_v1_0.ps1 export 180                                                +
+       This would create a .csv file with a log of all account that have not   +
+       been active for at least 180 days.                                      +
+                                                                               +
+++++++++++++++++++++++++++++++++++++[report]++++++++++++++++++++++++++++++++++++
+                                                                               +
+ This option creates a simple report but does not redirect the output into a   +
+ file. Use the report option when you want to run a simple search.             +
+                                                                               +
+                                [example output]                               +
+                                                                               +
+ Name,                 SamAccountName,            LastLogonDate                +
+ --------------------- -------------------------- -----------------------------+
+ John Doe              jdoe                       08/10/2023 9:05:14 AM        +
+ Gideon Ravenor        gravenor                   04/17/2023 3:13:08 PM        +
+ Nefertari Vivi        nvivi                      02/02/2001 5:46:37 PM        +
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
+ accounts that InActive finds. Use this option to automate the disabling of    +
+ inactive accounts from a date of your choosing.                               +
+                                                                               +
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"@

    Write-Output $help
    exit
}

else {
    #Sets the paramaters of the script based on the user input
    $Action = $args[0].ToLower()
    [int]$Days = $args[1]

    if (-not (($Action -eq 'report') -or ($Action -eq 'export') -or ($Action -eq 'disable'))) {
        #ERROR: Not a valid action
        Write-Error ($Action + ' is not a valid action. If you need help try .\InActive_v1_0.ps1 help')
        exit
    }

    if (($Days -le 0) -or ($Days -ge 366)) {
        #ERROR: Not a valid value for days
        Write-Output ([string]$Days + ' is not a valid value for days. Specify a number from 1-365.')
        exit
    }
}

#Creates the ASCII art title and displays it
$title = @"

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
+                                                                               +
+                     ====                                                      +
+                      /   =  =  ===  === === === =   =  ===                    +
+                     /   /\ /  /--/ /    /   /    \ /  /--                     +
+                   ==== =  =  =  = ===  =  ===     =  ===                      +
+                                                                               +
+-------------------------------------------------------------------------------+			
+---------------------    Inactive AD User Finder v1.0     ---------------------+			
+-------------------------------------------------------------------------------+		      
+-------------------------------------------------------------------------------+
+---------------------    Created by: Michael Williams     ---------------------+
+---------------------        @ Divergence Academy       -----------------------+
+-------------------------------------------------------------------------------+
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

"@
Write-Output $title

#Function to gather all inactive user from a specified date
function Get-Report {
    Get-ADUser -Filter { LastLogonTimeStamp -lt $Time } -Properties * | Select-Object Name, SamAccountName, LastLogonDate
}

function Get-Export {
    Write-Output ('NOTE: You do not need to add the .csv extention. This is done for you.')
    $global:Export = Read-Host ('What would you like to call the .csv export file?')
    Get-Report | Export-Csv -Path ~\$global:Export.csv -NoTypeInformation
}

#Creates a 1.5 second delay before displaying the next output text
Start-Sleep -Milliseconds 1500

# Creates the the time to look back to based on subtracting the days entered from the current time of the machine
$Time = (Get-Date).Adddays( - ($Days))

#Displays your appropriately entered day value and states your intended action
Write-Output ('You entered ' + [string]$Days + ' days.')
Write-Output (' ')
Start-Sleep -Milliseconds 500

if ($Action -eq 'report') {
    Write-Output ('Gathering your report of inactive users dating back ' + $Days + ' days.')
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



