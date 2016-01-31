$assemblylist = "Microsoft.SqlServer.Dac.dll",
                "Microsoft.SqlServer.Smo.dll"
$sqlpsreg110="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps110"
$sqlpsreg100="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"



configuration DacDeploy
{

    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Ensure,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DatabaseName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServer,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SqlServerVersion,

        [String]$DacPacPath,

        [String]$BacPacPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$NodeName,

        [PSCredential]
        $Credentials,

        [string]$DacPacApplicationName,

        [string]$PublishProfilePath

    )

    Import-DSCResource -ModuleName xDatabase     
    
    Node 'localhost'
    { 
        xDatabase DeployDac
        {
            Ensure = $Ensure
            SqlServer = $SqlServer
            SqlServerVersion = $SqlServerVersion
            DatabaseName = $DatabaseName
            Credentials = $Credentials
            DacPacPath =  $DacPacPath
            DacPacApplicationName = $DacPacApplicationName
            PublishProfilePath = $PublishProfilePath
        } 
    } 
}

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName="*"
        }
        @{
            NodeName="localhost"
        }
    )
}

DacDeploy -ConfigurationData $ConfigurationData -Ensure "Present" -DatabaseName "dbr1" -SqlServer "." -SqlServerVersion "2014" -NodeName "localhost" -DacPacPath "C:\Dacpac\Dacpac.dacpac" -DacPacApplicationName "Registered App Name"
Start-DscConfiguration  -ComputerName "localhost" -Path .\DacDeploy -Wait -Force -Verbose

