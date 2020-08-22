# xDatabase

The **xDatabase** module contains the **xDatabase**, **xDatabaseLogin**,
**xDatabaseServer**, and  **xDBPackage** resources.

[![Build Status](https://dev.azure.com/dsccommunity/xDatabase/_apis/build/status/dsccommunity.xDatabase?branchName=master)](https://dev.azure.com/dsccommunity/xDatabase/_build/latest?definitionId=45&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/xDatabase/45/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/xDatabase/45/master)](https://dsccommunity.visualstudio.com/xDatabase/_test/analytics?definitionId=45&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/xDatabase?label=xDatabase%20Preview)](https://www.powershellgallery.com/packages/xDatabase/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/xDatabase?label=xDatabase)](https://www.powershellgallery.com/packages/xDatabase/)

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Change log

A full list of changes in each version can be found in the [change log](CHANGELOG.md).

## Documentation

Please se the section [Resources](#resources).

### Examples

You can review the [Examples](/source/Examples) directory in the repository
for some general use scenarios for all of the resources that are in the module.

## Resources

For information on Data-Tier Applications please refer to [Understanding Data-tier Applications](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ee240739(v=sql.105)).

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
