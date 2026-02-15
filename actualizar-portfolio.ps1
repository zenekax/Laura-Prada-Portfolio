## ==========================================================
## ACTUALIZAR PORTFOLIO - Laura Prada
## ==========================================================
## Ejecutar este script despues de agregar o quitar fotos/videos
## de las carpetas en /portfolio/ y /videos/
##
## COMO AGREGAR UNA NUEVA SESION DE FOTOS:
## 1. Crear una carpeta nueva en /portfolio/ (ej: "07-mi-sesion")
## 2. Meter las fotos ahi (jpg, jpeg, png, webp)
## 3. Editar portfolio/config.json y agregar la entrada
## 4. Correr este script
##
## COMO AGREGAR VIDEOS:
## 1. Meter los videos en la carpeta correspondiente en /videos/
## 2. Formatos soportados: mp4, mov, webm
## 3. Correr este script
## ==========================================================

$outputJs = Join-Path $PSScriptRoot "portfolio-data.js"

## ============ FOTOS ============
$base = Join-Path $PSScriptRoot "portfolio"
$configPath = Join-Path $base "config.json"

if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: No se encontro config.json en $base" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

$manifest = @{}

foreach ($session in $config.sessions) {
    $folderPath = Join-Path $base $session.folder
    if (Test-Path $folderPath) {
        $files = Get-ChildItem -Path (Join-Path $folderPath "*") -File -Include "*.jpg","*.jpeg","*.png","*.webp" |
                 Sort-Object Name |
                 ForEach-Object { $_.Name }
        if ($files) {
            $manifest[$session.folder] = @($files)
        } else {
            $manifest[$session.folder] = @()
        }
    } else {
        Write-Host "ADVERTENCIA: Carpeta de fotos no encontrada: $folderPath" -ForegroundColor Yellow
        $manifest[$session.folder] = @()
    }
}

## ============ VIDEOS ============
$videosBase = Join-Path $PSScriptRoot "videos"
$videosConfigPath = Join-Path $videosBase "config.json"

$videosConfig = $null
$videosManifest = @{}

if (Test-Path $videosConfigPath) {
    $videosConfig = Get-Content $videosConfigPath -Raw | ConvertFrom-Json

    foreach ($session in $videosConfig.sessions) {
        $folderPath = Join-Path $videosBase $session.folder
        if (Test-Path $folderPath) {
            $files = Get-ChildItem -Path (Join-Path $folderPath "*") -File -Include "*.mp4","*.mov","*.webm" |
                     Sort-Object Name |
                     ForEach-Object { $_.Name }
            if ($files) {
                $videosManifest[$session.folder] = @($files)
            } else {
                $videosManifest[$session.folder] = @()
            }
        } else {
            Write-Host "ADVERTENCIA: Carpeta de videos no encontrada: $folderPath" -ForegroundColor Yellow
            $videosManifest[$session.folder] = @()
        }
    }
} else {
    Write-Host "ADVERTENCIA: No se encontro videos/config.json" -ForegroundColor Yellow
}

## ============ LOGOS / MARCAS ============
$logosBase = Join-Path $PSScriptRoot "Logos"
$logoFiles = @()

if (Test-Path $logosBase) {
    $logoFiles = Get-ChildItem -Path (Join-Path $logosBase "*") -File -Include "*.png","*.jpg","*.jpeg","*.svg","*.webp" |
                 Sort-Object Name |
                 ForEach-Object { $_.Name }
    if (-not $logoFiles) { $logoFiles = @() }
} else {
    Write-Host "ADVERTENCIA: Carpeta Logos no encontrada" -ForegroundColor Yellow
}

## ============ GENERAR JS ============
$jsLines = @()
$jsLines += "// GENERADO AUTOMATICAMENTE por actualizar-portfolio.ps1"
$jsLines += "// Ultima actualizacion: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$jsLines += "// NO EDITAR MANUALMENTE - correr el script para actualizar"
$jsLines += ""

## Fotos config + files
$jsLines += "const PORTFOLIO_CONFIG = $($config | ConvertTo-Json -Depth 5 -Compress);"
$jsLines += ""
$jsLines += "const PORTFOLIO_FILES = {"

$sessionIndex = 0
foreach ($session in $config.sessions) {
    $folder = $session.folder
    $files = $manifest[$folder]
    $filesJson = ($files | ForEach-Object { """$_""" }) -join ", "
    $comma = if ($sessionIndex -lt $config.sessions.Count - 1) { "," } else { "" }
    $jsLines += "  ""$folder"": [$filesJson]$comma"
    $sessionIndex++
}
$jsLines += "};"
$jsLines += ""

## Videos config + files
if ($videosConfig) {
    $jsLines += "const VIDEOS_CONFIG = $($videosConfig | ConvertTo-Json -Depth 5 -Compress);"
    $jsLines += ""
    $jsLines += "const VIDEOS_FILES = {"

    $sessionIndex = 0
    foreach ($session in $videosConfig.sessions) {
        $folder = $session.folder
        $files = $videosManifest[$folder]
        $filesJson = ($files | ForEach-Object { """$_""" }) -join ", "
        $comma = if ($sessionIndex -lt $videosConfig.sessions.Count - 1) { "," } else { "" }
        $jsLines += "  ""$folder"": [$filesJson]$comma"
        $sessionIndex++
    }
    $jsLines += "};"
} else {
    $jsLines += "const VIDEOS_CONFIG = {sessions:[]};"
    $jsLines += "const VIDEOS_FILES = {};"
}

$jsLines += ""

## Logos
$logosJson = ($logoFiles | ForEach-Object { """$_""" }) -join ", "
$jsLines += "const BRAND_LOGOS = [$logosJson];"

$jsContent = $jsLines -join "`n"
[System.IO.File]::WriteAllText($outputJs, $jsContent, [System.Text.Encoding]::UTF8)

## ============ RESUMEN ============
Write-Host ""
Write-Host "Portfolio actualizado!" -ForegroundColor Green
Write-Host "Archivo generado: $outputJs"
Write-Host ""
Write-Host "=== FOTOS ===" -ForegroundColor White
foreach ($session in $config.sessions) {
    $count = $manifest[$session.folder].Count
    Write-Host "  $($session.folder)  ->  $count fotos  ($($session.title))" -ForegroundColor Cyan
}
Write-Host ""
if ($videosConfig) {
    Write-Host "=== VIDEOS ===" -ForegroundColor White
    foreach ($session in $videosConfig.sessions) {
        $count = $videosManifest[$session.folder].Count
        Write-Host "  $($session.folder)  ->  $count videos  ($($session.title))" -ForegroundColor Magenta
    }
    Write-Host ""
}
Write-Host "=== LOGOS ===" -ForegroundColor White
Write-Host "  $($logoFiles.Count) logos encontrados en /Logos/" -ForegroundColor Yellow
Write-Host ""
Write-Host "Ahora podes abrir index.html en el navegador." -ForegroundColor Green
