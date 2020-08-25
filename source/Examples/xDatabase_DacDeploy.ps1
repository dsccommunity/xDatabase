<#
    .SYNOPSIS
        Deploy a Database using DACPAC

    .DESCRIPTION
        This configuration will deploy the database with the schema specified in the dacpac.
        If the db exists, the new schema will be deployed.
#>
configuration xDatabase_DacDeploy
{
    Import-DscResource -ModuleName 'xDatabase'

    Node 'localhost'
    {
        xDatabase 'DeployDac'
        {
            Ensure = 'Present'
            SqlServer = 'host.company.local'
            SqlServerVersion = '2008-R2'
            DatabaseName = 'MyDB'
            DacPacPath =  'C:\DacPac\file.dac'
            DacPacApplicationName = 'DacPacApplicationName'
        }
    }
}
