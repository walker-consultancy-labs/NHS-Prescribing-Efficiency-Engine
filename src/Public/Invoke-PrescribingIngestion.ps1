function Invoke-PrescribingIngestion {
    <#
    .SYNOPSIS
        Ingests and validates NHSBSA prescribing data, calculating key efficiency metrics.
    .DESCRIPTION
        The primary orchestration function for the Prescribing Engine. Validates the 
        schema before calculating Cost Per Item for each record.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    process {
        Write-Verbose "Starting ingestion for: $Path"

        # Step 1: Validate Schema using our Private Helper
        $SchemaCheck = Test-PrescribingSchema -Path $Path
        if (-not $SchemaCheck.IsValid) {
            Write-Error "Data Ingestion Aborted: $($SchemaCheck.Message)"
            return
        }

        # Step 2: Import and Process Data
        # We use -ErrorAction Stop to ensure we catch any data-level issues
        try {
            $RawData = Import-Csv -Path $Path -ErrorAction Stop
            
            $ProcessedData = foreach ($Row in $RawData) {
            # Logic: Cast and clean the strings (removing trailing dots if present)
            $ActualCost = [decimal]($Row.ACTUAL_COST.Trim('.'))
            $Items      = [int]($Row.ITEMS.Trim('.'))
            
            $CostPerItem = if ($Items -gt 0) { [math]::Round($ActualCost / $Items, 2) } else { 0 }

            [PSCustomObject]@{
                Period      = $Row.YEAR_MONTH
                Practice    = $Row.PRACTICE_CODE
                BNFName     = $Row.BNF_DESCRIPTION
                Items       = $Items
                TotalCost   = $ActualCost
                CostPerItem = $CostPerItem
                Status      = "Validated"
            }
        }
            return $ProcessedData
        }
        catch {
            Write-Error "Failed to process data rows: $($_.Exception.Message)"
        }
    }
}