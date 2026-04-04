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
                # Logic: Calculate Cost Per Item (Efficiency Metric)
                # We cast to [decimal] and [int] to ensure math works correctly
                $ActualCost = [decimal]$Row.'Actual Cost'
                $Items      = [int]$Row.Items
                
                # Prevent division by zero if items is 0
                $CostPerItem = if ($Items -gt 0) { [math]::Round($ActualCost / $Items, 2) } else { 0 }

                [PSCustomObject]@{
                    Period      = $Row.Period
                    Practice    = $Row.Practice
                    BNFName     = $Row.'BNF Name'
                    Items       = $Items
                    TotalCost   = $ActualCost
                    CostPerItem = $CostPerItem # The new insight
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