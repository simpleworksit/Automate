Try {
    . C:\swgit\Automate\lib\cwmlib1.ps1
} Catch {
    Write-Host "Can't find file."
}

#Set-ContactCustomField -ContactID 8057 -ID 7 -Caption "Managed User (SW)" -Type "Checkbox" -Value $False
