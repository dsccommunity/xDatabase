# xDatabase

[![Build Status](https://dev.azure.com/dsccommunity/xDatabase/_apis/build/status/dsccommunity.xDatabase?branchName=master)](https://dev.azure.com/dsccommunity/xDatabase/_build/latest?definitionId={definitionId}&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/xDatabase/{definitionId}/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/xDatabase/{definitionId}/master)](https://dsccommunity.visualstudio.com/xDatabase/_test/analytics?definitionId={definitionId}&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/xDatabase?label=xDatabase%20Preview)](https://www.powershellgallery.com/packages/xDatabase/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/xDatabase?label=xDatabase)](https://www.powershellgallery.com/packages/xDatabase/)

The **xDatabase** module contains the **xDatabase**, **xDatabaseLogin**,
**xDatabaseServer**, and  **xDBPackage** resources.

For information on Data-Tier Applications please refer to [http://technet.microsoft.com/en-us/library/ee240739(v=sql.105).aspx](http://technet.microsoft.com/en-us/library/ee240739(v=sql.105).aspx).

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Resources

- **xDatabase** handles creation/deletion of a database using a dacpac
  or SQL connection string.
- **xDatabaseLogin** _not yet written._.
- **xDatabaseServer** _not yet written._.
- **xDBPackage** allows extraction of a dacpac or import of a bacpac from
  a database.

### xDatabase

- **Credentials**: The credential to connect to the SQL server.
- **SqlServer**: The SQL server.
- **SqlServerVersion**: The version of the SQL Server.
  This property can take the following values:
  { 2008-R2 | 2012 | 2014 | 2016 | 2017 | 2019 }
- **BacPacPath**: The path to the .bacpac file to be used for database restore
  If this is used, the DacPacPath (see below) cannot be specified.
- **DacPacPath**: The path to the .dacpac file to be used for database schema deploy.
  If this is used, the BacPacPath (see above) cannot be specified.
- **DacPacApplicationName**: For deploying a database using .dacpac file,
  an application name with which the dacpac is registered.
  This is needed to support database upgrade using .dacpac files.
  This must specified if DacPacPath is provided.
- **DacPacApplicationVersion**: This is an optional parameter needed for
  registration for database deployment using .dacpac files for dacpac registration.
- **DatabaseName**: The name of the database to be deployed.

### xDatabaseLogin

_Not yet written_.

### xDatabaseServer

_Not yet written_.

### xDBPackage

- **DatabaseName**: The name of the database to be deployed.
- **SqlServer**: The SQL server.
- **SqlServerVersion**: The version of the SQL Server.
  This property can take the following values:
  { 2008-R2 | 2012 | 2014 | 2016 | 2017 | 2019 }
- **Path**: The path to the .bacpac or .dacpac file to be used to export
  a database to a bacpac or extract a db to a dacpac respectively.
- **Type**: This property can take the following values for dacpac extraction
  and bacpac export: { DACPAC | BACPAC }

## Examples

### Deploy a Database using DacPac

This configuration will deploy the database with the schema specified in the dacpac.
If the db exists, the new schema will be deployed.

```powershell
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

        [string]$DacPacApplicationName

    )

    Node ‘NodeName’
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

        }

    }
```

### Deploy Database using BACPAC

This configuration will deploy the database with the schema and data specified
in the bacpac. If the database exists, no action is taken.

```powershell
configuration BacPacDeploy
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

        [string]$DacPacApplicationName

    )

    Node ‘NodeName’
    {
        xDatabase DeployBacPac
        {
            Ensure = $Ensure
            SqlServer = $SqlServer
            SqlServerVersion = $SqlServerVersion
            DatabaseName = $DatabaseName
            Credentials = $Credentials
            BacPacPath = $BacPacPath
        }
    }
}
```

### Deploy Database without BACPAC or DACPAC

This configuration will create a database when neither a .dacpac nor a
.bacpac is specified.

```powershell
configuration DbDeploy
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

        [string]$DacPacApplicationName

    )

    Node ‘NodeName’
    {
        xDatabase DeployDatabase

        {
            Ensure = $Ensure
            SqlServer = $SqlServer
            SqlServerVersion = $SqlServerVersion
            DatabaseName = $DatabaseName
            Credentials = $Credentials
        }
    }
}
```
