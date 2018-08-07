#region HEADER
$script:HelperModuleName = 'xDatabase_Common'
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResources' -ChildPath 'xDatabase_Common\xDatabase_Common.psm1')) -Force -WarningAction SilentlyContinue
#endregion HEADER

# Begin Testing
InModuleScope $script:HelperModuleName {
    Describe 'xDatabase_Common\Get-DacPacDeployedVersion' -Tag 'Helper' {
      
        $mockedDatabase = @(
          @{DBName = 'DBTest'; DacPacVersion = '1.0.0.0'},
          @{DBName = 'TestDB'; DacPacVersion = '1.2.0.1'}
        )
      
        Mock -CommandName New-Object -MockWith {} 
        Mock -CommandName ReturnSqlQuery -MockWith {$mockedDatabase}
      
        It 'Should return DacPac version from the database' {
          $result = Get-DacPacDeployedVersion -ConnectionString 'ConnectionString' -DbName 'TestDB'
          $result | Should Be '1.2.0.1'
        }
      
        It 'Should return null if the database was not deployed by DacPac' {
          $result = Get-DacPacDeployedVersion -ConnectionString 'ConnectionString' -DbName 'NonDacPac'
          $result | Should -BeNullOrEmpty
        }
      }    
}