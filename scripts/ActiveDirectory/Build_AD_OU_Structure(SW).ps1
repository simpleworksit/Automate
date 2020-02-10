<#
Author: Shea Bryarly
Date: 2020-02-10
Description:
Creates the standard Simpleworks OU structure on a domain controller.
The OU structure can be found here in IT Glue:
https://sw.itglue.com/337469/docs/2180696#version=published&documentMode=view

Parameters:
[String]TopLevel - This refers to the first OU under the domain root. This will be different for every customer. Is mandatory.

Example:

-TopLevel USOPM

#>

[CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [String]$TopLevelOU
    )

Try {
    $Domain = Get-ADDomain
} Catch {
    Write-Host "Domain could not be found. Exiting Script. $_"
    Exit
}

#Company Organizational Units

$DN = "OU=$TopLevelOU,$Domain"

Try {
    $CompanyOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Top level OU has been found."
} Catch {
    Write-Host "Could not find top level OU. Attempting to build it."

    Try {
        $CompanyOU = New-ADOrganizationalUnit -Name $TopLevelOU -Path $Domain.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Top level OU is created."
    } Catch {
        Write-Host "Could not create top level OU. Exiting Script. $_"
        Exit
    }
}

$DN = "OU=Contacts,$CompanyOU"

Try {
    $ContactsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Contacts OU has been found."
} Catch {
    Write-Host "Could not find Contacts OU. Attempting to build it."

    Try {
        $ContactsOU = New-ADOrganizationalUnit -Name 'Contacts' -Path $CompanyOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Contacts OU has been created."
    } Catch {
        Write-Host "Contacts OU has failed to be created. $_"
    }
}

$DN = "OU=Groups,$CompanyOU"

Try {
    $GroupsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Groups OU has been found."

} Catch {
    Write-Host "Could not find Groups OU. Attempting to build it."

    Try {
        $GroupsOU = New-ADOrganizationalUnit -Name 'Groups' -Path $CompanyOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Groups OU has been created."
    } Catch {
        Write-Host "Groups OU has failed to be created. $_"
    }
}

$DN = "OU=Users,$CompanyOU"

Try {
    $UsersOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Users OU has been found."

} Catch {
    Write-Host "Could not find Users OU. Attempting to build it."

    Try {
        $UsersOU = New-ADOrganizationalUnit -Name 'Users' -Path $CompanyOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Users OU has been created."
    } Catch {
        Write-Host "Users OU has failed to be created. $_"
    }
}

$DN = "OU=Computers,$CompanyOU"

Try {
    $ComputersOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Computers OU has been found."

} Catch {
    Write-Host "Could not find Computers OU. Attempting to build it."

    Try {
        $ComputersOU = New-ADOrganizationalUnit -Name 'Computers' -Path $CompanyOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Computers OU has been created."
    } Catch {
        Write-Host "Computers OU has failed to be created. $_"
    }
}


#Computer Organization Units

$DN = "OU=Member Servers,$ComputersOU"

Try {
    $MemberServersOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Member Servers OU has been found."

} Catch {
    Write-Host "Could not find Member Servers OU. Attempting to build it."

    Try {
        $MemberServersOU = New-ADOrganizationalUnit -Name 'Member Servers' -Path $ComputersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Member Servers OU has been created."
    } Catch {
        Write-Host "Member Servers OU has failed to be created. $_"
    }
}

$DN = "OU=Workstations,$ComputersOU"

Try {
    $WorkstationsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Workstations OU has been found."

} Catch {
    Write-Host "Could not find Workstations OU. Attempting to build it."

    Try {
        $WorkstationsOU = New-ADOrganizationalUnit -Name 'Workstations' -Path $ComputersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Workstations OU has been created."
    } Catch {
        Write-Host "Workstations OU has failed to be created. $_"
    }
}

#Group Organizational Units

$DN = "OU=Distribution Groups,$GroupsOU"

Try {
    $DistributionGroupsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Distribution Groups OU has been found."

} Catch {
    Write-Host "Could not find Distribution Groups OU. Attempting to build it."

    Try {
        $DistributionGroupsOU = New-ADOrganizationalUnit -Name 'Distribution Groups' -Path $GroupsOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Distribution Groups OU has been created."
    } Catch {
        Write-Host "Distribution Groups OU has failed to be created. $_"
    }
}

$DN = "OU=Security Groups,$GroupsOU"

Try {
    $SecurityGroupsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Security Groups OU has been found."

} Catch {
    Write-Host "Could not find Security Groups OU. Attempting to build it."

    Try {
        $SecurityGroupsOU = New-ADOrganizationalUnit -Name 'Security Groups' -Path $GroupsOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Security Groups OU has been created."
    } Catch {
        Write-Host "Security Groups OU has failed to be created. $_"
    }
}

#User Organizational Units

$DN = "OU=Admin Users,$UsersOU"

Try {
    $AdminUsersOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Admin Users OU has been found."

} Catch {
    Write-Host "Could not find Admin Users OU. Attempting to build it."

    Try {
        $AdminUsersOU = New-ADOrganizationalUnit -Name 'Admin Users' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Admin Users OU has been created."
    } Catch {
        Write-Host "Admin Users OU has failed to be created. $_"
    }
}

$DN = "OU=Managed Users,$UsersOU"

Try {
    $ManagedUsersOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Managed Users OU has been found."

} Catch {
    Write-Host "Could not find Managed Users OU. Attempting to build it."

    Try {
        $ManagedUsersOU = New-ADOrganizationalUnit -Name 'Managed Users' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Managed Users OU has been created."
    } Catch {
        Write-Host "Managed Users OU has failed to be created. $_"
    }
}

$DN = "OU=Shared Mailboxes,$UsersOU"

Try {
    $SharedMailboxesOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Shared Mailboxes OU has been found."

} Catch {
    Write-Host "Could not find Shared Mailboxes OU. Attempting to build it."

    Try {
        $SharedMailboxesOU = New-ADOrganizationalUnit -Name 'Shared Mailboxes' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Shared Mailboxes OU has been created."
    } Catch {
        Write-Host "Shared Mailboxes OU has failed to be created. $_"
    }
}

$DN = "OU=Service Accounts,$UsersOU"

Try {
    $ServiceAccountsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Service Accounts OU has been found."

} Catch {
    Write-Host "Could not find Service Accounts OU. Attempting to build it."

    Try {
        $ServiceAccountsOU = New-ADOrganizationalUnit -Name 'Service Accounts' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Service Accounts OU has been created."
    } Catch {
        Write-Host "Service Accounts OU has failed to be created. $_"
    }
}

$DN = "OU=Special Accounts,$UsersOU"

Try {
    $SpecialAccountsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Special Accounts OU has been found."

} Catch {
    Write-Host "Could not find Special Accounts OU. Attempting to build it."

    Try {
        $SpecialAccountsOU = New-ADOrganizationalUnit -Name 'Special Accounts' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Special Accounts OU has been created."
    } Catch {
        Write-Host "Special Accounts OU has failed to be created. $_"
    }
}

$DN = "OU=Disabled Accounts,$UsersOU"

Try {
    $DisabledAccountsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Disabled Accounts OU has been found."

} Catch {
    Write-Host "Could not find Special Accounts OU. Attempting to build it."

    Try {
        $DisabledAccountsOU = New-ADOrganizationalUnit -Name 'Disabled Accounts' -Path $UsersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Disabled Accounts OU has been created."
    } Catch {
        Write-Host "Disabled Accounts OU has failed to be created. $_"
    }
}

#Member Server Organizational Units

$DN = "OU=RDS Session Hosts,$MemberServersOU"

Try {
    $RDSSessionHostsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "RDS Session Hosts OU has been found."

} Catch {
    Write-Host "Could not find RDS Session Hosts OU. Attempting to build it."

    Try {
        $RDSSessionHostsOU = New-ADOrganizationalUnit -Name 'RDS Session Hosts' -Path $MemberServersOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "RDS Session Hosts OU has been created."
    } Catch {
        Write-Host "RDS Session Hosts OU has failed to be created. $_"
    }
}

#Workstation Organizational Units

$DN = "OU=Desktops,$WorkstationsOU"

Try {
    $DesktopsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Desktops OU has been found."

} Catch {
    Write-Host "Could not find Desktops OU. Attempting to build it."

    Try {
        $DesktopsOU = New-ADOrganizationalUnit -Name 'Desktops' -Path $WorkstationsOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Desktops OU has been created."
    } Catch {
        Write-Host "Desktops OU has failed to be created. $_"
    }
}

$DN = "OU=Laptops,$WorkstationsOU"

Try {
    $LaptopsOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "Laptops OU has been found."

} Catch {
    Write-Host "Could not find Laptops OU. Attempting to build it."

    Try {
        $LaptopsOU = New-ADOrganizationalUnit -Name 'Laptops' -Path $WorkstationsOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "Laptops OU has been created."
    } Catch {
        Write-Host "Laptops OU has failed to be created. $_"
    }
}

#Security Group Organizational Units

$DN = "OU=DL,$SecurityGroupsOU"

Try {
    $DLOU = Get-ADOrganizationalUnit -Identity $DN -ErrorAction Stop
    Write-Host "DL OU has been found."

} Catch {
    Write-Host "Could not find DL OU. Attempting to build it."

    Try {
        $DLOU = New-ADOrganizationalUnit -Name 'DL' -Path $SecurityGroupsOU.DistinguishedName -PassThru -ErrorAction Stop
        Write-Host "DL OU has been created."
    } Catch {
        Write-Host "DL OU has failed to be created. $_"
    }
}