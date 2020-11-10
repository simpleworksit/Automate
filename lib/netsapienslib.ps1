<#
Function Get-NSAuth()
Author: Shea Bryarly
Date: 2020-11-09
Description: Gets the basic variables for authentication for the other Netsapian functions to work. Returns an authentication object.
#>
Function Get-NSAuth() {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
                [STRING]$ClientID,
            [Parameter(Mandatory=$true)]
                [STRING]$ClientSecret,
            [Parameter(Mandatory=$true)]
                [STRING]$Username,
            [Parameter(Mandatory=$true)]
                [STRING]$Password
        )
    
    $URL = "https://simpleworksit.option9.net/ns-api/oauth2/token/?grant_type=password&client_id=$ClientID&client_secret=$ClientSecret&username=$Username&password=$Password"

    If ((Get-Date) -lt $Auth.Exp) {
        Return $Auth
    } Else {
        Try {
            $APIVal = Invoke-RestMethod -Uri $URL -ErrorAction Stop
        } Catch {
            Throw $_ 
        }

        $TS = New-TimeSpan -Seconds $APIVal.expires_in
        
        $RetVal = [PSCustomObject]@{
            Header = @{'Authorization' = "Bearer $($APIVal.access_token)"}
            Exp = (Get-Date) + $TS
            ContentType = 'application/json'
        }
        Return $RetVal
    }

}

<#
Function Get-DomainCDR()
Author: Shea Bryarly
Date: 2020-11-09
Description: Grabs the Call Data Records at the domain level. 

Parameters:
    Auth - Must supply an authentication token that you can get from NS-Auth
    Domain - Netsapien domain you want to pull from i.e. simpleworksit.com
    Type - 0 for Outbound calls, 1 for Inbound calls, 2 for Missed Calls, and 3 for On Net calls
    Timespan - Should either be "Weekly" or "Monthly"
    UnitsBack - Used in conjuction with Timespan. Specifies how many months/weeks back in INT form.
    Limit - the NS API does not have pagination so I usually pick a huge number for this so I can just get all the records. *refining your search doesn't seem lower record count with this API
    FilterToNumber - Filters the number that someone dialed. i.e. our sales line 719-476-0443.

Example:
$InBoundSalesCalls = Get-DomainCDR -Auth $Auth -Domain "simpleworksit.com" -Type 1 -TimeSpan "Monthly" -UnitsBack 2 -Limit 9000000 -FilterToNumber "7194760443"
Grabs all inbound calls from two months ago to one month ago that went to Sales.
#>
Function Get-DomainCDR() {
    [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
                $Auth,
            [Parameter(Mandatory=$true)]
                [STRING]$Domain,
            [Parameter(Mandatory=$true)]
                [INT]$Type,
            [Parameter(Mandatory=$true)]
                [STRING]$TimeSpan,
            [Parameter(Mandatory=$true)]
                [INT]$UnitsBack,
            [Parameter(Mandatory=$true)]
                [INT]$Limit,
            [Parameter(Mandatory=$false)]
                [STRING]$FilterToNumber
        )
    
    If ($TimeSpan -eq "Weekly") {
        $Weeks = $UnitsBack * 7
    }

    Switch ($TimeSpan)
    {
        "Monthly" {
            $StartDate = (Get-Date (Get-Date).AddMonths(-$UnitsBack) -UFormat "%Y/%m/%d %T")
            $EndDate = (Get-Date (Get-Date $StartDate).AddMonths(1) -UFormat "%Y/%m/%d %T")
        }
        "Weekly"  {
            $StartDate = (Get-Date (Get-Date).AddDays(-$Weeks) -UFormat "%Y/%m/%d %T")
            $EndDate = (Get-Date (Get-Date $StartDate).AddDays(7) -UFormat "%Y/%m/%d %T")
        }
        Default {Write-Host "TimeSpan variable entered incorrectly."}
    }

    $URL = "https://simpleworksit.option9.net/ns-api/?object=cdr2&action=read&type=$type&start_date=$StartDate&end_date=$EndDate&limit=$Limit&domain=$Domain"
    
    Try {
        $APICall = Invoke-RestMethod -Uri $URL -Headers $Auth.Header -Method GET -ContentType $Auth.ContentType -ErrorAction Stop
    } Catch {
        Throw $_
    }

    $RetVal = @()

    ForEach ($cdr in $APICall.xml.cdr) {

        If ($cdr.orig_from_uri -match "\W(\d{10,11})@") {
            $m = $Matches[1]
        } Else {
            $m = "N/A"
        }

        If ($cdr.orig_from_name -ne "") {
            $name = $cdr.orig_from_name
        } Else {
            $name = "N/A"
        }

        $obj = [PSCustomObject] @{
            CallDate = (Get-Date ((Get-Date "1970/1/1") + (New-TimeSpan -Seconds $cdr.time_start)) -UFormat "%Y/%m/%d %T")
            FromName = $name
            FromNumber = $Matches[1]
            ToNumber = $cdr.orig_to_user
            TimeTalking = $cdr.time_talking
        }

        $RetVal += $obj
    }

    $RetVal = $RetVal | Sort-Object CallDate

    If ($FilterToNumber) {
        $RetVal = ($RetVal | ? {$_.ToNumber -like "*" + $FilterToNumber + "*"})
    } Else {
    }

    Return $RetVal
}