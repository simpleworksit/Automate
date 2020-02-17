<#
Author: Shea Bryarly
Date: 2020-02-17
Description: This script updates the Managed User (SW) custom field in CW Manage Contacts.
It queries the labtech database to determine which users are in the Managed Users OU to make the determination.
#>

[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$cwmlib,
            [Parameter(Mandatory=$true)]
            [String]$PublicKey,
            [Parameter(Mandatory=$true)]
            [String]$PrivateKey,
            [Parameter(Mandatory=$true)]
            [String]$ClientID
        )

If (Test-Path $cwmlib) {
    . $cwmlib
} Else {
    Write-Host "Can't find cwmlib. Exiting Script"
    Exit
}

If (Get-Module -ListAvailable -Name SimplySQL) {
    Try {
        Import-Module SimplySQL -ErrorAction Stop
    } Catch {
        Throw $_
    }

} Else {
    Try {
        Install-Module -Name SimplySQL -ErrorAction Stop
        Import-Module SimplySQL -ErrorAction Stop
    } Catch {
        Throw $_
    }
}

$QueryResults = $NULL
$RemoveContactFlag = $NULL
$j = 0

$Auth = Get-CWMAuth -PublicKey $PublicKey -PrivateKey $PrivateKey -ClientID $ClientID -ErrorAction Stop
$DBPW = ConvertTo-SecureString 'QOxgJAm3kSChqw_9' -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential (“swautomate”, $DBPW)
$CWAutomateUsersQuery = 
    "
    SELECT
	    cont.ContactID
	    ,cont.ExternalID AS 'Contact_ExternalID'
	    ,IFNULL(usr.Firstname, '') AS 'FirstName'
	    ,IFNULL(usr.Lastname, '') AS 'LastName'
	    ,cli.Name AS 'Company'
            ,cli.clientid
            ,cli.ExternalID AS 'Company_ExternalID'

    FROM
	    Contacts AS cont
	    JOIN plugin_ad_users AS usr
		    ON cont.ContactID = usr.ContactID
	    JOIN Clients AS cli
		    ON cont.ClientID = cli.ClientID
	    JOIN plugin_ad_entries AS ent
		    ON usr.objectGUID = ent.ObjectGUID

    WHERE
	    ent.DistinguishedName LIKE '%OU=Managed Users%'
	    AND cont.ExternalID <> 0

    ORDER BY
	    cli.clientid
        ,cont.contactid
    "

Try {
    $DBSession = Open-MySqlConnection -ConnectionName "PSConnection" -Server "SVR-SW-LT01" -Database "labtech" -Credential $Credentials
} Catch {
    Write-Host "Could not connect to database. $_"
    Exit
}

Try {
    $QueryResults = Invoke-SqlQuery -ConnectionName "PSConnection" -Query $CWAutomateUsersQuery
} Catch {
    Write-Host "Could not query database. $_"
    Exit
}

If ($QueryResults.Count) {
    Write-Host "Query has found contacts."
} Else {
    Write-Host "Query found no contacts to update. Exiting script."
    Exit  
}

ForEach ($c IN $QueryResults.Contact_ExternalID) {
    Try {
        Set-ContactCustomField -Auth $Auth -ContactID $c -ID 7 -Caption "Managed User (SW)" -Type "Checkbox" -Value $True
    } Catch {
        Write-Host "Could not update contact $c. $_"
    }
}

Write-Host "$($QueryResults.Contact_ExternalID.Count) contact(s) have had the Managed User (SW) custom field checked."

$RemoveContactFlags = Get-ContactCustomFields -Auth $Auth -Caption "Managed User (SW)" -Value $True -PageSize 200

ForEach ($c IN $RemoveContactFlags.id) {
    If ($c -NOTIN $QueryResults.Contact_ExternalID) {
                
        Try {
            Set-ContactCustomField -Auth $Auth -ContactID $c -ID 7 -Caption "Managed User (SW)" -Type "Checkbox" -Value $False -ErrorAction Stop
        } Catch {
            Write-Host "Could not update contact $c. $_"
        }
        
        $j++
    }
}

If ($j) {
    Write-Host "$j contact(s) have had the Managed User (SW) custom field unchecked."
}

Write-Host "Script has completed."