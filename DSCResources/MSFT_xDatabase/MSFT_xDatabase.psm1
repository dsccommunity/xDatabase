 data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
DacFxInstallationError=Please ensure that DacFx is installed.
SmoFxInstallationError=Please ensure that Smo is installed.
DacPacExtractionError=Extracting DacPac for Db failed, continuing with Dac Deployment.
'@
}

$SmoServerLocation = "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [System.Management.Automation.PSCredential]
        $Credentials,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SqlServer,

        [parameter(Mandatory = $true)]
        [ValidateSet("2008-R2","2012","2014")]
        [System.String]
        $SqlServerVersion,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [System.String]
        $publishProfilePath

    )

        if($PSBoundParameters.ContainsKey('Credentials'))
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer -credentials $Credentials
    }
    else
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer
    }

    $dbExists = CheckIfDbExists $ConnectionString $DatabaseName
    $Ensure = if ($dbExists) { "Present" } else { "Absent" }

    $result = @{
        Ensure = $Ensure
        DatabaseName = $DatabaseName
        SqlServer = $SqlServer
        SqlServerVersion = $SqlServerVersion
    }
    return $result
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [System.Management.Automation.PSCredential]
        $Credentials,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SqlServer,

        [parameter(Mandatory = $true)]
        [ValidateSet("2008-R2","2012","2014")]
        [System.String]
        $SqlServerVersion,

        [System.String]
        $BacPacPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [System.String]
        $DacPacPath,

        [System.String]
        $DacPacApplicationName,

        [System.String]
        $DacPacApplicationVersion,
        
        [System.String]
        $publishProfilePath
    )
        

    if($PSBoundParameters.ContainsKey('Credentials'))
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer -credentials $Credentials
    }
    else
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer
    }
    
    if($Ensure -eq "Present")
    {
        if($PSBoundParameters.ContainsKey('BacPacPath'))
        {
            Perform-Restore -DbName $DatabaseName -connectionString $ConnectionString -sqlserverVersion $SqlServerVersion -bacpacFilePath $BacPacPath
        }
        elseif($PSBoundParameters.ContainsKey('DacPacPath'))
        {
            if(!$PSBoundParameters.ContainsKey('DacPacApplicationName'))
            {
                Throw "Application Name Needed for DAC Registration, else upgrade is unsupported"
            }
                
            Write-Verbose "Deploying Database"
            DeployDac -databaseName $DatabaseName -connectionString $ConnectionString -sqlserverVersion $SqlServerVersion -dacpacPath $DacPacPath -dacpacApplicationName $DacPacApplicationName -dacpacApplicationVersion $DacPacApplicationVersion -publishProfilePath $publishProfilePath
            Write-Verbose "Deploying Database...Done"
            
        }
        else
        {
            Write-Verbose "Creating Database"
            CreateDb -databaseName $DatabaseName -connectionString $ConnectionString
        }
    }
    else
    {
        Write-Verbose "Deleting Database"
        DeleteDb -databaseName $DatabaseName -connectionString $ConnectionString -sqlServerVersion $SqlServerVersion
    }

    
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [System.Management.Automation.PSCredential]
        $Credentials,

        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $SqlServer,

        [parameter(Mandatory = $true)]
        [ValidateSet("2008-R2","2012","2014")]
        [System.String]
        $SqlServerVersion,

        [System.String]
        $BacPacPath,

        [parameter(Mandatory = $true)]
        [System.String]
        $DatabaseName,

        [System.String]
        $DacPacPath,

        [System.String]
        $DacPacApplicationName,

        [System.String]
        $DacPacApplicationVersion,

        [System.String]
        $publishProfilePath

    )

    if($PSBoundParameters.ContainsKey('DacPacPath') -and $PSBoundParameters.ContainsKey('BacPacPath'))
    {
        throw "Specify only one out of dacpac or bacpac"
    }

    if($PSBoundParameters.ContainsKey('Credentials'))
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer -credentials $Credentials
    }
    else
    {
        $ConnectionString = Construct-ConnectionString -sqlServer $SqlServer
    }

    $dbExists = CheckIfDbExists $ConnectionString $DatabaseName

    if($Ensure -eq "Present")
    {
        if($PSBoundParameters.ContainsKey('BacPacPath'))
        {
            if($dbExists)
            {
                return $true
            }
  
            return $false
        }
        if($dbExists -eq $false)
        {
            return $false
        }
        if($dbExists -eq $true -and !$PSBoundParameters.ContainsKey('DacPacPath'))
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        if($dbExists)
        {
            return $false
        }

        return $true
    }
}

function CheckIfDbExists([string]$connectionString, [string]$databaseName)
{
    $connectionString = "$connectionString database=$databaseName;"

    $connection = New-Object system.Data.SqlClient.SqlConnection

    $connection.connectionstring = $connectionString

    try
    {
        $connection.Open()
    }
    catch
    {
        Write-Verbose "Unable to open connection: $_"
        return $false
    }

    $connection.Close()

    return $true
}

function DeployDac([string] $databaseName, [string]$connectionString, [string]$sqlserverVersion, [string]$dacpacPath, [string]$dacpacApplicationName, [string]$dacpacApplicationVersion, [string]$publishProfilePath)
{
    $defaultDacPacApplicationVersion = "1.0.0.0"

    if($PSBoundParameters.ContainsKey('dacpacApplicationVersion'))
    {
        $defaultDacPacApplicationVersion = $defaultDacPacApplicationVersion
    }

    Write-Verbose "DeployDac: Loading DacFx"

    Load-DacFx -sqlserverVersion $sqlserverVersion

    Write-Verbose "DeployDac: Loading DacPac"

    try
    {        
        $dacpacInstance = Load-Dacpac $path
    }
    catch
    {
        Write-Verbose("Unable to load dacpac, error: $_")  
        return    
    }    

    try
    {
        if($PSBoundParameters.ContainsKey('PublishProfilePath') -and  $publishProfilePath -ne "")
        {
            if(!(Test-Path $publishProfilePath)){
                Write-Verbose ("Dac Publish Profile in $publishProfilePath was not found, aborting")
                return
            }
            
            try
            {
                $dacProfile = Load-Profile $publishProfilePath
                Write-Verbose ("Dac Publish using Profile in $publishProfilePath")
            }
            catch
            {
                Write-Verbose("Dac Publish Profile Failed, error: $_")
                return        
            }

            Write-Verbose "DeployDac: Deploying DacPac with publish profile path"
            
            Deploy-Dacpac $connectionString $path $databaseName $true $publishProfilePath    
            
        }
        else
        {            
            Write-Verbose "DeployDac: Deploying DacPac"

            Deploy-Dacpac $connectionString $path $databaseName $true $null
        }
               
   }
   catch
   {
       Write-Verbose("Dac Deploy Failed, error: $_")
       return
   }
    
    try
    {        
        Register-Dacpac $connectionString $databaseName $dacpacApplicationName $defaultDacPacApplicationVersion
        Write-Verbose("Dac Deployed and Registered")    
    }
    catch
    {
        Write-Verbose("Dac Registration Failed, error: $_")
    }
    
}


function Get-DacServices([string]$connectionString){
    
    new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

}

function Get-DeployProfile([string]$sqlServerVersion, [string]$connectionString){
    
    new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)
}

function Load-Dacpac([string] $path){
    
    [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacPath)
}

function Load-Profile([string] $publishProfilePath){
    
    [Microsoft.SqlServer.Dac.DacProfile]::Load($publishProfilePath)
}

function Deploy-Dacpac([string]$connectionString, [string]$dacpacInstancePath, [string]$databaseName, [bool]$upgradeExisting, [string]$publishProfilePath ){
       
    $dacServicesObject = Get-DacServices $connectionString
    $dacpacInstance = Load-Dacpac $dacpacInstancePath

    if (![string]::IsNullOrEmpty($publishProfilePath) -and (Test-Path($publishProfilePath)))
    {   
        $dacProfile = Load-Profile $publishProfilePath
        $dacServicesObject.Deploy($dacpacInstance, $databaseName,$true, $dacProfile.DeployOptions) 
    }
    else
    {   
        $dacServicesObject.Deploy($dacpacInstance, $databaseName,$true)
    }
}

function Register-Dacpac([string]$connectionstring, [string]$databaseName, [string]$dacpacApplicationName, [string]$dacpacApplicationVersion){
    
    $dacServicesObject = Get-DacServices $connectionString
    $dacServicesObject.Register($databaseName, $dacpacApplicationName,$defaultDacPacApplicationVersion)
    
}


function CreateDb([string] $databaseName, [string]$connectionString)
{
    $sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);

    $query = "create database $databaseName"

    ExecuteSqlQuery $sqlConnection $query

    $sqlConnection.Close()
}

function DeleteDb([string] $databaseName, [string]$connectionString, [string]$sqlServerVersion)
{

    Load-SmoAssembly -sqlserverVersion $sqlServerVersion

    $sqlConnection = new-object system.data.SqlClient.SQLConnection($connectionString);

    $smo = New-Object Microsoft.SqlServer.Management.Smo.Server $sqlConnection.DataSource

    $smo.KillAllProcesses($databaseName)

    $query = "drop database $databaseName"

    $result = ExecuteSqlQuery $sqlConnection $query

    $sqlConnection.Close()
}

function ExecuteSqlQuery([system.data.SqlClient.SQLConnection]$sqlConnection, [string]$SqlQuery)
{
    $sqlCommand = new-object system.data.sqlclient.sqlcommand($SqlQuery, $sqlConnection);

    $sqlConnection.Open()

    if ($sqlCommand.ExecuteNonQuery() -ne -1)
    {
        return $true
    }

    return $false
}

function Construct-ConnectionString([string]$sqlServer, [System.Management.Automation.PSCredential]$credentials)
{

    $server = "Server=$sqlServer;"

    if($PSBoundParameters.ContainsKey('credentials'))
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

function Perform-Restore([string]$DbName, [string]$connectionString, [string]$sqlserverVersion, [string]$bacpacFilePath)
{
    Load-DacFx -sqlserverVersion $sqlserverVersion

    $dacServiceInstance = new-object Microsoft.SqlServer.Dac.DacServices ($connectionString)

    $bacpacPackageInstance = [Microsoft.SqlServer.Dac.BacPackage]::Load($bacpacFilePath)

    try
    {
        $dacServiceInstance.ImportBacpac($bacpacPackageInstance, $DbName)
    }
    catch
    {
        Throw "Restore Failed. Exception: $_"
    }
}

function Load-DacFx([string]$sqlserverVersion)
{
    $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion

    $DacFxLocation = "${env:ProgramFiles(x86)}\Microsoft SQL Server\$majorVersion\DAC\bin\Microsoft.SqlServer.Dac.dll"

    try
    {  
        [System.Reflection.Assembly]::LoadFrom($DacFxLocation) | Out-Null
    }
    catch
    {
        Throw "$LocalizedData.DacFxInstallationError"
    }
}

function Load-SmoAssembly([string]$sqlserverVersion)
{
    $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion

    $SmoLocation = "${env:ProgramFiles(x86)}\Microsoft SQL Server\$majorVersion\SDK\Assemblies\Microsoft.SqlServer.Smo.dll"
    try
    {  
        [System.Reflection.Assembly]::LoadFrom($SmoLocation) | Out-Null
    }
    catch
    {
        Throw "$LocalizedData.SmoFxInstallationError"
    }
}

function Get-SqlServerMajoreVersion([string]$sqlServerVersion)
{
    switch($sqlserverVersion)
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
    }

    return $majorVersion
}


   Export-ModuleMember -Function *-TargetResource
