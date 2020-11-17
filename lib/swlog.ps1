<#=============================================================
Log-Message()

=============================================================#>

Function Log-Message () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
            [String]$msg,
        [Parameter(Mandatory=$true)]
            [String]$filepath,
        [Parameter(Mandatory=$false)]
            [Switch]$quiet
    )

    $dateTime = (Get-Date)

    "$(Get-Date $dateTime -Format G): " + $msg>>$filepath
    If (-not ($quiet.IsPresent)) {
        Write-Host $msg
    }
}