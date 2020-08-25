#region HEADER
$script:projectPath = "$PSScriptRoot\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:parentModule = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
$script:subModulesFolder = Join-Path -Path $script:parentModule.ModuleBase -ChildPath 'Modules'
Remove-Module -Name $script:parentModule -Force -ErrorAction 'SilentlyContinue'

$script:subModuleName = (Split-Path -Path $PSCommandPath -Leaf) -replace '\.Tests.ps1'
$script:subModuleFile = Join-Path -Path $script:subModulesFolder -ChildPath "$($script:subModuleName)"

Import-Module $script:subModuleFile -Force -ErrorAction 'Stop'
#endregion HEADER

InModuleScope $script:subModuleName {
    Describe 'xDatabase.Common\Get-DacPacDeployedVersion' -Tag 'Helper' {
        $mockedDatabase = @(
            @{DBName = 'DBTest'; DacPacVersion = '1.0.0.0'},
            @{DBName = 'TestDB'; DacPacVersion = '1.2.0.1'}
        )

        Mock -CommandName New-Object
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
