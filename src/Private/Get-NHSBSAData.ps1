function Get-NHSBSAData {
    <#
    .SYNOPSIS
        Downloads a specific month of English Prescribing Data from the NHSBSA portal.
    .DESCRIPTION
        Uses Invoke-WebRequest with a browser User-Agent to bypass server-side 403 restrictions.
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
            # Ensure the directory exists
            $TargetDir = Split-Path $OutPath
            if (-not (Test-Path $TargetDir)) { 
                New-Item -ItemType Directory -Path $TargetDir | Out-Null 
            }

            Write-Host "Initialising download from NHSBSA Portal (Browser Emulation)..." -ForegroundColor Cyan
            
            # Use a standard UserAgent to avoid 403 Forbidden errors
            $UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            
            Invoke-WebRequest -Uri $Url -OutFile $OutPath -UserAgent $UserAgent -ErrorAction Stop
            
            $FileSizeMB = [math]::Round((Get-Item $OutPath).Length / 1MB, 2)
            Write-Host "Download Complete: $OutPath ($FileSizeMB MB)" -ForegroundColor Green
            
            return $OutPath
        }
        catch {
            Write-Error "Failed to download data: $($_.Exception.Message)"
        }
    }
}