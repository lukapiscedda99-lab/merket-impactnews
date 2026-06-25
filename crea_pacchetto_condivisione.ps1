$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$TempDir = Join-Path $env:TEMP "market-news-bot-condivisione-$Timestamp"
$Desktop = [Environment]::GetFolderPath("Desktop")
$ZipPath = Join-Path $Desktop "market-news-bot-condivisione-$Timestamp.zip"

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir | Out-Null

$ExcludedNames = @(
    ".env",
    ".venv",
    "__pycache__",
    "logs",
    ".git",
    ".idea",
    ".vscode",
    "news_seen.db",
    "bot_avvio.log"
)

$ExcludedExtensions = @(
    ".pyc",
    ".pyo",
    ".log"
)

Get-ChildItem -Path $ProjectDir -Force | ForEach-Object {
    $item = $_

    if ($ExcludedNames -contains $item.Name) {
        return
    }

    if (-not $item.PSIsContainer -and $ExcludedExtensions -contains $item.Extension.ToLower()) {
        return
    }

    Copy-Item -Path $item.FullName -Destination $TempDir -Recurse -Force
}

$EnvPath = Join-Path $ProjectDir ".env"
$EnvExamplePath = Join-Path $TempDir ".env.example"

if (Test-Path $EnvPath) {
    $exampleLines = @()

    Get-Content $EnvPath | ForEach-Object {
        $line = $_.Trim()

        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith("#")) {
            return
        }

        if ($line.Contains("=")) {
            $key = $line.Split("=", 2)[0].Trim()

            switch ($key) {
                "MIN_IMPACT" { $exampleLines += "$key=ALTO" }
                "POLL_SECONDS" { $exampleLines += "$key=60" }
                "SCHEDULE_REFRESH_SECONDS" { $exampleLines += "$key=3600" }
                "TRANSLATE_TO_ITALIAN" { $exampleLines += "$key=true" }
                "SHOW_ORIGINAL_TITLE" { $exampleLines += "$key=false" }
                default { $exampleLines += "$key=INSERIRE_VALORE" }
            }
        }
    }

    if ($exampleLines.Count -gt 0) {
        $exampleLines | Set-Content -Path $EnvExamplePath -Encoding UTF8
    }
}
else {
    @(
        "TELEGRAM_BOT_TOKEN=INSERIRE_VALORE",
        "TELEGRAM_CHAT_ID=INSERIRE_VALORE",
        "MIN_IMPACT=ALTO",
        "POLL_SECONDS=60",
        "SCHEDULE_REFRESH_SECONDS=3600",
        "TRANSLATE_TO_ITALIAN=true",
        "SHOW_ORIGINAL_TITLE=false"
    ) | Set-Content -Path $EnvExamplePath -Encoding UTF8
}

$Readme = @"
MARKET IMPACT NEWS — PACCHETTO DI CONDIVISIONE

Questo pacchetto contiene il codice del progetto, ma NON contiene:
- token Telegram;
- file .env;
- ambiente virtuale .venv;
- database locale news_seen.db;
- log;
- credenziali.

INSTALLAZIONE SUL PC DEL DESTINATARIO

1. Estrarre lo ZIP in una cartella.
2. Aprire il Prompt dei comandi nella cartella.
3. Eseguire:

   py -m venv .venv
   .venv\Scripts\activate
   py -m pip install -r requirements.txt
   copy .env.example .env
   notepad .env

4. Inserire nel file .env:
   - token Telegram;
   - Chat ID;
   - eventuali altre configurazioni.

5. Avviare:

   py app.py

IMPORTANTE
Non inviare separatamente il file .env tramite email, chat o cartelle pubbliche.
Se il destinatario deve gestire lo stesso bot, il token gli attribuisce pieno controllo.
"@

$Readme | Set-Content -Path (Join-Path $TempDir "README_CONDIVISIONE.txt") -Encoding UTF8

if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Compress-Archive -Path (Join-Path $TempDir "*") -DestinationPath $ZipPath -Force
Remove-Item $TempDir -Recurse -Force

Write-Host ""
Write-Host "Pacchetto creato correttamente:" -ForegroundColor Green
Write-Host $ZipPath
Write-Host ""
Write-Host "Il file .env, il token, il database e i log NON sono stati inclusi." -ForegroundColor Yellow
Read-Host "Premi Invio per chiudere"
