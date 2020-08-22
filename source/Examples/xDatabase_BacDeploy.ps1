<#
    .SYNOPSIS
        Deploy Database using BACPAC

    .DESCRIPTION
        This configuration will deploy the database with the schema and data specified
        in the bacpac. If the database exists, no action is taken.
#>
configuration xDatabase_BacDeploy
{
    Import-DscResource -ModuleName 'xDatabase'

    Node 'localhost'
    {
        xDatabase 'DeployBackPac'
        {
            Ensure = 'Present'
            SqlServer = 'host.company.local'
            SqlServerVersion = '2008-R2'
            DatabaseName = 'MyDB'
            BacPacPath = 'C:\Backup\file.bac'
        }
    }
}
