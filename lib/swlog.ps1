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
            [Switch]$quiet,
        [Parameter(Mandatory=$false)]
            [Switch]$time
    )

    $dateTime = (Get-Date)

    If ($time.IsPresent) {
        "$(Get-Date $dateTime -Format G): " + $msg>>$filepath
    } Else {
        $msg>>$filepath
    }

    If (-not ($quiet.IsPresent)) {
        Write-Host $msg
    }
}