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
			    ServiceDefinitionID = 5
				
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
    
    Write-Host "Checking $($comp.CWCompanyName) agreement workstation counts."
    Try {
        $wsagr = Get-Agreements -Auth $Auth -PageSize 200 -Conditions "agreementStatus='Active' AND type/id=18 AND company/id=$($comp.CWCompanyRecID)"
    } Catch {
        Throw $_
    }

    If ($wsagr.Count) {
        Write-Host "Found more than one active workstation agreement."
    } ElseIf ($wsagr) {
        ForEach ($wsid In $wsagr.ID) {
            $addition = Get-AgreementAdditions -Auth $Auth -PageSize 200 -AgreementID $wsid -Conditions "agreementStatus='Active' AND product/id=752"
        }
        If ($addition.Count) {
            Write-Host "Found more than one active workstation agreement addition."
        } ElseIf ($addition) {
            If ($comp.WS_Count -ne $addition.quantity) {
                Write-Host "Setting workstation agreement addition line item from $($addition.quantity) to $($comp.WS_Count)."
                Try {
                    Set-AgreementAdditionQuantity -Auth $Auth -AgreementID $addition.agreementid -AdditionID $addition.id -Quantity $comp.WS_Count | Out-Null
                } Catch {
                    Throw $_
                }
            } Else {
                Write-Host "Quantity is already correct."
            }
        } Else {
            Write-Host "There are no workstation line items found."
        }
    } Else {
        Write-Host "There are no workstation agreements found."
    }
}

Write-Host "The script has completed."