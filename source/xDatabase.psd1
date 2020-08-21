@{
    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # ID used to uniquely identify this module
    GUID                 = '8ad956dd-4a36-4767-9725-ed0466893edb'

    # Author of this module
    Author               = 'DSC Community'

    # Company or vendor of this module
    CompanyName          = 'DSC Community'

    # Copyright statement for this module
    Copyright            = 'Copyright the DSC Community contributors. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'This module contains 2 resources. xDatabase allows to create and deploy databases using DAC or connection string, restore a database using BACPAC and delete a database. The xDBPackage resource allows extracting a database to a DACPAC or exporting to a BACPAC'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'xDatabase'
        'xDatabaseLogin'
        'xDatabaseServer'
        'xDBPackage'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'DesiredStateConfiguration', 'DSC', 'DSCResourceKit', 'DSCResource'

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/dsccommunity/xDatabase/blob/master/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/dsccommunity/xDatabase'

            # A URL to an icon representing this module.
            IconUri      = 'https://dsccommunity.org/images/DSC_Logo_300p.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''

            # Prerelease string of this module
            Prerelease   = ''
        } # End of PSData hashtable

    } # End of PrivateData hashtable
}
