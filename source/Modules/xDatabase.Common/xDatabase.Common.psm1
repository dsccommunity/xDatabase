data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
DacFxInstallationError=Please ensure that DacFx is installed.
SmoFxInstallationError=Please ensure that Smo is installed.
'@
}

function CheckIfDbExists
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $databaseName
    )

    Write-Verbose -Message "Inside CheckIfDbExists"

    $connectionString = "$connectionString database=$databaseName;"

    $connection = New-Object system.Data.SqlClient.SqlConnection

    $connection.connectionstring = $connectionString

    Write-Verbose -Message $connectionString

    try
    {
        $connection.Open()
    }
    catch
    {
        Write-Verbose -Message "Db does not exist"

        return $false
    }

    $connection.Close()

    return $true
}

function DeployDac
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $sqlserverVersion,

        [Parameter()]
        [string]
        $dacpacPath,

        [Parameter()]
        [string]
        $dacpacApplicationName,

        [Parameter()]
        [string]
        $dacpacApplicationVersion
    )

    if ($PSBoundParameters.ContainsKey('dacpacApplicationVersion'))
    {
        $defaultDacPacApplicationVersion = $dacpacApplicationVersion
    }
    else
    {
        $defaultDacPacApplicationVersion = "1.0.0.0"
    }

    try
    {
        Load-DacFx -sqlserverVersion $sqlserverVersion
    }
    catch
    {
        throw "$LocalizedData.DacFxInstallationError"
    }

    $dacServicesObject = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    $dacpacInstance = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacPath)

    try
    {
        $dacServicesObject.Deploy($dacpacInstance, $databaseName, $true)

        $dacServicesObject.Register($databaseName, $dacpacApplicationName, $defaultDacPacApplicationVersion)

        Write-Verbose -Message "Dac Deployed"
    }
    catch
    {
        $errorMessage = $_.Exception.Message
        Write-Verbose -Message ('Dac Deploy Failed: ''{0}''' -f $errorMessage)
    }
}

function CreateDb
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

    $sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);

    $query = "if not exists(SELECT name FROM sys.databases WHERE name='$databaseName') BEGIN create database $databaseName END"

    ExecuteSqlQuery -sqlConnection $sqlConnection -sqlQuery $query

    $sqlConnection.Close()
}

function DeleteDb
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $databaseName,

        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $sqlserverVersion
    )

    <#
    Load-SmoAssembly -sqlserverVersion $sqlServerVersion

    $smo = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlConnection.DataSource

    $smo.KillAllProcesses($databaseName)

    $query = "drop database $databaseName"
    #>

    $sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);

    #Forcibly drop database
    $Query = "If EXISTS(SELECT * FROM sys.databases WHERE name='$databaseName')
               BEGIN
                EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'$databaseName'
                ALTER DATABASE [$databaseName] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
                USE [master]
                DROP DATABASE [$databaseName]
               END"

    $result = ExecuteSqlQuery -sqlConnection $sqlConnection -sqlQuery $query

    $sqlConnection.Close()
}

function ExecuteSqlQuery
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter()]
        [System.Data.SqlClient.SQLConnection]
        $sqlConnection,

        [Parameter()]
        [string]
        $SqlQuery
    )

    $sqlCommand = new-object system.data.sqlclient.sqlcommand($SqlQuery, $sqlConnection)

    $sqlConnection.Open()
    $queryResult = $sqlCommand.ExecuteNonQuery()
    $sqlConnection.Close()

    if ($queryResult -ne -1)
    {
        return $true
    }

    return $false
}

function ReturnSqlQuery
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.Data.SqlClient.SQLConnection]
        $sqlConnection,

        [Parameter()]
        [string]
        $SqlQuery
    )

    $sqlCommand = new-object system.data.sqlclient.sqlcommand($SqlQuery, $sqlConnection)
    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($sqlCommand)
    $dataSet = New-Object System.Data.DataSet
    $sqlAdapter.Fill($dataSet)

    return $dataSet.Tables
}

function Get-DacPacDeployedVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ConnectionString,

        [Parameter(Mandatory = $true)]
        [string]
        $DbName
    )

    $sqlConnection = New-Object System.Data.SqlClient.SQLConnection($ConnectionString)
    $dacpacQueryString = 'SELECT instance_name as DBName, type_version as DacPacVersion FROM msdb.dbo.sysdac_instances'

    $result = ReturnSqlQuery -SqlConnection $sqlConnection -SqlQuery $dacpacQueryString

    return $result.Where( {$_.DBName -eq $DBName}).DacPacVersion
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

    $server = "Server=$sqlServer;"

    if ($PSBoundParameters.ContainsKey('credentials'))
    {
        $uid = $credentials.UserName
        $pwd = $credentials.GetNetworkCredential().Password
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

function Perform-Restore
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $DbName,

        [Parameter()]
        [string]
        $connectionString,

        [Parameter()]
        [string]
        $sqlserverVersion,

        [Parameter()]
        [string]
        $bacpacFilePath
    )

    Load-DacFx -sqlserverVersion $sqlserverVersion

    $dacServiceInstance = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    $bacpacPackageInstance = [Microsoft.SqlServer.Dac.BacPackage]::Load($bacpacFilePath)

    try
    {
        $dacServiceInstance.ImportBacpac($bacpacPackageInstance, $DbName)
    }
    catch
    {
        throw "Restore Failed Exception: $_"
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


    if(Test-Path -Path "${env:ProgramFiles(x86)}\$dacPathSuffix")
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
        throw "$LocalizedData.DacFxInstallationError"
    }
}

function Load-SmoAssembly
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $sqlserverVersion
    )

    $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion

    $smoPathSuffix = "Microsoft SQL Server\$majorVersion\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"

    if(Test-Path -Path "${env:ProgramFiles(x86)}\$smoPathSuffix")
    {
        $SmoLocation = "${env:ProgramFiles(x86)}\$smoPathSuffix"
    }
    else
    {
        $SmoLocation = "$env:ProgramFiles\$smoPathSuffix"
    }

    try
    {
        [System.Reflection.Assembly]::LoadFrom($SmoLocation) | Out-Null
    }
    catch
    {
        throw "$LocalizedData.SmoFxInstallationError"
    }
}

function Get-SqlServerMajoreVersion
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $sqlserverVersion
    )

    switch ($sqlserverVersion)
    {
        "2008-R2"
        {
            $majorVersion = 100
        }
        "2012"
        {
            $majorVersion = 110
        }
        "2014"
        {
            $majorVersion = 120
        }
        "2016"
        {
            $majorVersion = 130
        }
        "2017"
        {
            $majorVersion = 140
        }
        "2019"
        {
            $majorVersion = 150
        }
    }

    return $majorVersion
}

function Get-SqlDatabaseOwner
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $DatabaseName,

        [Parameter()]
        [string]
        $connectionString
    )

    [string]$SqlQuery = "SELECT SUSER_SNAME(owner_sid) [OwnerName] FROM sys.databases where name = '$DatabaseName'"

    $sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString)

    return (ReturnSqlQuery -sqlConnection $sqlConnection -SqlQuery $SqlQuery).OwnerName
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

    Write-Verbose -Message "Importing bacpac"

    Load-DacFx -sqlserverVersion $sqlServerVersion

    Write-Verbose -Message $connectionString

    $dacServiceInstance = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    Write-Verbose -Message $dacServiceInstance

    try
    {
        $dacServiceInstance.ExportBacpac($bacpacPath, $databaseName)
    }
    catch
    {
        Write-Verbose -Message "Importing BacPac failed"
    }
}
