function Test-PrescribingSchema {
    <#
    .SYNOPSIS
        Validates that a CSV file matches the expected NHSBSA prescribing data schema.
    .DESCRIPTION
        Internal helper used to ensure data integrity before ingestion.
    #>
    [CmdletBinding()]
    param(
        # The path to the CSV file to be validated
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    process {
        # Defined columns based on the agreed DataSchema.md
        # Standard EPD January 2024 Columns
        $ExpectedColumns = @(
            'YEAR_MONTH', 
            'PRACTICE_CODE', 
            'BNF_CODE', 
            'BNF_DESCRIPTION', 
            'ITEMS', 
            'NIC', 
            'ACTUAL_COST'
        )

        try {
            # Efficiently read only the header row (the first line)
            $HeaderLine = Get-Content -Path $Path -TotalCount 1
            
            if (-not $HeaderLine) {
                return [PSCustomObject]@{ IsValid = $false; Message = "File is empty or inaccessible." }
            }

            # Convert header string into an array of property names
            $ActualColumns = $HeaderLine.Split(',') | ForEach-Object { $_.Trim('"') }

            # Identify any missing columns
            $MissingColumns = $ExpectedColumns | Where-Object { $_ -notin $ActualColumns }

            if ($MissingColumns) {
                return [PSCustomObject]@{
                    IsValid = $false
                    Message = "Schema Mismatch. Missing: $($MissingColumns -join ', ')"
                }
            }

            return [PSCustomObject]@{
                IsValid = $true
                Message = "Schema validation successful."
            }
        }
        catch {
            return [PSCustomObject]@{
                IsValid = $false
                Message = "Error accessing file: $($_.Exception.Message)"
            }
        }
    }
}