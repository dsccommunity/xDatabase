<#
    .SYNOPSIS
        Deploy Database without BACPAC or DACPAC

    .DESCRIPTION
        This configuration will create a database when neither a .dacpac nor a
        .bacpac is specified.
#>
configuration xDatabase_CreateDatabase
{
    Import-DscResource -ModuleName 'xDatabase'

    Node 'localhost'
    {
        xDatabase 'DeployDatabase'
        {
            Ensure = 'Present'
            SqlServer = 'host.company.local'
            SqlServerVersion = '2008-R2'
            DatabaseName = 'MyDB'
        }
    }
}
