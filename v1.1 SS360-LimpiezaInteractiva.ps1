# SS360-LimpiezaInteractiva.ps1
# Ejecutar como Administrador

# ==== PASO 1: SETUP ====
$logFile = "$env:TEMP\SS360-limpieza-log.txt"
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$execHeader = "========= EJECUCIÓN: $timestamp ========="
if (Test-Path $logFile) { Remove-Item $logFile -Force }
Add-Content -Path $logFile -Value "`n$execHeader"
Write-Host "`n$execHeader" -ForegroundColor Cyan

# ==== ASCII HEADER ====
$asciiHeader = @"
      SSSS   SSSS
     SS  SS SS  SS
     SS     SS
      SSSS   SSSS
         SS     SS
     SS  SS SS  SS
      SSSS   SSSS

     333   666   000
    3   3 6     0   0
        3 6     0   0
      333  666  0   0
        3 6   6 0   0
    3   3 6   6 0   0
     333   666   000

Automatización | Ciberseguridad | Desarrollo
"@

function Show-Screen {
    param ([string]$stepContent)
    Clear-Host
    Write-Host ""
    Write-Host $asciiHeader -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkGray
    Write-Host "Ciberseguridad para todos: https://ss360.co/elearn" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "=== EJECUCIÓN: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host $stepContent -ForegroundColor Gray
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor DarkGray
    Write-Host " Soporte: https://ss360.co/ayuda" -ForegroundColor Cyan
    Write-Host " Contacto: +57 300 787 3211" -ForegroundColor Cyan
    Write-Host " LinkedIn: https://linkedin.com/company/ss360sas/" -ForegroundColor Cyan
    Write-Host " IG: https://instagram.com/ss360_2.0" -ForegroundColor Cyan
    Write-Host " YouTube: https://youtube.com/@Seguridad_Sincronizada_360" -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor DarkGray
}

# ==== VARIABLES ====
$indexedList = @()
$index = 1
$deletedCount = 0
$retainedCount = 0
$errorsCount = 0
$protectedApps = @()

# ==== PASO 2: ESCANEAR UWP ====
Show-Screen -stepContent " Paso 2: Escaneando aplicaciones UWP no esenciales..."
$foundApps = Get-AppxPackage -AllUsers | Where-Object {
    $_.Name -notmatch "^Microsoft.Windows.(ShellExperienceHost|StartMenuExperienceHost|Calculator|StorePurchaseApp|WindowsStore|SecureAssessmentBrowser|VCLibs)"
}

foreach ($app in $foundApps) {
    if ($app.NonRemovable) {
        # Verificar si es un paquete provisionado
        $prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app.Name }
        if ($prov) {
            try {
                Write-Host "Intentando eliminar paquete provisionado (para nuevos usuarios): $($app.Name)" -ForegroundColor Yellow
                "🔁 Intentando eliminar provisionado: $($app.Name)" | Out-File -FilePath $logFile -Append

                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop
                "✅ ProvisionedPackage eliminado: $($app.Name)" | Out-File -FilePath $logFile -Append
            } catch {
                "❌ Error eliminando provisionado $($app.Name): $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
            }
        } else {
            "⚠️ Protegido y no provisionado: $($app.Name)" | Out-File -FilePath $logFile -Append
        }
        $protectedApps += $app
    } else {
        $indexedList += [PSCustomObject]@{
            Index = $index++
            Type = "UWP"
            Name = $app.Name
            Identifier = $app.PackageFullName
        }
    }
}

$userInput = Read-Host "Presiona ENTER para continuar o Q para salir"
if ($userInput.ToLower() -eq "q") { exit }

# ==== PASO 3: CLAVES INICIO ====
Show-Screen -stepContent " Paso 3: Verificando claves de inicio automático..."
try { $foundHKCU = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" } catch { $foundHKCU = @{} }
try { $foundHKLM = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" } catch { $foundHKLM = @{} }

foreach ($name in $foundHKCU.PSObject.Properties.Name) {
    $indexedList += [PSCustomObject]@{
        Index = $index++
        Type = "Startup_HKCU"
        Name = $name
        Identifier = "HKCU:\...\$name"
    }
}
foreach ($name in $foundHKLM.PSObject.Properties.Name) {
    $indexedList += [PSCustomObject]@{
        Index = $index++
        Type = "Startup_HKLM"
        Name = $name
        Identifier = "HKLM:\...\$name"
    }
}
$userInput = Read-Host "Presiona ENTER para continuar o Q para salir"
if ($userInput.ToLower() -eq "q") { exit }

# ==== PASO 4: LISTAR Y SELECCIONAR ====
if ($indexedList.Count -eq 0) {
    Show-Screen -stepContent "No se encontraron elementos eliminables. Solo hay protegidos o vacíos."
    Read-Host "Presiona ENTER para salir"
    exit
}
Show-Screen -stepContent "Paso 4: Elementos disponibles para eliminar:`n`n$($indexedList | ForEach-Object { "$($_.Index): [$($_.Type)] $($_.Name)" } | Out-String)"

Write-Host "`nOpciones:"
Write-Host " - Ingresa los números separados por coma (ej: 1,3,5)"
Write-Host " - Ingresa A para eliminar todos"
Write-Host " - Ingresa N para no eliminar nada"

$selection = Read-Host "`n¿Qué deseas eliminar?"
if ($selection -eq "A") {
    $indicesToRemove = $indexedList.Index
} elseif ($selection -eq "N") {
    $indicesToRemove = @()
} else {
    $indicesToRemove = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
}
$userInput = Read-Host "Presiona ENTER para continuar o Q para salir"
if ($userInput.ToLower() -eq "q") { exit }

# ==== PASO 5: MATAR PROCESOS ====
Show-Screen -stepContent " Paso 5: Finalizando procesos asociados..."
function Stop-AssociatedProcesses {
    param ($selectedItems)
    $processesToKill = $selectedItems |
        Where-Object { $_.Type -eq "UWP" } |
        ForEach-Object { $_.Name -replace "Microsoft.", "" } |
        Select-Object -Unique

    foreach ($procName in $processesToKill) {
        try {
            $processes = Get-Process | Where-Object { $_.Name -like "*$procName*" }
            foreach ($proc in $processes) {
                Write-Host "Finalizando proceso asociado: $($proc.Name)" -ForegroundColor Magenta
                "Finalizando proceso asociado: $($proc.Name)" | Out-File -FilePath $logFile -Append
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            }
        } catch {
            "❌ Error finalizando ${procName}: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
        }
    }
}
$selectedItems = $indexedList | Where-Object { $indicesToRemove -contains $_.Index.ToString() }
Stop-AssociatedProcesses -selectedItems $selectedItems
$userInput = Read-Host "Presiona ENTER para continuar o Q para salir"
if ($userInput.ToLower() -eq "q") { exit }

# ==== PASO 6: ELIMINAR ELEMENTOS ====
Show-Screen -stepContent " Paso 6: Ejecutando limpieza..."
foreach ($item in $indexedList) {
    if ($indicesToRemove -contains $item.Index.ToString()) {
        try {
            switch ($item.Type) {
                "UWP" {
                    Write-Host "Eliminando app: $($item.Name)" -ForegroundColor Red
                    "Eliminando app: $($item.Name)" | Out-File -FilePath $logFile -Append
                    Remove-AppxPackage -Package $item.Identifier -AllUsers -ErrorAction Stop
                }
                "Startup_HKCU" {
                    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $item.Name -Force -ErrorAction Stop
                }
                "Startup_HKLM" {
                    Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $item.Name -Force -ErrorAction Stop
                }
            }
            $deletedCount++
        } catch {
            $errMsg = "❌ Error eliminando $($item.Type): $($item.Name) - $($_.Exception.Message)"
            Write-Host $errMsg -ForegroundColor Red
            $errMsg | Out-File -FilePath $logFile -Append
            $errorsCount++
        }
    } else {
        "Conservado: [$($item.Type)] $($item.Name)" | Out-File -FilePath $logFile -Append
        $retainedCount++
    }
}
$userInput = Read-Host "Presiona ENTER para continuar o Q para salir"
if ($userInput.ToLower() -eq "q") { exit }

# ==== PASO 7: RESUMEN FINAL ====
$summary = @"
----------------------------
Resumen de limpieza:
 - Eliminados: $deletedCount
 - Conservados: $retainedCount
 - Errores: $errorsCount
 - UWP protegidas no removibles: $($protectedApps.Count)
----------------------------
"@
Show-Screen -stepContent $summary

if ($errorsCount -gt 0) {
    Write-Host "`nErrores detectados:" -ForegroundColor Red
    Get-Content $logFile | Select-String "❌" | ForEach-Object { Write-Host $_.Line -ForegroundColor DarkRed }
}

Write-Host "`nLimpieza completada. Revisa el log en: $logFile" -ForegroundColor Green

# ==== PASO 8: REINICIO ====
do {
    $exit = Read-Host "`nPresiona ENTER para volver a ejecutar o Q para salir"
    if ($exit -eq "") {
        powershell.exe -ExecutionPolicy Bypass -File "$PSCommandPath"
        exit
    }
} while ($exit.ToLower() -ne "q")
