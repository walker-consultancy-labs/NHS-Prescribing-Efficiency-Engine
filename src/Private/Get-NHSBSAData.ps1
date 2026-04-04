function Get-NHSBSAData {
    <#
    .SYNOPSIS
        Downloads a specific month of English Prescribing Data from the NHSBSA portal using BITS.
    .DESCRIPTION
        Uses Start-BitsTransfer for resilient, high-speed downloads with progress tracking.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$false)]
        [string]$OutPath = "./data/prescribing_raw.csv"
    )

    process {
        try {
            # Ensure the directory exists before starting the transfer
            $TargetDir = Split-Path $OutPath
            if (-not (Test-Path $TargetDir)) { 
                New-Item -ItemType Directory -Path $TargetDir | Out-Null 
            }

            Write-Host "Initialising BITS transfer from NHSBSA Portal..." -ForegroundColor Cyan
            
            # Start-BitsTransfer is preferred for large datasets over Invoke-WebRequest
            # It provides a native progress bar and handles network interruptions better
            Start-BitsTransfer -Source $Url -Destination $OutPath -ErrorAction Stop
            
            # Calculate file size for logging purposes
            $FileSizeMB = [math]::Round((Get-Item $OutPath).Length / 1MB, 2)
            Write-Host "Download Complete: $OutPath ($FileSizeMB MB)" -ForegroundColor Green
            
            return $OutPath
        }
        catch {
            # Error handling for network issues or file access problems
            Write-Error "Failed to download data via BITS: $($_.Exception.Message)"
        }
    }
}