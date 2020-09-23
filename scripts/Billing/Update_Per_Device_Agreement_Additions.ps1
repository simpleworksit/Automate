<#
Author: Shea Bryarly
Date: 2020-09-23
Description: This script updates agreement addition line items in CW Manage. It makes a query to the Automate database for the values.
The query only pulls data for customers that have the "API (SW)" Managed Service template in the CW Automate plugin.

Parameters:
$cwmlib: The CW Manage Library file path
$PublicKey: The API Public Key
$PrivateKey: The API Private Key
$ClientID: The API Client ID provided by the CW developer network.
$ServiceDefinitionID: This can be one of three different values and corresponds to what product you are trying to update.

The values can be:
    5 - Contract Workstation Counts and AV Counts. 
    6 - Contract Physical Server Counts.
    9 - Contact SRVR Virtual Counts.

Example:
[script path] -cwmlib 'C:\LTShare\Transfer\swgit\Automate\lib\cwmlib.ps1' -PublicKey [Your Key here] -PrivateKey [Your Key Here]  -ClientID [Your ID here]  -ServiceDefinitionID 5

This command will update the AGR:CONTRACT-WKSTN counts for the companies that have the line item under a Managed Workstation agreement.

Output:

Does not return any values. Just a description of what it did. See below:
-------------------------------------------------------------------------------
Workstation count query has found records.
Looping through company agreements.

Checking Campbell Homes.
Setting AGR:CONTRACT-SRVR-PHYSICAL agreement addition line item from 2.00 to 1.

The script has completed.
-------------------------------------------------------------------------------
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
            [String]$ClientID,
            [Parameter(Mandatory=$true)]
            [INT]$ServiceDefinitionID
        )

$ProductParams = @(0,0,"") #The first element is agreement type ID. The second element is product ID. The third element is the name.

Switch ($ServiceDefinitionID) {
    5 {$ProductParams[0] = 18; $ProductParams[1] = 752; $ProductParams[2] = "AGR:CONTRACT-WKSTN"}
    6 {$ProductParams[0] = 12; $ProductParams[1] = 751; $ProductParams[2] = "AGR:CONTRACT-SRVR-PHYSICAL"}
    9 {$ProductParams[0] = 12; $ProductParams[1] = 2519; $ProductParams[2] = "AGR:CONTRACT-SRVR-VIRTUAL"}
    Default {
        Write-Host "There is no matching managed service definition. Exiting script."
        Exit
    }
}

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

$Auth = Get-CWMAuth -PublicKey $PublicKey -PrivateKey $PrivateKey -ClientID $ClientID -ErrorAction Stop
$DBPW = ConvertTo-SecureString 'QOxgJAm3kSChqw_9' -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential (“swautomate”, $DBPW)

$AutomateWSCountsQuery = 
    "
       SELECT
	    cwm.CWCompanyRecID
	    ,cwm.CWCompanyName
	    ,wsc.WS_Count

    FROM
	    `plugin_cw_clientmapping` AS cwm
	    JOIN (
		    SELECT
			    cli.clientid
			    ,COUNT(ComputerID) WS_Count
		    FROM
			    clients AS cli
			    JOIN v_mngd_svc_computers AS svc
				    ON cli.clientid = svc.clientid
		    WHERE
			    ServiceDefinitionID = $ServiceDefinitionID
				
		    GROUP BY
			    ClientID	
	    ) AS wsc
	    ON cwm.ClientID = wsc.ClientID

    WHERE
	    ManagedServiceTemplateID = 5
    "

Try {
    $DBSession = Open-MySqlConnection -ConnectionName "PSConnection" -Server "SVR-SW-LT01" -Database "labtech" -Credential $Credentials
} Catch {
    Throw $_
}

Try {
    $QueryResults = Invoke-SqlQuery -ConnectionName "PSConnection" -Query $AutomateWSCountsQuery
} Catch {
    Throw $_
}

If ($QueryResults) {
    Write-Host "Workstation count query has found records."
} Else {
    Write-Host "There was no data in the query results."
   Throw $_
}

Write-Host "Looping through company agreements."

ForEach ($comp In $QueryResults) {
    
    Write-Host "`nChecking $($comp.CWCompanyName)"

    Try {
        $wsagr = Get-Agreements -Auth $Auth -PageSize 200 -Conditions "agreementStatus='Active' AND type/id=$($ProductParams[0]) AND company/id=$($comp.CWCompanyRecID)"
    } Catch {
        Throw $_
    }

    #Getting device type agreement additions.
    If ($wsagr.Count) {
        Write-Host "Found more than one active agreement for agreement type $($ProductParams[0])."
    } ElseIf ($wsagr) {
        ForEach ($wsid In $wsagr.ID) {
            Try {
                $addition = Get-AgreementAdditions -Auth $Auth -PageSize 200 -AgreementID $wsid -Conditions "agreementStatus='Active' AND product/id=$($ProductParams[1])"
            } Catch {
                Throw $_
            }

            If ($ServiceDefinitionID -eq 5) {
                Try {
                    $AVAddition = Get-AgreementAdditions -Auth $Auth -PageSize 200 -AgreementID $wsid -Conditions "agreementStatus='Active' AND product/id=2368" #Addition ID is hardcoded for AV.
                } Catch {
                    Throw $_
                }
            } Else {
                #Should never get here
            }
        }

        #Check to see if there is only one line item on the agreement for device type. If so, update the line item if the count is not equal to Automate device type count.
        If ($addition.Count) {
            Write-Host "Found more than one active $($ProductParams[2]) agreement addition."
        } ElseIf ($addition) {
            If ($comp.WS_Count -ne $addition.quantity) {
                Write-Host "Setting $($ProductParams[2]) agreement addition line item from $($addition.quantity) to $($comp.WS_Count)."
                Try {
                    Set-AgreementAdditionQuantity -Auth $Auth -AgreementID $addition.agreementid -AdditionID $addition.id -Quantity $comp.WS_Count | Out-Null
                } Catch {
                    Throw $_
                }
            } Else {
                Write-Host "$($ProductParams[2]) quantity is already correct."
            }
        } Else {
            Write-Host "There are no $($ProductParams[2]) line items found."
        }

        #Check to see if there is only one line item on the agreement for AntiVirus. If so, update the line item if the count is not equal to Automate workstation counts.
        If ($ServiceDefinitionID -eq 5) {
            If ($AVAddition.Count) {
                Write-Host "Found more than one Antivirus agreement addition."
            } ElseIf ($AVAddition) {
                If ($comp.WS_Count -ne $AVAddition.quantity) {
                    Write-Host "Setting AntiVirus agreement addition line item from $($AVAddition.quantity) to $($comp.WS_Count)."
                    Try {
                        Set-AgreementAdditionQuantity -Auth $Auth -AgreementID $AVAddition.agreementid -AdditionID $AVAddition.id -Quantity $comp.WS_Count | Out-Null
                    } Catch {
                        Throw $_
                    }
                } Else {
                    Write-Host "AntiVirus quantity is already correct."
                }
            } Else {
                Write-Host "There are no AntiVirus line items found."
            }
        }
    } Else {
        Write-Host "There are no agreements found for agreement type $($ProductParams[0])."
    }
}

Write-Host "`nThe script has completed."