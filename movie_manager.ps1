# ============================================================
#  Movie Manager Pro - All-in-One Media Folder Toolkit
#  Supports both Movies and TV Series
#  Combines folder renaming + poster icon setting
#  with an interactive menu system
# ============================================================

Add-Type -AssemblyName System.Drawing

# ---- CONFIG FILE for persisted settings (API key etc.) ----
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "movie_manager_config.json"


# ============================================================
#  UTILITY FUNCTIONS
# ============================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "    ##   ##   ####   ##   ##  ##  #####                           " -ForegroundColor Cyan
    Write-Host "    ### ###  ##  ##  ##   ##  ##  ##                              " -ForegroundColor Cyan
    Write-Host "    ## # ##  ##  ##  ##   ##  ##  ####                            " -ForegroundColor Cyan
    Write-Host "    ##   ##  ##  ##   ## ##   ##  ##                              " -ForegroundColor Cyan
    Write-Host "    ##   ##   ####     ###    ##  #####                           " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    ##   ##    ###    ##   ##    ###     ####   #####  ####       " -ForegroundColor DarkCyan
    Write-Host "    ### ###   ## ##   ###  ##   ## ##   ##      ##     ##  ##     " -ForegroundColor DarkCyan
    Write-Host "    ## # ##  ##   ##  ## # ##  ##   ##  ## ###  ####   ####       " -ForegroundColor DarkCyan
    Write-Host "    ##   ##  #######  ##  ###  #######  ##  ##  ##     ## ##      " -ForegroundColor DarkCyan
    Write-Host "    ##   ##  ##   ##  ##   ##  ##   ##   ####   #####  ##  ##     " -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "                           P R O                                 " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-MainMenu {
    Write-Host "  .---------------------------------------------------------."-ForegroundColor DarkGray
    Write-Host "  |                                                         |" -ForegroundColor DarkGray
    Write-Host "  |   " -NoNewline -ForegroundColor DarkGray
    Write-Host "[1]" -NoNewline -ForegroundColor Yellow
    Write-Host "  Folder Renamer" -NoNewline -ForegroundColor White
    Write-Host "                                  |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Clean up messy folder names to Title Year" -NoNewline -ForegroundColor DarkGray
    Write-Host "      |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Move loose files into their own folders" -NoNewline -ForegroundColor DarkGray
    Write-Host "        |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Works for Movies & TV Series" -NoNewline -ForegroundColor DarkGray
    Write-Host "                |" -ForegroundColor DarkGray

    Write-Host "  |                                                         |" -ForegroundColor DarkGray
    Write-Host "  |   " -NoNewline -ForegroundColor DarkGray
    Write-Host "[2]" -NoNewline -ForegroundColor Yellow
    Write-Host "  Poster Icon Setter" -NoNewline -ForegroundColor White
    Write-Host "                              |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Fetch posters from TMDb (Movies & TV)" -NoNewline -ForegroundColor DarkGray
    Write-Host "      |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Set them as custom folder icons" -NoNewline -ForegroundColor DarkGray
    Write-Host "              |" -ForegroundColor DarkGray

    Write-Host "  |                                                         |" -ForegroundColor DarkGray
    Write-Host "  |   " -NoNewline -ForegroundColor DarkGray
    Write-Host "[3]" -NoNewline -ForegroundColor Yellow
    Write-Host "  Full Auto" -NoNewline -ForegroundColor White
    Write-Host " (Rename + Set Icons)" -NoNewline -ForegroundColor DarkGray
    Write-Host "               |" -ForegroundColor DarkGray

    Write-Host "  |        " -NoNewline -ForegroundColor DarkGray
    Write-Host "Run both tools in sequence" -NoNewline -ForegroundColor DarkGray
    Write-Host "                    |" -ForegroundColor DarkGray

    Write-Host "  |                                                         |" -ForegroundColor DarkGray
    Write-Host "  |   " -NoNewline -ForegroundColor DarkGray
    Write-Host "[0]" -NoNewline -ForegroundColor Red
    Write-Host "  Exit" -NoNewline -ForegroundColor White
    Write-Host "                                          |" -ForegroundColor DarkGray

    Write-Host "  |                                                         |" -ForegroundColor DarkGray
    Write-Host "  '---------------------------------------------------------'" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-ContentTypeMenu {
    Write-Host "  What type of content is in this folder?" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] " -NoNewline -ForegroundColor Yellow
    Write-Host "Movies" -ForegroundColor White
    Write-Host "    [2] " -NoNewline -ForegroundColor Yellow
    Write-Host "TV Series" -ForegroundColor White
    Write-Host ""
    Write-Host "  > " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    switch ($choice.Trim()) {
        '1' { return 'movie' }
        '2' { return 'tv' }
        default {
            Write-Host "  Invalid choice, defaulting to Movies." -ForegroundColor Yellow
            return 'movie'
        }
    }
}

function Show-Divider {
    Write-Host ""
    Write-Host "  ---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-ToolHeader {
    param([string]$Title, [string]$Icon)
    Write-Host ""
    Write-Host "  =========================================================" -ForegroundColor DarkCyan
    Write-Host "    $Icon  $Title" -ForegroundColor Cyan
    Write-Host "  =========================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Success {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [OK] $Message" -ForegroundColor Green
    Write-Host ""
}

function Show-Error {
    param([string]$Message)
    Write-Host ""
    Write-Host "  [!!] $Message" -ForegroundColor Red
    Write-Host ""
}

function Show-Warning {
    param([string]$Message)
    Write-Host "  [!] $Message" -ForegroundColor Yellow
}

function Pause-BeforeMenu {
    Write-Host ""
    Write-Host "  Press any key to return to the main menu..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


# ---- Ask user for a folder path (supports drag & drop) ----
function Get-FolderPath {
    Write-Host "  Enter the folder path " -NoNewline -ForegroundColor White
    Write-Host "(or drag & drop a folder here):" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  > " -NoNewline -ForegroundColor Yellow
    $path = Read-Host

    # Clean up: remove surrounding quotes from drag-and-drop
    $path = $path.Trim().Trim('"').Trim("'")

    if ([string]::IsNullOrWhiteSpace($path)) {
        Show-Error "No path entered."
        return $null
    }
    if (-not (Test-Path -LiteralPath $path)) {
        Show-Error "Path does not exist: $path"
        return $null
    }
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Show-Error "Path is not a folder: $path"
        return $null
    }

    return $path
}


# ---- Load / Save config ----
function Load-Config {
    if (Test-Path $ConfigFile) {
        try {
            return (Get-Content $ConfigFile -Raw | ConvertFrom-Json)
        }
        catch { return @{} }
    }
    return @{}
}

function Save-Config {
    param($Config)
    $Config | ConvertTo-Json | Set-Content $ConfigFile -Force
}


# ---- Get or ask for TMDb API key ----
function Get-TMDbToken {
    $config = Load-Config

    if ($config.TMDbToken -and $config.TMDbToken.Length -gt 10) {
        $masked = $config.TMDbToken.Substring(0, 20) + "..." + $config.TMDbToken.Substring($config.TMDbToken.Length - 10)
        Write-Host "  Saved API token found: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$masked" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Use saved token? " -NoNewline -ForegroundColor White
        Write-Host "[Y/n]: " -NoNewline -ForegroundColor Yellow
        $answer = Read-Host
        if ($answer -eq '' -or $answer -match '^[Yy]') {
            return $config.TMDbToken
        }
    }

    Write-Host ""
    Write-Host "  Enter your TMDb API Read Access Token:" -ForegroundColor White
    Write-Host "  (Get one free at: " -NoNewline -ForegroundColor DarkGray
    Write-Host "https://www.themoviedb.org/settings/api" -NoNewline -ForegroundColor Cyan
    Write-Host ")" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  > " -NoNewline -ForegroundColor Yellow
    $token = Read-Host

    $token = $token.Trim()
    if ([string]::IsNullOrWhiteSpace($token)) {
        Show-Error "No token entered."
        return $null
    }

    $config = Load-Config
    if ($config -is [PSCustomObject]) {
        $config | Add-Member -NotePropertyName "TMDbToken" -NotePropertyValue $token -Force
    }
    else {
        $config = @{ TMDbToken = $token }
    }
    Save-Config -Config $config
    Show-Success "API token saved! You won't need to enter it again."

    return $token
}


# ============================================================
#  TOOL 1: FOLDER RENAMER
# ============================================================

$VideoExtensions = @('.mkv', '.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.ts', '.mpg', '.mpeg')
$ArchiveExtensions = @('.zip', '.rar', '.7z')

# Technical keywords that signal the end of a title
$global:CutoffKeywords = @(
    '1080p', '2160p', '720p', '480p', '4K',
    'BluRay', 'Blu-Ray', 'BRRip', 'BDRip', 'WEBRip', 'WEB-DL', 'WEB DL', 'WEBDL', 'WEBDL',
    'HDRip', 'DVDRip', 'HDTV', 'PDTV', 'CAM',
    'UPSCALE', 'REMASTERED', 'UNRATED', 'EXTENDED', 'DIRECTORS CUT',
    'x264', 'x265', 'H 264', 'H 265', 'HEVC', 'AVC',
    'AAC', 'AC3', 'AC3D', 'DD5 1', 'DDP5 1', 'DTS', 'FLAC', 'Atmos',
    'MULTI', 'DUAL', 'REMUX', 'HDR', 'HDR10',
    'SDR', 'UHD',
    'German', 'French', 'Italian', 'Spanish', 'Hindi', 'Tamil',
    'iTA', 'EnG', 'Jap',
    'Sub', 'Subs',
    '10bit', '8bit',
    'Tigole', 'BONE', 'YTS', 'RARBG', 'MIRCrew', 'toto', 'OldT',
    'realDMDJ', 'Ospreay', 'TiGER', 'RDNYB',
    'Free Download', 'Borrow', 'Streaming', 'Internet Archive',
    'Ben The Men'
)

# Well-known website names to strip from folder names
# Patterns with dots (match BEFORE dot-to-space conversion)
$global:WebsitePatternsWithDots = @(
    'MkvDrama\.net', 'YTS\.MX', 'YTS\.BZ', 'YTS\.AM', 'pahe\.in'
)
# Patterns without dots (match AFTER dot-to-space conversion)
$global:WebsitePatterns = @(
    'MkvDrama\s*net', 'MkvDrama', 'YTS\s*MX', 'YTS\s*BZ', 'YTS\s*AM',
    'RARBG', 'EZTV', 'TorrentGalaxy', 'PSA', 'GalaxyTV',
    'pahe\s*in', 'pahe', 'Dramacool',
    'KissAsian', 'AsianWiki', 'MyDramaList', 'VIU', 'Viki'
)

function Get-CleanName {
    param(
        [string]$RawName,
        [bool]$IsFile = $false,
        [string]$ContentType = 'movie'  # 'movie' or 'tv'
    )

    if ($IsFile) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($RawName)
    }
    else {
        $name = $RawName
    }

    # Remove website names WITH dots BEFORE dot-to-space conversion
    foreach ($wp in $global:WebsitePatternsWithDots) {
        $name = $name -replace "[-\s]*$wp[-\s]*", ' '
    }

    # Replace dots and underscores with spaces
    $name = $name -replace '[._]', ' '

    # Remove website names (space-separated variants)
    foreach ($wp in $global:WebsitePatterns) {
        $name = $name -replace "[-\s]*$wp[-\s]*", ' '
    }

    # For TV series: remove season/episode tags like S01E01, S01-S04, Season 1, etc.
    if ($ContentType -eq 'tv') {
        # Remove patterns like S01E01, S01E01E02, S01-S04
        $name = $name -replace '\bS\d{1,2}E\d{1,2}(E\d{1,2})*\b', ''
        $name = $name -replace '\bS\d{1,2}\s*-\s*S\d{1,2}\b', ''
        $name = $name -replace '\bS\d{1,2}\b', ''
        $name = $name -replace '\bSeason\s*\d+\b', ''
        $name = $name -replace '\bEpisode\s*\d+\b', ''
        $name = $name -replace '\bComplete\s*Series\b', ''
        $name = $name -replace '\bComplete\b', ''
    }

    # Try to extract year (4-digit number between 1900-2099)
    $yearMatch = [regex]::Match($name, '\b((?:19|20)\d{2})\b')

    $year = $null
    $titlePart = $name

    if ($yearMatch.Success) {
        $year = $yearMatch.Value
        $titlePart = $name.Substring(0, $yearMatch.Index).Trim()
    }
    else {
        # No year found - cut at earliest technical keyword
        $earliestCut = $name.Length
        foreach ($kw in $global:CutoffKeywords) {
            $escaped = [regex]::Escape($kw)
            $pattern = "\b$escaped\b"
            $kwMatch = [regex]::Match($name, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($kwMatch.Success -and $kwMatch.Index -lt $earliestCut -and $kwMatch.Index -gt 0) {
                $earliestCut = $kwMatch.Index
            }
        }
        if ($earliestCut -lt $name.Length) {
            $titlePart = $name.Substring(0, $earliestCut).Trim()
        }
    }

    # Clean up extra spaces, trailing hyphens/brackets
    $titlePart = $titlePart -replace '\s+', ' '
    $titlePart = $titlePart -replace '[\-\[\]\(\),]+$', ''
    $titlePart = $titlePart.Trim(' ', '-', '[', ']', '(', ')', ',')

    if ($year) {
        $result = "$titlePart $year"
    }
    else {
        $result = $titlePart
    }

    return $result.Trim()
}


function Run-FolderRenamer {
    param(
        [string]$TargetPath,
        [string]$ContentType = 'movie'
    )

    $label = if ($ContentType -eq 'tv') { 'TV SERIES' } else { 'MOVIES' }

    Show-ToolHeader -Title "FOLDER RENAMER ($label)" -Icon "[1]"
    Write-Host "  Target: $TargetPath" -ForegroundColor White
    Show-Divider

    # ---- STEP 1: Move loose files into folders ----
    Write-Host "  STEP 1: Organizing loose files into folders" -ForegroundColor Cyan
    Write-Host ""

    $allLooseFiles = Get-ChildItem -Path $TargetPath -File | Where-Object {
        ($VideoExtensions -contains $_.Extension.ToLower()) -or
        ($ArchiveExtensions -contains $_.Extension.ToLower())
    }

    $movedCount = 0
    if ($allLooseFiles.Count -eq 0) {
        Write-Host "    No loose files found." -ForegroundColor DarkGray
    }
    else {
        foreach ($file in $allLooseFiles) {
            $cleanName = Get-CleanName -RawName $file.Name -IsFile $true -ContentType $ContentType
            $newFolderPath = Join-Path $TargetPath $cleanName

            Write-Host "    FILE: " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($file.Name)" -ForegroundColor DarkYellow
            Write-Host "      -> " -NoNewline -ForegroundColor DarkGray
            Write-Host "$cleanName/" -ForegroundColor Green

            if (-not (Test-Path $newFolderPath)) {
                New-Item -ItemType Directory -Path $newFolderPath | Out-Null
            }
            Move-Item -LiteralPath $file.FullName -Destination $newFolderPath -Force
            $movedCount++
        }
    }

    Show-Divider

    # ---- STEP 2: Rename folders ----
    Write-Host "  STEP 2: Cleaning up folder names" -ForegroundColor Cyan
    Write-Host ""

    $folders = Get-ChildItem -Path $TargetPath -Directory
    $renamedCount = 0
    $skippedCount = 0

    foreach ($folder in $folders) {
        $cleanName = Get-CleanName -RawName $folder.Name -IsFile $false -ContentType $ContentType

        if ($folder.Name -eq $cleanName) {
            $skippedCount++
            continue
        }

        if ([string]::IsNullOrWhiteSpace($cleanName) -or $cleanName.Length -lt 2) {
            Write-Host "    SKIP: " -NoNewline -ForegroundColor Red
            Write-Host "$($folder.Name) (could not parse)" -ForegroundColor Red
            continue
        }

        Write-Host "    RENAME: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($folder.Name)" -ForegroundColor DarkYellow
        Write-Host "        ->  " -NoNewline -ForegroundColor DarkGray
        Write-Host "$cleanName" -ForegroundColor Green

        $newPath = Join-Path $TargetPath $cleanName

        if (Test-Path $newPath) {
            $items = Get-ChildItem -LiteralPath $folder.FullName
            foreach ($item in $items) {
                Move-Item -LiteralPath $item.FullName -Destination $newPath -Force
            }
            Remove-Item -LiteralPath $folder.FullName -Force -Recurse
        }
        else {
            try {
                Rename-Item -LiteralPath $folder.FullName -NewName $cleanName -ErrorAction Stop
            }
            catch {
                Show-Warning "Could not rename '$($folder.Name)': $($_.Exception.Message)"
                continue
            }
        }
        $renamedCount++
    }

    # ---- Summary ----
    Show-Divider
    Write-Host "  RESULTS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Files organized:    $movedCount" -ForegroundColor $(if ($movedCount -gt 0) { 'Green' } else { 'DarkGray' })
    Write-Host "    Folders renamed:    $renamedCount" -ForegroundColor $(if ($renamedCount -gt 0) { 'Green' } else { 'DarkGray' })
    Write-Host "    Already clean:      $skippedCount" -ForegroundColor DarkGray
    Show-Divider
    Show-Success "Folder renaming complete!"
}


# ============================================================
#  TOOL 2: POSTER ICON SETTER
# ============================================================

function Search-TMDb {
    param(
        [string]$Title,
        [string]$Year,
        [string]$ContentType,  # 'movie' or 'tv'
        [hashtable]$Headers
    )

    $encodedTitle = [System.Uri]::EscapeDataString($Title)
    $endpoint = if ($ContentType -eq 'tv') { 'tv' } else { 'movie' }
    $yearParam = if ($ContentType -eq 'tv') { 'first_air_date_year' } else { 'primary_release_year' }
    $yearParamLoose = if ($ContentType -eq 'tv') { 'first_air_date_year' } else { 'year' }

    # Try 1: strict year match
    if ($Year) {
        $url = "https://api.themoviedb.org/3/search/$endpoint`?query=$encodedTitle&$yearParam=$Year"
        try {
            $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
            if ($response.results -and $response.results.Count -gt 0) {
                return $response.results[0]
            }
        }
        catch {
            Write-Host "      API ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }

        # Try 2: looser year match
        if ($yearParamLoose -ne $yearParam) {
            $url = "https://api.themoviedb.org/3/search/$endpoint`?query=$encodedTitle&$yearParamLoose=$Year"
            try {
                $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
                if ($response.results -and $response.results.Count -gt 0) {
                    foreach ($result in $response.results) {
                        $releaseDate = if ($ContentType -eq 'tv') { $result.first_air_date } else { $result.release_date }
                        if ($releaseDate -and $releaseDate.StartsWith($Year)) {
                            return $result
                        }
                    }
                    return $response.results[0]
                }
            }
            catch {
                Write-Host "      API ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Try 3: search without year
    $url = "https://api.themoviedb.org/3/search/$endpoint`?query=$encodedTitle"
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
        if ($response.results -and $response.results.Count -gt 0) {
            if ($Year) {
                foreach ($result in $response.results) {
                    $releaseDate = if ($ContentType -eq 'tv') { $result.first_air_date } else { $result.release_date }
                    if ($releaseDate -and $releaseDate.StartsWith($Year)) {
                        return $result
                    }
                }
            }
            return $response.results[0]
        }
    }
    catch {
        Write-Host "      API ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Try 4: if TV not found, try multi-search as fallback
    if ($ContentType -eq 'tv') {
        $url = "https://api.themoviedb.org/3/search/multi?query=$encodedTitle"
        try {
            $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get -ErrorAction Stop
            if ($response.results -and $response.results.Count -gt 0) {
                # Prefer TV results
                foreach ($result in $response.results) {
                    if ($result.media_type -eq 'tv') {
                        return $result
                    }
                }
                return $response.results[0]
            }
        }
        catch {
            Write-Host "      API ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    return $null
}


function Convert-ToIcon {
    param(
        [string]$ImagePath,
        [string]$IconPath
    )

    try {
        $original = [System.Drawing.Image]::FromFile($ImagePath)
        $size = 256
        $resized = New-Object System.Drawing.Bitmap($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($resized)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.DrawImage($original, 0, 0, $size, $size)
        $graphics.Dispose()

        $pngStream = New-Object System.IO.MemoryStream
        $resized.Save($pngStream, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngBytes = $pngStream.ToArray()
        $pngStream.Dispose()

        $fs = [System.IO.File]::Create($IconPath)
        $writer = New-Object System.IO.BinaryWriter($fs)

        # ICO Header
        $writer.Write([uint16]0)      # Reserved
        $writer.Write([uint16]1)      # Type: ICO
        $writer.Write([uint16]1)      # Count: 1 image

        # ICO Directory Entry
        $writer.Write([byte]0)        # Width 0 = 256
        $writer.Write([byte]0)        # Height 0 = 256
        $writer.Write([byte]0)        # No palette
        $writer.Write([byte]0)        # Reserved
        $writer.Write([uint16]1)      # Color planes
        $writer.Write([uint16]32)     # Bits per pixel
        $writer.Write([uint32]$pngBytes.Length)  # Data size
        $writer.Write([uint32]22)     # Offset (6 + 16)

        # PNG data
        $writer.Write($pngBytes)

        $writer.Close()
        $fs.Close()
        $resized.Dispose()
        $original.Dispose()

        return $true
    }
    catch {
        Write-Host "      ICON ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}


function Set-FolderIcon {
    param(
        [string]$FolderPath,
        [string]$IconFileName
    )

    $desktopIniPath = Join-Path $FolderPath "desktop.ini"
    $iconFullPath = Join-Path $FolderPath $IconFileName

    if (Test-Path -LiteralPath $desktopIniPath) {
        $existingFile = Get-Item -LiteralPath $desktopIniPath -Force
        $existingFile.Attributes = 'Normal'
        Remove-Item -LiteralPath $desktopIniPath -Force
    }

    $iniContent = @"
[.ShellClassInfo]
IconResource=$IconFileName,0
[ViewState]
Mode=
Vid=
FolderType=Generic
"@
    [System.IO.File]::WriteAllText($desktopIniPath, $iniContent, [System.Text.Encoding]::Unicode)

    $iniFile = Get-Item -LiteralPath $desktopIniPath -Force
    $iniFile.Attributes = 'Hidden, System'

    $icoFile = Get-Item -LiteralPath $iconFullPath -Force
    $icoFile.Attributes = 'Hidden'

    $folder = Get-Item -LiteralPath $FolderPath -Force
    $folder.Attributes = $folder.Attributes -bor [System.IO.FileAttributes]::System
}


function Parse-FolderName {
    param(
        [string]$FolderName,
        [string]$ContentType = 'movie'
    )

    $name = $FolderName

    # For TV: strip season/episode tags before parsing
    if ($ContentType -eq 'tv') {
        $name = $name -replace '\bS\d{1,2}E\d{1,2}(E\d{1,2})*\b', ''
        $name = $name -replace '\bS\d{1,2}\s*-\s*S\d{1,2}\b', ''
        $name = $name -replace '\bS\d{1,2}\b', ''
        $name = $name -replace '\bSeason\s*\d+\b', ''
    }

    # Strip known website names WITH dots before dot-to-space conversion
    foreach ($wp in $global:WebsitePatternsWithDots) {
        $name = $name -replace "[-\s]*$wp[-\s]*", ' '
    }

    $name = $name -replace '[._]', ' '

    # Strip remaining website name patterns (space-separated variants)
    foreach ($wp in $global:WebsitePatterns) {
        $name = $name -replace "[-\s]*$wp[-\s]*", ' '
    }

    # Remove technical keywords for search
    foreach ($kw in $global:CutoffKeywords) {
        $escaped = [regex]::Escape($kw)
        $name = $name -replace "\b$escaped\b", ''
    }
    $name = $name -replace '\s+', ' '
    $name = $name.Trim(' ', '-', '[', ']', '(', ')', ',')

    # Try to extract year
    $yearMatch = [regex]::Match($name, '\b((?:19|20)\d{2})\b')

    if ($yearMatch.Success) {
        $year = $yearMatch.Value
        $title = $name.Substring(0, $yearMatch.Index).Trim(' ', '-', '(', ')')
    }
    else {
        $year = $null
        $title = $name
    }

    $title = $title.Trim(' ', '-', '(', ')', '[', ']')

    return @{ Title = $title; Year = $year }
}


function Run-PosterIconSetter {
    param(
        [string]$TargetPath,
        [string]$ContentType = 'movie'
    )

    $label = if ($ContentType -eq 'tv') { 'TV SERIES' } else { 'MOVIES' }

    Show-ToolHeader -Title "POSTER ICON SETTER ($label)" -Icon "[2]"
    Write-Host "  Target: $TargetPath" -ForegroundColor White
    Show-Divider

    # Get API token
    $token = Get-TMDbToken
    if (-not $token) {
        Show-Error "Cannot proceed without a TMDb API token."
        return
    }

    $headers = @{
        'Authorization' = "Bearer $token"
        'Accept'        = 'application/json'
    }
    $ImageBaseUrl = "https://image.tmdb.org/t/p/w500"
    $IconFileName = "folder.ico"

    # Validate token
    Write-Host "  Validating API token..." -ForegroundColor DarkGray
    try {
        $testUrl = "https://api.themoviedb.org/3/search/movie?query=test"
        $null = Invoke-RestMethod -Uri $testUrl -Headers $headers -Method Get -ErrorAction Stop
        Write-Host "  API token is valid!" -ForegroundColor Green
    }
    catch {
        Show-Error "API token is invalid or expired. Please try again."
        $config = Load-Config
        if ($config -is [PSCustomObject]) {
            $config | Add-Member -NotePropertyName "TMDbToken" -NotePropertyValue "" -Force
            Save-Config -Config $config
        }
        return
    }

    Show-Divider

    # Temp directory
    $tempDir = Join-Path $env:TEMP "movie_posters_temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }

    $folders = Get-ChildItem -Path $TargetPath -Directory
    $total = $folders.Count
    $current = 0
    $successCount = 0
    $skipCount = 0
    $failCount = 0

    Write-Host "  Found $total folders to process." -ForegroundColor White
    Write-Host ""

    foreach ($folder in $folders) {
        $current++
        $iconPath = Join-Path $folder.FullName $IconFileName

        # Progress bar
        $pct = [math]::Round(($current / $total) * 100)
        $barLen = 30
        $filled = [math]::Round($barLen * $current / $total)
        $empty = $barLen - $filled
        $bar = ("$([char]9608)" * $filled) + ("$([char]9617)" * $empty)
        Write-Host "`r  [$bar] $pct% ($current/$total) " -NoNewline -ForegroundColor DarkCyan

        Write-Host ""
        Write-Host "    $($folder.Name)" -ForegroundColor White

        # Skip if already has icon
        if (Test-Path -LiteralPath $iconPath) {
            Write-Host "      Already has icon. Skipping." -ForegroundColor DarkGray
            $skipCount++
            continue
        }

        # Parse folder name
        $parsed = Parse-FolderName -FolderName $folder.Name -ContentType $ContentType
        $searchTitle = $parsed.Title
        $searchYear = $parsed.Year

        # Get display name for the result
        $titleField = if ($ContentType -eq 'tv') { 'name' } else { 'title' }
        $dateField = if ($ContentType -eq 'tv') { 'first_air_date' } else { 'release_date' }

        Write-Host "      Searching: " -NoNewline -ForegroundColor DarkGray
        Write-Host "'$searchTitle'" -NoNewline -ForegroundColor Yellow
        if ($searchYear) { Write-Host " ($searchYear)" -ForegroundColor Yellow } else { Write-Host "" }

        # Search TMDb
        $result = Search-TMDb -Title $searchTitle -Year $searchYear -ContentType $ContentType -Headers $headers
        Start-Sleep -Milliseconds 300

        if (-not $result) {
            Write-Host "      Not found on TMDb." -ForegroundColor Red
            $failCount++
            continue
        }

        $displayName = if ($result.$titleField) { $result.$titleField } elseif ($result.title) { $result.title } elseif ($result.name) { $result.name } else { "Unknown" }
        $displayDate = if ($result.$dateField) { $result.$dateField } elseif ($result.release_date) { $result.release_date } elseif ($result.first_air_date) { $result.first_air_date } else { "?" }
        Write-Host "      Found: $displayName ($displayDate)" -ForegroundColor Green

        if (-not $result.poster_path) {
            Write-Host "      No poster available." -ForegroundColor Yellow
            $failCount++
            continue
        }

        # Download poster
        $posterUrl = "$ImageBaseUrl$($result.poster_path)"
        $tempImagePath = Join-Path $tempDir "$current.jpg"

        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($posterUrl, $tempImagePath)
            $webClient.Dispose()
        }
        catch {
            Write-Host "      Download failed: $($_.Exception.Message)" -ForegroundColor Red
            $failCount++
            continue
        }

        # Convert to ICO
        $converted = Convert-ToIcon -ImagePath $tempImagePath -IconPath $iconPath
        if (-not $converted) {
            $failCount++
            continue
        }

        # Set folder icon
        Set-FolderIcon -FolderPath $folder.FullName -IconFileName $IconFileName

        Write-Host "      Icon set!" -ForegroundColor Green
        $successCount++

        # Cleanup temp
        if (Test-Path $tempImagePath) { Remove-Item $tempImagePath -Force }
    }

    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue
    }

    # Summary
    Show-Divider
    Write-Host "  RESULTS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Icons set:     $successCount" -ForegroundColor $(if ($successCount -gt 0) { 'Green' } else { 'DarkGray' })
    Write-Host "    Skipped:       $skipCount" -ForegroundColor DarkGray
    Write-Host "    Not found:     $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Yellow' } else { 'DarkGray' })
    Show-Divider
    Show-Success "Icon setting complete! Press F5 in Explorer or restart Explorer to see icons."
}


# ============================================================
#  MAIN LOOP
# ============================================================

while ($true) {
    Show-Banner
    Show-MainMenu

    Write-Host "  Enter your choice: " -NoNewline -ForegroundColor White
    $choice = Read-Host

    switch ($choice.Trim()) {
        '1' {
            Show-Banner
            Show-ToolHeader -Title "FOLDER RENAMER" -Icon "[1]"
            $path = Get-FolderPath
            if ($path) {
                $ctype = Show-ContentTypeMenu
                Run-FolderRenamer -TargetPath $path -ContentType $ctype
            }
            Pause-BeforeMenu
        }
        '2' {
            Show-Banner
            Show-ToolHeader -Title "POSTER ICON SETTER" -Icon "[2]"
            $path = Get-FolderPath
            if ($path) {
                $ctype = Show-ContentTypeMenu
                Run-PosterIconSetter -TargetPath $path -ContentType $ctype
            }
            Pause-BeforeMenu
        }
        '3' {
            Show-Banner
            Show-ToolHeader -Title "FULL AUTO (Rename + Icons)" -Icon "[3]"
            $path = Get-FolderPath
            if ($path) {
                $ctype = Show-ContentTypeMenu
                Run-FolderRenamer -TargetPath $path -ContentType $ctype
                Write-Host ""
                Write-Host "  Now setting poster icons..." -ForegroundColor Cyan
                Write-Host ""
                Run-PosterIconSetter -TargetPath $path -ContentType $ctype
            }
            Pause-BeforeMenu
        }
        '0' {
            Show-Banner
            Write-Host "  Goodbye! Happy watching!" -ForegroundColor Cyan
            Write-Host ""
            exit 0
        }
        default {
            Show-Error "Invalid choice. Please enter 1, 2, 3, or 0."
            Start-Sleep -Seconds 1
        }
    }
}
