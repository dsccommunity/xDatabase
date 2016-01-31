$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$leaf = Split-Path -Leaf $MyInvocation.MyCommand.Path
$source = "..\DSCResources\$($leaf.Split(".")[0])\$($leaf -replace ".Tests.ps1$",".psm1")"

$testParameter = @{
    Ensure = "Present"
    SqlServer = "localhost"
    SqlServerVersion = "2014"
    DatabaseName = "test"
}

Describe "Testing xDatabase resource execution" {
    Copy-Item -Path "$here\$source" -Destination TestDrive:\script.ps1

    $connectionObj = New-Object -TypeName psobject
    $connectionObj | Add-Member -MemberType NoteProperty -Name connectionString -Value $null
    $connectionObj | Add-Member -MemberType ScriptMethod -Name Close -Value {return $null}
    Mock -CommandName New-Object -ParameterFilter { $TypeName -eq "system.Data.SqlClient.SqlConnection" } -MockWith {return $connectionObj}

    Mock -CommandName Export-ModuleMember -MockWith {return $true}
    . TestDrive:\script.ps1

    It "Get-TargetResource should return [Hashtable]" {
        (Get-TargetResource @testParameter).GetType()  -as [String] | Should Be "hashtable"
    }
    Context "database does not exist" {

        $connectionObj | Add-Member -MemberType ScriptMethod -Name Open -Value {throw [System.Data.SqlClient.SqlException]}
        It "Test-TargetResource should return false" {
            Test-TargetResource @testParameter | Should Be $false
        }
    }
    Context "database does exist" {

        $connectionObj | Add-Member -MemberType ScriptMethod -Name Open -Value {return $null} -Force
        It "Test-TargetResource should return false" {
            Test-TargetResource @testParameter | Should Be $true
        }
    }
}

$testParameterWithPublishProfile = @{
    Ensure = "Present"
    SqlServer = "localhost"
    SqlServerVersion = "2014"
    DatabaseName = "test"
    PublishProfilePath = "c:\publishProfile.xml"
    DacpacPath = "c:\dacpac.dacpac"
    DacPacApplicationName = "Testing"
}

$testParameterWithoutPublishProfile = @{
    Ensure = "Present"
    SqlServer = "localhost"
    SqlServerVersion = "2014"
    DatabaseName = "test"
    DacpacPath = "c:\dacpac.dacpac"
    DacPacApplicationName = "Testing"
}

Describe "Testing Set-TargetResource with a publishProfilePath" {
    Copy-Item -Path "$here\$source" -Destination TestDrive:\script.ps1
    
    Mock Export-ModuleMember -MockWith {return $true}
    . TestDrive:\script.ps1
    
    Mock -CommandName Test-Path -MockWith{ return $true }
    
    It "Set-TargetResource should use publishProfilePath" {
    
        Mock -CommandName Load-DacFx
        Mock -CommandName Load-Dacpac
        Mock -CommandName Load-Profile     
        Mock -CommandName Deploy-Dacpac
        Mock -CommandName Register-Dacpac
                
        (Set-TargetResource @testParameterWithPublishProfile)
                
        Assert-MockCalled -CommandName Load-Profile -Exactly 1  
        Assert-MockCalled -CommandName Deploy-Dacpac -ParameterFilter { $publishProfilePath -eq "c:\publishProfile.xml"} -Exactly 1
        Assert-MockCalled -CommandName Register-Dacpac -Exactly 1
    }
     
}

Describe "Testing Set-TargetResource without a publishProfilePath" {
    Copy-Item -Path "$here\$source" -Destination TestDrive:\script.ps1
    
    Mock Export-ModuleMember -MockWith {return $true}
    . TestDrive:\script.ps1
    
    Mock -CommandName Test-Path -MockWith{ return $true }
     
    Mock -CommandName Load-DacFx
    Mock -CommandName Load-Dacpac
    Mock -CommandName Deploy-Dacpac
    Mock -CommandName Register-Dacpac  
    Mock -CommandName Load-Profile    
    
    It "Set-TargetResource should not use publishProfilePath" {
                              
        (Set-TargetResource @testParameterWithoutPublishProfile)
                         
        Assert-MockCalled -CommandName Deploy-Dacpac -Exactly 1
        Assert-MockCalled -CommandName Register-Dacpac -Exactly 1
        Assert-MockCalled -CommandName Load-Profile -Exactly 0
    }
        
}
