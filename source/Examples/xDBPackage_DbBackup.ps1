configuration xDBPackage_DbBackup
{
    Import-DscResource -ModuleName 'xDatabase'

    Node 'localhost'
    {
        xDBPackage 'Backup'
        {
            SqlServer = 'host.company.local'
            SqlServerVersion = '2008-R2'
            Type = 'DACPAC'
            DatabaseName = 'MyDB'
            Path = 'C:\Backup\file.dac'
        }
    }

}
