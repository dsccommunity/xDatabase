$script:dscModuleName = 'xDatabase'
$script:dscResourceName = 'MSFT_xDatabase'
function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        $sqlServerVersions = '2008-R2', '2012', '2014', '2016', '2017'

        foreach ($sqlServerVersion in $sqlServerVersions)
        {
            $testParameter = @{
                Ensure           = "Present"
                SqlServer        = "localhost"
                SqlServerVersion = $sqlServerVersion
                DatabaseName     = "test"
            }

            Describe 'Testing xDatabase resource execution' {
                Context 'When getting the current state' {
                    BeforeAll {
                        $connectionObj = New-Object -TypeName PSObject
                        $connectionObj |
                            Add-Member -MemberType NoteProperty -Name connectionString -Value $null

                        $connectionObj |
                            Add-Member -MemberType ScriptMethod -Name Close -Value {
                                return $null
                            }

                        Mock -CommandName New-Object -ParameterFilter {
                            $TypeName -eq 'System.Data.SqlClient.SqlConnection'
                        } -MockWith {
                            return $connectionObj
                        }
                    }
                }

                It 'Get-TargetResource should return [Hashtable]' {
                    (Get-TargetResource @testParameter).GetType() -as [String] | Should -Be 'hashtable'
                }

                Context 'When database does not exist' {
                    BeforeAll {
                        $connectionObj = New-Object -TypeName PSObject
                        $connectionObj |
                        Add-Member -MemberType NoteProperty -Name connectionString -Value $null

                    $connectionObj |
                        Add-Member -MemberType ScriptMethod -Name Close -Value {
                            return $null
                        }

                        $connectionObj | Add-Member -MemberType ScriptMethod -Name Open -Value {
                            throw [System.Data.SqlClient.SqlException]
                        }
                    }

                    It 'Test-TargetResource should return false' {
                        Test-TargetResource @testParameter | Should -BeFalse
                    }
                }

                Context 'When database do exist' {
                    BeforeAll {
                       Mock -CommandName CheckIfDbExists -MockWith {
                           return $true
                       }
                    }

                    It 'Test-TargetResource should return true' {
                        Test-TargetResource @testParameter | Should -BeTrue
                    }
                }
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
