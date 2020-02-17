<#
Author: Shea Bryarly
Date: 2020-02-17
Description: This script updates the Managed User (SW) custom field in CW Manage Contacts.
It queries the labtech database to determine which users are in the Managed Users OU to make the determination.
#>

[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [String]$cwmlib
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


$Auth = Get-CWMAuth -ErrorAction Stop
$QueryResults = $NULL
$RemoveContactFlag = $NULL
$i = 0
$PageSize = 200
$Page = 1
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
    Write-Host "QueryResults.Count contact(s) found in query." 
} Else {
    Write-Host "Query found no contacts to update. Exiting script."
    Exit  
}

ForEach ($c IN $QueryResults.Contact_ExternalID) {
    Try {
        Set-ContactCustomField -ContactID $c -ID 7 -Caption "Managed User (SW)" -Type "Checkbox" -Value $True
    } Catch {
        Write-Host "Could not update contact $c. $_"
    }
}

While (($i -ne 0) -OR ($i.count -ne 0)) {
   
    $AddURI = "company/contacts?pagesize=$PageSize&Page=$Page&customFieldConditions=caption='Managed User (SW)' AND Value = True"
    $FullURI = $Auth.BaseURI + $AddURI
    
    Try {
        $i = Invoke-RestMethod -Uri $FullURI -Method Get -Headers $Auth.Header -ErrorAction Stop
    } Catch {
        Throw $_
    }

    $Page++

    If ($i.Count) {
        $RemoveContactFlag += $i
    }

}

ForEach ($c IN $RemoveContactFlag.id) {
    If ($c -NOTIN $QueryResults.Contact_ExternalID) {
        Try {
            Set-ContactCustomField -ContactID $c -ID 7 -Caption "Managed User (SW)" -Type "Checkbox" -Value $False -ErrorAction Stop
        } Catch {
            Write-Host "Could not update contact $c. $_"
        }
    }
}

Write-Host "Contacts have been updated."