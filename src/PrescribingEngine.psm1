# -------------------------------------------------------------------------
# PrescribingEngine.psm1 - Module Orchestrator
# -------------------------------------------------------------------------

# Get the path to the current module directory
$PublicPath  = Join-Path $PSScriptRoot "Public"
$PrivatePath = Join-Path $PSScriptRoot "Private"

# Automatically load (dot-source) all Public functions
Get-ChildItem -Path $PublicPath -Filter *.ps1 -Recurse | ForEach-Object { . $_.FullName }

# Automatically load (dot-source) all Private functions
Get-ChildItem -Path $PrivatePath -Filter *.ps1 -Recurse | ForEach-Object { . $_.FullName }

# Export only the Public functions to the user
# (This ensures 'Private' helpers stay hidden)
Export-ModuleMember -Function "*"