<#
Author: Shea Bryarly
Date: 2020-11-10
Description: This script pulls call data records for Monthly and Weekly time spans.

Parameters:
$netsapianslib: The Netsapians library file path
$ClientID: The Client ID provided by data102
$ClientSecret: The Client Secret provided by data102
$Username: The simpleworks username
$Password: The simpleworks password for OAuth2 API Authentication
$TimeSpan: Specifies either Monthly or Weekly time spans

Example:
C:\swgit\Automate\scripts\Marketing\CDR.ps1 -netsapianslib C:\swgit\Automate\lib\netsapienslib.ps1 -ClientID [clientID] -ClientSecret [clientsecret] -Username [username] -Password [password] -TimeSpan "Monthly"

Output:

Does not return any values. Just a table of call data records and some additional information:

=================================================================

Calls Two Week Ago: 3 -- Time Spent Talking in Minutes: 834
Calls Last Week: 16 -- Time Spent Talking in Minutes: 2344

Call Data Records for Last Week:

CallDate            FromName        FromNumber  ToNumber     TimeTalking
--------            --------        ----------  --------     -----------
2020/11/03 16:16:36 COLORADO SPG CO 17194955536 +17194760443 170        
2020/11/03 16:36:40 N/A             15057101109 +17194760443 34         
2020/11/03 17:19:47 N/A             17193300326 +17194760443 117        
2020/11/03 20:54:52 WIRELESS CALLER 17196403129 +17194760443 59         
2020/11/03 20:54:52 WIRELESS CALLER 17196403129 +17194760443 283        
2020/11/03 22:35:53 JOHN ROGEL      18586146727 +17194760443 613        
2020/11/03 23:02:08 N/A             14023660857 +17194760443 13         
2020/11/04 17:42:36 WIRELESS CALLER 15205993737 +17194760443 21         
2020/11/04 20:01:19 WIRELESS CALLER 17193522135 +17194760443 91         
2020/11/05 15:57:17 WIRELESS CALLER 15205993737 +17194760443 6          
2020/11/06 16:17:37 TIMOTHY HUMPHRI 19704050138 +17194760443 84         
2020/11/06 21:48:14 N/A             12536869423 +17194760443 412        
2020/11/09 16:36:47 MILLIE WALLY    19167085500 +17194760443 0          
2020/11/09 17:32:57 Cordell Jessica 17193680136 +17194760443 29         
2020/11/09 17:40:41 MILL VALLEY  CA 16282037406 +17194760443 381        
2020/11/09 17:47:44 ERIC CABRERA    17199669006 +17194760443 31
#>

[CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
                [String]$netsapianslib,
            [Parameter(Mandatory=$true)]
                [String]$ClientID,
            [Parameter(Mandatory=$true)]
                [STRING]$ClientSecret,
            [Parameter(Mandatory=$true)]
                [STRING]$Username,
            [Parameter(Mandatory=$true)]
                [STRING]$Password,
            [Parameter(Mandatory=$true)]
                [STRING]$TimeSpan
        )

If (Test-Path $netsapianslib) {
    . $netsapianslib
} Else {
    Write-Host "Can't find netsapianslib. Exiting Script"
    Exit
}

$Auth = Get-NSAuth -ClientID $ClientID -ClientSecret $ClientSecret -Username $Username -Password $Password
$OneUnitAgo = Get-DomainCDR -Auth $Auth -Domain "simpleworksit.com" -Type 1 -TimeSpan $TimeSpan -UnitsBack 1 -Limit 9000000 -FilterToNumber "7194760443"
$TwoUnitsAgo = Get-DomainCDR -Auth $Auth -Domain "simpleworksit.com" -Type 1 -TimeSpan $TimeSpan -UnitsBack 2 -Limit 9000000 -FilterToNumber "7194760443"

Write-Host "===============================================================`n"

If ($Timespan -eq "Monthly") {
    Write-Host "Calls Two Months Ago: $($TwoUnitsAgo.Count) -- Time Spent Talking in Seconds: $(($TwoUnitsAgo.TimeTalking | Measure-Object -Sum).Sum)"
    Write-Host "Calls Last Month: $($OneUnitAgo.Count) -- Time Spent Talking in Seconds: $(($OneUnitAgo.TimeTalking | Measure-Object -Sum).Sum)"
    Write-Host "`nCall Data Records for Last Month:"
} Elseif ($TimeSpan -eq "Weekly") {
    Write-Host "Calls Two Week Ago: $($TwoUnitsAgo.Count) -- Time Spent Talking in Seconds: $(($TwoUnitsAgo.TimeTalking | Measure-Object -Sum).Sum)"
    Write-Host "Calls Last Week: $($OneUnitAgo.Count) -- Time Spent Talking in Seconds: $(($OneUnitAgo.TimeTalking | Measure-Object -Sum).Sum)"
    Write-Host "`nCall Data Records for Last Week:"
}

$OneUnitAgo | Format-Table -AutoSize

Write-Host "==============================================================="

#C:\swgit\Automate\scripts\Marketing\CDR.ps1 -netsapianslib C:\swgit\Automate\lib\netsapienslib.ps1 -ClientID simpleworks-api -ClientSecret 3da857c8b1e487ff577930a66a5c1274 -Username techstaff@swreseller.com -Password helpmeCarl2 -TimeSpan "Monthly"