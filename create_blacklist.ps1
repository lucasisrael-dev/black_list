# Extract IpAddress field from Windows Security Log (Event ID 4625)
# and export to a file

# Set date-based filename
$today = Get-Date -Format "dd-MM-yyyy_hh-mm-ss"
#$outFile = "C:\Users\lucasisrael\Documents\scripts\logs\ips-$today.csv"

# Define the time range (last 24 hours)
$startTime = (Get-Date).AddHours(-1)

Write-Host "Searching last $MaxEventsToSearch Failed Logon events (ID 4625)..." -ForegroundColor Cyan

# Get all 4625 failed logon events
$events = Get-WinEvent -FilterHashtable @{ LogName = "Security"; Id = 4625; StartTime = $startTime } -ErrorAction Stop

# Parse each event and extract IpAddress from Event XML
$IpsParsed = foreach ($event in $events) {
    $xml = [xml]$event.ToXml()
    
    # Extract fields from EventData section
    $ip = $xml.Event.EventData.Data |
        Where-Object { $_.Name -eq "IpAddress" } |
        Select-Object -ExpandProperty '#text'
    
    # Output an object for CSV writing
    [PSCustomObject]@{
        IpAddress   = $ip
    }
}

# Extract only the IP address
$somenteIPs = $ipsFiltrado | Select-Object -ExpandProperty IpAddress

# Remove duplicates
$IpsParsed = $IpsParsed | Sort-Object -Unique

# Remove local IP
$IpsParsed = $IpsParsed | Where-Object {
    ($_ -notmatch '^::1$') -and
    ($_ -notmatch '^172\.') -and
    ($_ -notmatch '^168\.')
}

# Showing IPs that were found
Write-Host "IPs wehe found $IpsParsed"

# Location of file blacklist.txt
$BlacklistFile = "C:\Scripts\black_list\blacklist.txt"

# Read the file and junk with new IPs without duplicates
$Blacklist = Get-Content $BlacklistFile
$JunkedData = ($Blacklist + $IpsParsed) | Sort-Object -Unique

# Re-write blacklist file
$JunkedData | Set-Content $BlacklistFile

# Save results to CSV -- ununsed now
# $IpsParsed | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8

# Log end of script
Write-Host "Log export completed: $BlacklistFile"

Set-Location "C:\Scripts\black_list"

# Check if change
$Changes = git status --porcelain

if ($Changes) {
    git add .
    git commit -m "Commit automático via PowerShell - $today"
    Write-Host "Commit criado."
    git push
    Write-Host "Github atualizado. push"
} else {
    Write-Host "Nenhuma mudança para commitar."
}
