Import-Module -DisableNameChecking -Name $PSScriptRoot\..\..\Modules\xDatabase.Common

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DACPAC", "BACPAC")]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateSet("2008-R2", "2012", "2014", "2016", "2017", "2019")]
        [System.String]
        $SqlServerVersion
    )

    Write-Verbose -Message 'Getting current state.'
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DACPAC", "BACPAC")]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateSet("2008-R2", "2012", "2014", "2016", "2017", "2019")]
        [System.String]
        $SqlServerVersion
    )

    Write-Verbose -Message 'Setting desired state.'

    $connectionString = Construct-ConnectionString -sqlServer $SqlServer -credentials $Credentials

    switch ($Type)
    {
        "DACPAC"
        {
            Extract-DacPacForDb -connectionString $connectionString -sqlServerVersion $SqlServerVersion -databaseName $DatabaseName -dacpacPath $Path
        }

        "BACPAC"
        {
            Import-BacPacForDb -connectionString $connectionString -sqlServerVersion $SqlServerVersion -databaseName $DatabaseName -bacpacPath $Path
        }
    }

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credentials,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SqlServer,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet("DACPAC", "BACPAC")]
        [System.String]
        $Type,

        [Parameter(Mandatory = $true)]
        [ValidateSet("2008-R2", "2012", "2014", "2016", "2017", "2019")]
        [System.String]
        $SqlServerVersion
    )

    Write-Verbose -Message 'Determine the current state.'

    $connectionString = Construct-ConnectionString -sqlServer $SqlServer -credentials $Credentials

    $dbExists = CheckIfDbExists -connectionString $connectionString -databaseName $DatabaseName

    if ($dbExists)
    {
        return $false
    }

    return $true
}

function Check-IfDbExists
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [string]
        $connectionString
    )

    $connectionString = "$connectionString database=$databaseName;"

    $connection = New-Object system.Data.SqlClient.SqlConnection

    $connection.connectionstring = $connectionString

    try
    {
        $connection.Open()
    }
    catch
    {
        return $false
    }

    $connection.Close()

    return $true
}

function Construct-ConnectionString
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $sqlServer,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $credentials
    )

    $uid = $credentials.UserName
    $pwd = $credentials.GetNetworkCredential().Password
    $server = "Server=$sqlServer;"

    if ($PSBoundParameters.ContainsKey('credentials'))
    {
        $integratedSecurity = "Integrated Security=False;"
        $userName = "uid=$uid;pwd=$pwd;"
    }
    else
    {
        $integratedSecurity = "Integrated Security=SSPI;"
    }

    $connectionString = "$server$userName$integratedSecurity"

    return $connectionString
}

function Extract-DacPacForDb
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $sqlServerVersion,

        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [string]
        $dacpacPath
    )

    Load-DacFx -sqlserverVersion $sqlServerVersion

    $dacService = new-object Microsoft.SqlServer.Dac.DacServices($connectionString)

    try
    {
        $dacService.Extract($dacpacPath, $databaseName, "MyApplication", "1.0.0.0")
    }
    catch
    {
        Write-Verbose -Message "Extracting DacPac failed"
    }
}

function Import-BacPacForDb
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $sqlServerVersion,

        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [string]
        $bacpacPath
    )

    Write-Verbose "Importing bacpac"

    Load-DacFx -sqlserverVersion $sqlServerVersion

    Write-Verbose $connectionString

    $dacServiceInstance = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    Write-Verbose $dacServiceInstance

    try
    {
        $dacServiceInstance.ExportBacpac($bacpacPath, $databaseName)
    }
    catch
    {
        Write-Verbose -Message "Importing BacPac failed"
    }
}

function Load-DacFx
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $sqlserverVersion
    )

    $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion

    $dacPathSuffix = "Microsoft SQL Server\$majorVersion\DAC\bin\Microsoft.SqlServer.Dac.dll"

    if (Test-Path -Path "${env:ProgramFiles(x86)})\$dacPathSuffix")
    {
        $DacFxLocation = "${env:ProgramFiles(x86)}\$dacPathSuffix"
    }
    else
    {
        $DacFxLocation = "$env:ProgramFiles\$dacPathSuffix"
    }

    try
    {
        [System.Reflection.Assembly]::LoadFrom($DacFxLocation) | Out-Null
    }
    catch
    {
        throw "Loading DacFx Failed"
    }
}

Export-ModuleMember -Function *-TargetResource
