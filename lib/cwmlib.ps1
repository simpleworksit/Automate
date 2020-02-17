<#
Function Get-CWMAuth
Author: Shea Bryarly
Date: 2020-02-17
Description: Gets the basic variables for authentication for the other CWM functions to work. Returns an Auth Object.
#>
Function Get-CWMAuth() {
    [CmdletBinding()]
        Param(
        )
    
    $RetVal = $Null
    $PublicKey    = 'VEyt8kopSAUFh0RN'
    $PrivateKey   = 'BuNFIrIgG43GfL9P'
    $Authstring   = "SWCOS+$($PublicKey):$($PrivateKey)"
    $EncodedAuth  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)))
    
    $RetVal = [PSCustomObject] @{

        BaseUri      = "https://cw.simpleworksit.com/v4_6_Release/apis/3.0/"
        Accept       = "application/vnd.connectwise.com+json; version=v2019_4"
        ContentType  = "application/json"
        Header       = @{
                            Authorization = ("Basic $encodedAuth")
                            ClientID = "5a6dea14-5363-481c-9336-6c19aafe19f7"
                        }
    }

    Return $RetVal
}

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

    $Auth = Get-CWMAuth

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