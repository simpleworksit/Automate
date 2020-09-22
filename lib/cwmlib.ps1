<#
-----------------------------------------------------------------------------------------------------------------------------------------------
Getter Functions
-------------------------------------------------------------------------------------------------------------------------------------------------
#>

<#
Function Get-CWMAuth
Author: Shea Bryarly
Date: 2020-02-17
Description: Gets the basic variables for authentication for the other CWM functions to work. Returns an Auth Object.
#>
Function Get-CWMAuth() {
    [CmdletBinding()]
        Param(
        [Parameter(Mandatory=$true)]
            [STRING]$PublicKey,
        [Parameter(Mandatory=$true)]
            [STRING]$PrivateKey,
        [Parameter(Mandatory=$true)]
            [STRING]$ClientID
        )
    
    $RetVal = $Null
    $Authstring   = "SWCOS+$($PublicKey):$($PrivateKey)"
    $EncodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)))
    
    $RetVal = [PSCustomObject] @{

        BaseUri      = "https://cw.simpleworksit.com/v4_6_Release/apis/3.0/"
        Accept       = "application/vnd.connectwise.com+json; version=v2019_4"
        ContentType  = "application/json"
        Header       = @{
                            Authorization = ("Basic $encodedAuth")
                            ClientID = $ClientID
                        }
    }

    Return $RetVal
}

<#
Author: Shea Bryarly
Date: 2020-02-17
Description: Gets Contact Custom Fields.
#>

Function Get-ContactCustomFields() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            $Auth,
        [Parameter(Mandatory=$true)]
            [STRING]$Caption,
        [Parameter(Mandatory=$true)]
            $Value,
        [Parameter(Mandatory=$true)]
            [INT]$PageSize
    )

    $Page = 1
    $i = 0
    $RetVal = $NULL

    While (($i -ne 0) -OR ($i.count -ne 0)) {
   
            $AddURI = "company/contacts?pagesize=$PageSize&Page=$Page&customFieldConditions=caption='$($Caption)' AND Value = '$($Value)'"
            $FullURI = $Auth.BaseURI + $AddURI
    
            Try {
                $i = Invoke-RestMethod -Uri $FullURI -Method Get -Headers $Auth.Header -ErrorAction Stop
            } Catch {
                Throw $_
            }

            $Page++

            If ($i.Count) {
                $RetVal += $i
            }

        }

    Return $RetVal
}

<#
Author: Shea Bryarly
Date: 2020-09-22
Description: Gets agreement data.
Example of Conditions: "agreementStatus='Active' AND type/id=18"
#>
Function Get-Agreements() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            $Auth,
        [Parameter(Mandatory=$true)]
            [INT]$PageSize,
        [Parameter(Mandatory=$false)]
            [STRING]$Conditions
    )

    $Page = 1
    $i = 0
    $RetVal = $NULL

    While (($i -ne 0) -OR ($i.count -ne 0)) {
 
            If ($Conditions) {
                $AddURI = "finance/agreements?pagesize=$PageSize&page=$Page&Conditions=$Conditions"
            } Else {
                $AddURI = "finance/agreements?pagesize=$PageSize&page=$Page"
            }
            
            $FullURI = $Auth.BaseURI + $AddURI
    
            Try {
                $i = Invoke-RestMethod -Uri $FullURI -Method Get -Headers $Auth.Header -ErrorAction Stop
            } Catch {
                Throw $_
            }

            $Page++

            If ($i.Count) {
                $RetVal += $i
            }

        }

    Return $RetVal
}

<#
Author: Shea Bryarly
Date: 2020-09-22
Description: Gets agreement addition line item data.
Example of Conditions: "agreementStatus='Active' AND product/id=752"
#>
Function Get-AgrAdditions() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            $Auth,
        [Parameter(Mandatory=$true)]
            [INT]$PageSize,
        [Parameter(Mandatory=$false)]
            [INT]$AgreementID,
        [Parameter(Mandatory=$false)]
            [INT]$Conditions
    )

    $Page = 1
    $i = 0
    $RetVal = $NULL

    While (($i -ne 0) -OR ($i.count -ne 0)) {
            
            If ($Conditions) {
                $AddURI = "finance/agreements/$AgreementID/additions?pagesize=$PageSize&page=$Page&Conditions=$Conditions"
            } Else {
                $AddURI = "finance/agreements/$AgreementID/additions?pagesize=$PageSize&page=$Page"
            }

            $FullURI = $Auth.BaseURI + $AddURI
    
            Try {
                $i = Invoke-RestMethod -Uri $FullURI -Method Get -Headers $Auth.Header -ErrorAction Stop
            } Catch {
                Throw $_
            }

            $Page++

            If ($i.Count) {
                $RetVal += $i
            }

        }

    Return $RetVal
}

<#
-----------------------------------------------------------------------------------------------------------------------------------------------
Setter Functions
-------------------------------------------------------------------------------------------------------------------------------------------------
#>

<#
Functon Set-ContactCustomField
Author: Shea Bryarly
Date: 2020-02-17
Description: Sets a custom field on a contact.

Params:
ContactID - The CWM contactID
ID - The Custom field ID
Caption - the Custom Field name
Type - field type
Value - New value of field.

Example: 

Set-ContactCustomField -ContactID $contactID -ID 7 -Caption "Set Managed User (SW)" -Type "Checkbox" -Value $True
#>
Function Set-ContactCustomField() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            $Auth,
        [Parameter(Mandatory=$true)]
            [INT]$ContactID,
        [Parameter(Mandatory=$true)]
            [INT]$ID,
        [Parameter(Mandatory=$true)]
            [STRING]$Caption,
        [Parameter(Mandatory=$true)]
            [STRING]$Type,
        [Parameter(Mandatory=$true)]
            $Value
    )

    [STRING]$AddURI      = "company/contacts/$ContactID"
    [STRING]$FullURI     = $Auth.BaseURI + $AddURI 

    $RetVal = $NULL
    $Body = "[{
            op: 'replace',
            path: 'customFields',
            value: [
                {
                    'id': '$($ID)',
                    'caption': '$($Caption)',
                    'type': '$($Type)',
                    'entryMethod': 'Entryfield',
                    'numberofdecimals': 0,
                    'value': '$($Value)'
                }
            ],
        }
    ]"

    Try {
        $RetVal = Invoke-RestMethod -Uri $FullURI -Method Patch -Headers $Auth.Header -Body $Body -ContentType $Auth.ContentType -ErrorAction Stop
    } Catch {
        Throw $_
    }
}

<#
Author: Shea Bryarly
Date: 2020-09-22
Description: Sets the quantity of Agreement additions.
#>
Function Set-AgreementAdditionQuantity() {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            $Auth,
        [Parameter(Mandatory=$true)]
            [INT]$AgreementID,
        [Parameter(Mandatory=$true)]
            [INT]$AdditionID,
        [Parameter(Mandatory=$true)]
            [INT]$Quantity
    )

    $RetVal = $NULL
    $Body = "[{
            op: 'replace',
            path: 'quantity',
            value: '$($Quantity)'
        }
    ]"

    $AddURI = "finance/agreements/$AgreementID/additions/$AdditionID"
    $FullURI = $Auth.BaseURI + $AddURI

    Try {
        $RetVal = Invoke-RestMethod -Uri $FullURI -Method Patch -Headers $Auth.Header -Body $Body -ContentType $Auth.ContentType -ErrorAction Stop
    } Catch {
        Throw $_
    }

    Return $RetVal
}