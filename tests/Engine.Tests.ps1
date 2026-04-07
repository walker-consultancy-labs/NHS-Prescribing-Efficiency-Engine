# tests/Engine.Tests.ps1

# Load the module
Import-Module "$PSScriptRoot/../src/PrescribingEngine.psd1" -Force

Describe "Prescribing Engine - Core Logic" {
    
    Context "Schema Validation" {
        It "Should pass when the CSV has the correct SNOMED headers" {
            $TestPath = "$PSScriptRoot/test_valid.csv"
            "YEAR_MONTH,PRACTICE_CODE,BNF_CODE,BNF_DESCRIPTION,ITEMS,NIC,ACTUAL_COST" | Out-File $TestPath -Encoding utf8
            
            $Result = Test-PrescribingSchema -Path $TestPath
            $Result.IsValid | Should Be $true
            
            Remove-Item $TestPath
        }

        It "Should fail when headers are missing or misspelled" {
            $TestPath = "$PSScriptRoot/test_broken.csv"
            "YEAR,PRACTICE,WRONG_HEADER,ITEMS,COST" | Out-File $TestPath -Encoding utf8
            
            $Result = Test-PrescribingSchema -Path $TestPath
            $Result.IsValid | Should Be $false
            
            # Bulletproof Fix: Use standard PowerShell -match and assert the boolean
            ($Result.Message -match "Schema Mismatch") | Should Be $true
            
            Remove-Item $TestPath
        }
    }

    Context "Data Transformation" {
        It "Should correctly calculate Cost Per Item" {
            $TestPath = "$PSScriptRoot/test_data.csv"
            $Header = "YEAR_MONTH,PRACTICE_CODE,BNF_CODE,BNF_DESCRIPTION,ITEMS,NIC,ACTUAL_COST"
            $Row    = "202301,P81001,010101,Test Drug,10,50.00,50.00"
            $Header, $Row | Out-File $TestPath -Encoding utf8
            
            $Result = Invoke-PrescribingIngestion -Path $TestPath
            
            $Result.CostPerItem | Should Be 5.00
            
            Remove-Item $TestPath
        }

        It "Should handle the 'trailing dot' data issue gracefully" {
            $TestPath = "$PSScriptRoot/test_dot.csv"
            $Header = "YEAR_MONTH,PRACTICE_CODE,BNF_CODE,BNF_DESCRIPTION,ITEMS,NIC,ACTUAL_COST"
            $Row    = "202301,P81001,010101,Test Drug,10.,20.,20."
            $Header, $Row | Out-File $TestPath -Encoding utf8
            
            $Result = Invoke-PrescribingIngestion -Path $TestPath
            
            $Result.Items | Should Be 10
            $Result.TotalCost | Should Be 20.0
            
            Remove-Item $TestPath
        }
    }
}