#GetGroupTag
$title = "Intune Device Configuration Tool"
$titleNull = ""
$message1 = "What would you like to do?"
$message2 = "Assign user"
$message3 = "Custom Profile"

$Add = New-Object System.Management.Automation.Host.ChoiceDescription "&Add New Device", "Add a new device"
	
$Edit = New-Object System.Management.Automation.Host.ChoiceDescription "&Edit Existing Device", "Edit Existing Device"
	
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No, $null"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes, $null"

	
$options1 = [System.Management.Automation.Host.ChoiceDescription[]]($Add, $Edit)
$M1 = $host.ui.PromptForChoice($title, $message1, $options1, 0)
if($M1 -eq 0) {
   $Action = "Add"
}
if($M1 -eq 1) {
   $Action = "Edit"
}

$options2 = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
$M2 = $host.ui.PromptForChoice($titleNull, $message2, $options2, 0)
if($M2 -eq 0) {
   $assignedUser = $null
}
if($M2 -eq 1) {
   $assignedUser = Read-Host "Please Enter User Name followed by @ad.umu.se"
}

$options3 = [System.Management.Automation.Host.ChoiceDescription[]]($No, $Yes)
$M3 = $host.ui.PromptForChoice($titleNull, $message3, $options3, 0)
if($M3 -eq 0) {
   $GroupTag = $null
}
if($M3 -eq 1) {
   $GroupTag = Read-Host "Please Enter Profile name provided by ITS"
}

Write-Host "Running..." -ForegroundColor Blue
#Sets Hash Directory and Generates HardwareHash file
$CSVPath = new-item -Path "c:\" -Name "hhash" -ItemType Directory -Force
$serialnumber = Get-WmiObject win32_bios | select Serialnumber
Install-PackageProvider -Name "NuGet" -MinimumVersion 2.8.5.201 -Force | Out-Null
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
   GroupTag = $GroupTag
   Action = $Action
   User = $assignedUser
}
$deviceInfo =  $deviceInfo | ConvertTo-Json

Write-Host "Trigger Webhook..." -ForegroundColor Blue
#Trigger Webhook
$uri = 'https://c12c6805-7e33-44ea-a095-2105f519a048.webhook.sec.azure-automation.net/webhooks?token=ffkIpeCc0HJPHGX2PhEW7Az99MwjQrXkKLdae%2fV0xow%3d'
$body = $deviceInfo
$header = @{"Content-Type" = "application/json"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header
$jobid = (ConvertFrom-Json ($response.Content)).jobids[0]
Write-Host "JobID: $jobid" -ForegroundColor Yellow
Write-Host "
Triggerd Info : $deviceInfo" -ForegroundColor Green
Write-Host "
Task Completed." -ForegroundColor Blue


