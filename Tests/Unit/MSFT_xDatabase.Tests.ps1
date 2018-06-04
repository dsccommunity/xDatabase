$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$leaf = Split-Path -Leaf $MyInvocation.MyCommand.Path
$source = "..\..\DSCResources\$($leaf.Split(".")[0])\$($leaf -replace ".Tests.ps1$",".psm1")"
$common = "..\..\DSCResources\xDatabase_Common\xDatabase_Common.psm1"
$sqlServerVersions = '2008-R2','2012','2014','2016','2017'

foreach ($sqlServerVersion in $sqlServerVersions)
{
  $testParameter = @{
    Ensure = "Present"
    SqlServer = "localhost"
    SqlServerVersion = $sqlServerVersion
    DatabaseName = "test"
  }

  Describe "Testing xDatabase resource execution"
  {
    Copy-Item -Path "$here\$source" -Destination TestDrive:\script.ps1
    Copy-Item -Path "$here\$common" -Destination TestDrive:\helper.ps1

    $connectionObj = New-Object -TypeName psobject
    $connectionObj | Add-Member -MemberType NoteProperty -Name connectionString -Value $null
    $connectionObj | Add-Member -MemberType ScriptMethod -Name Close -Value {return $null}
    Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "system.Data.SqlClient.SqlConnection" } -MockWith {return $connectionObj}

    Mock -CommandName Export-ModuleMember -MockWith {return $true}
    Mock -CommandName Import-Module -MockWith {return $true}
    . TestDrive:\script.ps1
    . TestDrive:\helper.ps1

    It "Get-TargetResource should return [Hashtable]"
    {
      (Get-TargetResource @testParameter).GetType()  -as [String] | Should Be "hashtable"
    }

    Context "database does not exist"
    {
      $connectionObj | Add-Member -MemberType ScriptMethod -Name Open -Value {throw [System.Data.SqlClient.SqlException]}
      It "Test-TargetResource should return false"
      {
        Test-TargetResource @testParameter | Should Be $false
      }
    }
    Context "database does exist"
    {
        $connectionObj | Add-Member -MemberType ScriptMethod -Name Open -Value {return $null} -Force
      It "Test-TargetResource should return false"
      {
        Test-TargetResource @testParameter | Should Be $true
      }
    }
  }
}
