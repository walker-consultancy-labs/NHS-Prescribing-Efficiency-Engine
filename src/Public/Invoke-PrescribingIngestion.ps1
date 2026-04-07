function Invoke-PrescribingIngestion {
    <#
    .SYNOPSIS
        Optimised ingestion engine using System.IO.StreamReader for large-scale NHSBSA datasets.
    .DESCRIPTION
        Reads the file line-by-line to maintain a low memory footprint. 
        Calculates Cost Per Item and returns a PSCustomObject for each record.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    process {
        Write-Verbose "Initialising Stream Reader for: $Path"

        # Step 1: Schema Check (Still using our Gatekeeper)
        $SchemaCheck = Test-PrescribingSchema -Path $Path
        if (-not $SchemaCheck.IsValid) {
            Write-Error "Data Ingestion Aborted: $($SchemaCheck.Message)"
            return
        }

        # Step 2: Stream Processing
        $Reader = [System.IO.File]::OpenText($Path)
        try {
            # Capture headers and identify column positions (indices)
            $HeaderLine = $Reader.ReadLine()
            $Headers = $HeaderLine.Split(',') | ForEach-Object { $_.Trim('"') }

            $IdxYear     = [array]::IndexOf($Headers, 'YEAR_MONTH')
            $IdxPractice = [array]::IndexOf($Headers, 'PRACTICE_CODE')
            $IdxBNFName  = [array]::IndexOf($Headers, 'BNF_DESCRIPTION')
            $IdxItems    = [array]::IndexOf($Headers, 'ITEMS')
            $IdxActual   = [array]::IndexOf($Headers, 'ACTUAL_COST')

            # Loop through the file line-by-line
            while ($null -ne ($Line = $Reader.ReadLine())) {
                $Fields = $Line.Split(',') | ForEach-Object { $_.Trim('"') }

                # Data Cleaning & Calculation
                # Handling the trailing dot issue found in raw NHSBSA files
                $RawItems = $Fields[$IdxItems].Trim('.')
                $RawCost  = $Fields[$IdxActual].Trim('.')

                $Items      = if ([int]::TryParse($RawItems, [ref]0)) { [int]$RawItems } else { 0 }
                $ActualCost = if ([decimal]::TryParse($RawCost, [ref]0)) { [decimal]$RawCost } else { 0 }
                
                $CostPerItem = if ($Items -gt 0) { [math]::Round($ActualCost / $Items, 2) } else { 0 }

                # Emit the record to the pipeline immediately
                [PSCustomObject]@{
                    Period      = $Fields[$IdxYear]
                    Practice    = $Fields[$IdxPractice]
                    BNFName     = $Fields[$IdxBNFName]
                    Items       = $Items
                    TotalCost   = $ActualCost
                    CostPerItem = $CostPerItem
                    Status      = "Validated"
                }
            }
        }
        catch {
            Write-Error "Stream Error: $($_.Exception.Message)"
        }
        finally {
            # Critical: Always close the file handle
            $Reader.Close()
            $Reader.Dispose()
            Write-Verbose "Stream Reader closed successfully."
        }
    }
}