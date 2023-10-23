#=========================
#Sets Hash Directory and Generates HardwareHash file
#=========================
$CSVPath = new-item -Path "c:\" -Name "hhash" -ItemType Directory -Force
$serialnumber = Get-WmiObject win32_bios | select Serialnumber
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Script -Name Get-WindowsAutoPilotInfo -Force
Set-ExecutionPolicy bypass -Force
Get-WindowsAutoPilotInfo -Outputfile $CSVPath\$($serialnumber.SerialNumber)-Hash.csv

#Hash File:
$file = Get-ChildItem -Path $CSVPath | Where-Object -Property Name -Like "*.csv"
$file = $file.FullName

$file = Import-Csv -Path $file
$serialNumber = $file.'Device Serial Number'
$Hash = $file.'Hardware Hash'

#Fix txt file
$serialNumber + "+" + $Hash | Out-File $CSVPath\$serialNumber.txt
$file = Get-ChildItem -Path $CSVPath | Where-Object -Property Name -Like "*.txt"
$file = $file.FullName
$file = Get-Content -Path $file

$pos = $file.IndexOf("+")
$leftPart = $file.Substring(0, $pos)
$rightPart = $file.Substring($pos+1)

# Set Device info
$deviceInfo = @{
   serialNumber = $leftPart
   hardwareIdentifier = $rightPart
 
}
$deviceInfo =  $deviceInfo | ConvertTo-Json

#Trigger Webhook
$uri = 'https://c12c6805-7e33-44ea-a095-2105f519a048.webhook.sec.azure-automation.net/webhooks?token=9%2bmk5MWdaCTP7S%2bIVwBNEtgp%2fqnvgwiS5B%2fCkJYXaFY%3d'
$body = $deviceInfo
$header = @{"Content-Type" = "application/json"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header
$jobid = (ConvertFrom-Json ($response.Content)).jobids[0]
