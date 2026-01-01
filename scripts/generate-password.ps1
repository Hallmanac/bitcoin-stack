# =============================================================================
# Generate Secure RPC Password (Windows PowerShell)
# =============================================================================
# Generates a 32-byte (64 character) hex password suitable for Bitcoin RPC
# =============================================================================

$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$Password = [BitConverter]::ToString($bytes) -replace '-', ''
$Password = $Password.ToLower()

Write-Host ""
Write-Host "Generated RPC Password:"
Write-Host "========================"
Write-Host $Password -ForegroundColor Cyan
Write-Host ""
Write-Host "Add this to your .env file:"
Write-Host "BITCOIN_RPC_PASS=$Password" -ForegroundColor Yellow
Write-Host ""
