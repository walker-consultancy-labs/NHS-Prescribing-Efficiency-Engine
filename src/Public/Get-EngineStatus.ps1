function Get-EngineStatus {
    <#
    .SYNOPSIS
        Returns the current operational status of hte Prescribing Engine.
    .DESCRIPTION
        A public-facing function used to verify module loading and environment health.
    #>
    [CmdLetBinding()]
    param()

    process {
        # Deternun the OS in a way that works on all PowerShell versoins
        $OSName = if ($IsLinux) { "Linux" } else { "Windows" }

        # Create a customer object to return structured data
        $Status = [PSCustomObject]@{
            EngineName = "NHS-Prescribing-Efficiency-Engine"
            Version = "0.0.1"
            Timestamp = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            Status = "Online"
            Environment = $OSName
        }

        return $Status
    }
}