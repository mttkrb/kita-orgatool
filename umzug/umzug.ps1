# Umzug des Kita-Orgatools in ein anderes Supabase-Projekt - Windows.
# Ausführliche Anleitung: ANLEITUNG.md im selben Ordner.
#
#   umzug-windows.cmd pruefen               Werkzeuge, Verbindungen und Zielprojekt prüfen
#   umzug-windows.cmd sichern               Altes Projekt sichern (liest nur, ändert dort nichts)
#   umzug-windows.cmd einspielen            Letzte Sicherung ins neue Projekt einspielen
#   umzug-windows.cmd einspielen --ersetzen Dasselbe, vorhandene Tabellen im neuen Projekt ersetzen
#   umzug-windows.cmd cron                  Zeitgesteuerte Aufträge (pg_cron) übertragen
#   umzug-windows.cmd vergleichen           Zeilen, Struktur und Rechte alt/neu vergleichen
#   umzug-windows.cmd alles                 pruefen, sichern, einspielen, vergleichen
#   umzug-windows.cmd aufraeumen            Sicherungen im Ordner arbeit\ löschen
#
# Läuft mit Windows PowerShell 5.1 und PowerShell 7. Die Datei muss als UTF-8 mit BOM
# gespeichert bleiben, sonst zeigt PowerShell 5.1 die Umlaute falsch an.

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [Text.Encoding]::UTF8

$Hier = $PSScriptRoot
$EnvDatei = if ($env:UMZUG_ENV) { $env:UMZUG_ENV } else { Join-Path $Hier 'umzug.env' }
$Arbeit = Join-Path $Hier 'arbeit'
$Utf8 = New-Object System.Text.UTF8Encoding $false

function Fehler([string]$Text) { Write-Host ''; Write-Host "FEHLER: $Text" -ForegroundColor Red; exit 1 }
function Hinweis([string]$Text) { Write-Host 'Hinweis: ' -ForegroundColor Yellow -NoNewline; Write-Host $Text }
function Ok([string]$Text) { Write-Host 'OK: ' -ForegroundColor Green -NoNewline; Write-Host $Text }
function Rot([string]$Wort, [string]$Text) { Write-Host "$Wort " -ForegroundColor Red -NoNewline; Write-Host $Text }
function Schritt([string]$Text) { Write-Host ''; Write-Host "== $Text ==" -ForegroundColor White }

function Frage([string]$Text) {
  $antwort = Read-Host "$Text [j/N]"
  if (@('j', 'J', 'ja', 'Ja', 'JA') -notcontains $antwort) { Fehler 'Abgebrochen.' }
}

function Schreibe([string]$Datei, $Zeilen) {
  [IO.File]::WriteAllLines((Join-Path $Arbeit $Datei), [string[]]@($Zeilen), $Utf8)
}
function Lies([string]$Datei) { @([IO.File]::ReadAllLines((Join-Path $Arbeit $Datei), $Utf8)) }

# ---------- Zugangsdaten ----------

$Cfg = @{ ALT_HOST = ''; ALT_PORT = ''; ALT_USER = ''; ALT_PASSWORT = ''
          NEU_HOST = ''; NEU_PORT = ''; NEU_USER = ''; NEU_PASSWORT = ''
          NEU_URL = ''; NEU_ANON_KEY = ''; PG_DOCKER_IMAGE = '' }

function Lade-Env {
  if (-not (Test-Path $EnvDatei)) {
    Fehler "$EnvDatei fehlt. umzug.env.example kopieren, in umzug.env umbenennen und ausfüllen."
  }
  foreach ($zeile in [IO.File]::ReadAllLines($EnvDatei, $Utf8)) {
    $z = $zeile.Trim()
    if ($z -eq '' -or $z.StartsWith('#')) { continue }
    $i = $z.IndexOf('=')
    if ($i -lt 1) { continue }
    $name = $z.Substring(0, $i).Trim()
    $wert = $z.Substring($i + 1).Trim()
    if ($wert.Length -ge 2 -and (($wert[0] -eq '"' -and $wert[-1] -eq '"') -or ($wert[0] -eq "'" -and $wert[-1] -eq "'"))) {
      $wert = $wert.Substring(1, $wert.Length - 2)
    }
    if ($Cfg.ContainsKey($name)) { $Cfg[$name] = $wert }
  }
  if (-not $Cfg.ALT_PORT) { $Cfg.ALT_PORT = '5432' }
  if (-not $Cfg.NEU_PORT) { $Cfg.NEU_PORT = '5432' }
  foreach ($v in 'ALT_HOST', 'ALT_USER', 'ALT_PASSWORT', 'NEU_HOST', 'NEU_USER', 'NEU_PASSWORT') {
    if (-not $Cfg[$v]) { Fehler "$v ist in $(Split-Path $EnvDatei -Leaf) nicht ausgefüllt." }
  }
  if ("$($Cfg.ALT_HOST)|$($Cfg.ALT_USER)" -eq "$($Cfg.NEU_HOST)|$($Cfg.NEU_USER)") {
    Fehler 'ALT und NEU zeigen auf dasselbe Projekt.'
  }
}

# ---------- PostgreSQL-Werkzeuge ----------

$Modus = ''        # lokal oder docker
$PgBin = ''        # Ordner mit pg_dump.exe, pg_restore.exe und psql.exe
$PgMajor = 0
$DockerImage = ''
$PgExit = 0

# Sucht die neueste Installation, auch wenn sie nicht im PATH steht.
function Finde-Werkzeuge {
  $kandidaten = @()
  $cmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
  if ($cmd) { $kandidaten += (Split-Path $cmd.Source) }
  foreach ($basis in @($env:ProgramFiles, ${env:ProgramFiles(x86)})) {
    if (-not $basis) { continue }
    Get-ChildItem (Join-Path $basis 'PostgreSQL') -Directory -ErrorAction SilentlyContinue |
      ForEach-Object { $kandidaten += (Join-Path $_.FullName 'bin') }
  }
  foreach ($d in $kandidaten) {
    $vollstaendig = $true
    foreach ($p in 'pg_dump.exe', 'pg_restore.exe', 'psql.exe') {
      if (-not (Test-Path (Join-Path $d $p))) { $vollstaendig = $false }
    }
    if (-not $vollstaendig) { continue }
    $v = & (Join-Path $d 'pg_dump.exe') --version 2>$null
    if ("$v" -match '(\d+)') {
      $m = [int]$Matches[1]
      if ($m -gt $script:PgMajor) { $script:PgMajor = $m; $script:PgBin = $d }
    }
  }
}

function Docker-Bereit {
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return $false }
  & docker info *> $null
  return ($LASTEXITCODE -eq 0)
}

# Pg alt|neu programm argumente
# Führt ein PostgreSQL-Programm mit den Zugangsdaten des alten oder neuen Projekts aus.
# Arbeitsordner ist arbeit\, Dateiangaben also relativ dazu (SQL-Dateien: ../sql/...).
# Ausgabe geht an den Aufrufer, der Rückgabewert des Programms steht in $script:PgExit.
function Pg([string]$Ziel, [string]$Prog, [string[]]$Argumente) {
  $p = if ($Ziel -eq 'alt') { 'ALT_' } else { 'NEU_' }
  $env:PGHOST = $Cfg[$p + 'HOST']; $env:PGPORT = $Cfg[$p + 'PORT']
  $env:PGUSER = $Cfg[$p + 'USER']; $env:PGPASSWORD = $Cfg[$p + 'PASSWORT']
  $env:PGDATABASE = 'postgres'; $env:PGSSLMODE = 'require'; $env:PGCONNECT_TIMEOUT = '20'
  $env:PGAPPNAME = 'kita-umzug'; $env:PGCLIENTENCODING = 'UTF8'
  Push-Location $Arbeit
  try {
    if ($script:Modus -eq 'lokal') {
      & (Join-Path $script:PgBin "$Prog.exe") @Argumente
    } else {
      & docker run --rm -v "${Hier}:/umzug" -w /umzug/arbeit `
        -e PGHOST -e PGPORT -e PGUSER -e PGPASSWORD -e PGDATABASE -e PGSSLMODE `
        -e PGCONNECT_TIMEOUT -e PGAPPNAME -e PGCLIENTENCODING `
        $script:DockerImage $Prog @Argumente
    }
    $script:PgExit = $LASTEXITCODE
  } finally {
    Pop-Location
    foreach ($n in 'PGHOST', 'PGPORT', 'PGUSER', 'PGPASSWORD', 'PGDATABASE', 'PGSSLMODE',
                   'PGCONNECT_TIMEOUT', 'PGAPPNAME', 'PGCLIENTENCODING') {
      Remove-Item "env:$n" -ErrorAction SilentlyContinue
    }
  }
}

function Abfrage([string]$Ziel, [string]$Sql) { Pg $Ziel 'psql' @('-X', '-q', '-At', '-v', 'ON_ERROR_STOP=1', '-c', $Sql) }
function Sql-Datei([string]$Ziel, [string]$Datei) { Pg $Ziel 'psql' @('-X', '-q', '-At', '-v', 'ON_ERROR_STOP=1', '-f', $Datei) }

$AltMajor = 0; $NeuMajor = 0

# Wählt die Werkzeuge und fragt die Serverversionen ab. pg_dump muss mindestens die
# Hauptversion des Servers haben. Fehlt eine passende lokale Installation, wird Docker
# genommen.
function Bereite-Vor {
  if (-not (Test-Path $Arbeit)) { New-Item -ItemType Directory $Arbeit | Out-Null }
  Finde-Werkzeuge
  if ($script:PgBin) { $script:Modus = 'lokal' }
  elseif (Docker-Bereit) {
    $script:Modus = 'docker'
    $script:DockerImage = if ($Cfg.PG_DOCKER_IMAGE) { $Cfg.PG_DOCKER_IMAGE } else { 'postgres:17-alpine' }
  }
  else { Fehler 'Weder PostgreSQL-Werkzeuge (pg_dump, pg_restore, psql) noch Docker gefunden. Siehe ANLEITUNG.md, Abschnitt 2.' }

  $v = Abfrage 'alt' 'show server_version_num'
  if ($script:PgExit -ne 0 -or -not $v) {
    Fehler 'Keine Verbindung zum alten Projekt. ALT_HOST, ALT_USER und ALT_PASSWORT prüfen, und ob das Projekt pausiert ist.'
  }
  $script:AltMajor = [math]::Floor([int]"$v".Trim() / 10000)
  $v = Abfrage 'neu' 'show server_version_num'
  if ($script:PgExit -ne 0 -or -not $v) {
    Fehler 'Keine Verbindung zum neuen Projekt. NEU_HOST, NEU_USER und NEU_PASSWORT prüfen.'
  }
  $script:NeuMajor = [math]::Floor([int]"$v".Trim() / 10000)

  $noetig = [math]::Max($script:AltMajor, $script:NeuMajor)
  if ($script:Modus -eq 'lokal' -and $script:PgMajor -lt $noetig) {
    if (Docker-Bereit) {
      Hinweis "Lokale PostgreSQL-Werkzeuge sind Version $($script:PgMajor), gebraucht wird $noetig. Nehme Docker."
      $script:Modus = 'docker'
    } else {
      Fehler "Die PostgreSQL-Werkzeuge in $($script:PgBin) sind Version $($script:PgMajor), gebraucht wird mindestens $noetig. Neuere Version installieren (ANLEITUNG.md, Abschnitt 2)."
    }
  }
  if ($script:Modus -eq 'docker') {
    $script:DockerImage = if ($Cfg.PG_DOCKER_IMAGE) { $Cfg.PG_DOCKER_IMAGE } else { "postgres:$([math]::Max($noetig, 17))-alpine" }
  }
}

function Beschreibe-Werkzeuge {
  if ($script:Modus -eq 'lokal') { Ok "PostgreSQL-Werkzeuge Version $($script:PgMajor) in $($script:PgBin)" }
  else { Ok "PostgreSQL-Werkzeuge aus Docker ($($script:DockerImage))" }
  Ok "Altes Projekt erreichbar, Postgres $($script:AltMajor)"
  Ok "Neues Projekt erreichbar, Postgres $($script:NeuMajor)"
  if ($script:NeuMajor -lt $script:AltMajor) {
    Hinweis 'Das neue Projekt hat eine ältere Postgres-Version als das alte. Das Einspielen kann scheitern.'
    Hinweis "Besser ein neues Projekt mit Version $($script:AltMajor) oder neuer anlegen."
  }
}

# Tabellen im Schema public, ohne solche, die zu Erweiterungen gehören.
function Tabellen-Neu {
  $t = Abfrage 'neu' "select coalesce(string_agg(c.relname, ', ' order by c.relname), '') from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind in ('r','p','v','m') and not exists (select 1 from pg_depend d where d.classid = 'pg_class'::regclass and d.objid = c.oid and d.deptype = 'e')"
  if ($script:PgExit -ne 0) { Fehler 'Tabellen im neuen Projekt nicht lesbar.' }
  "$t".Trim()
}

function Erweiterungen([string]$Ziel) {
  "$(Abfrage $Ziel "select coalesce(string_agg(extname, ' ' order by extname), '') from pg_extension")".Trim() -split '\s+' |
    Where-Object { $_ }
}

function Hat-Cron([string]$Ziel) { "$(Abfrage $Ziel "select to_regclass('cron.job') is not null")".Trim() -eq 't' }

function Letzte-Sicherung {
  if (-not (Test-Path (Join-Path $Arbeit 'letzte-sicherung'))) {
    Fehler 'Noch keine Sicherung vorhanden. Erst "umzug-windows.cmd sichern" ausführen.'
  }
  $script:Basis = @(Lies 'letzte-sicherung')[0].Trim()
  if (-not (Test-Path (Join-Path $Arbeit "$($script:Basis).dump"))) { Fehler "Sicherung arbeit\$($script:Basis).dump fehlt." }
}

function Zeige-Zeilen($Zeilen) { foreach ($z in $Zeilen) { Write-Host ('  ' + ($z -replace '\|', ': ')) } }

# Zeilen, die nur in einer der beiden Listen stehen: - nur alt, + nur neu
function Unterschiede($Alt, $Neu) {
  $a = New-Object 'System.Collections.Generic.HashSet[string]'
  $n = New-Object 'System.Collections.Generic.HashSet[string]'
  foreach ($z in $Alt) { [void]$a.Add($z) }
  foreach ($z in $Neu) { [void]$n.Add($z) }
  foreach ($z in $Alt) { if (-not $n.Contains($z)) { "- $z" } }
  foreach ($z in $Neu) { if (-not $a.Contains($z)) { "+ $z" } }
}

# ---------- Schritte ----------

function Cmd-Pruefen {
  Schritt 'Prüfen'
  Beschreibe-Werkzeuge

  $tabellen = Tabellen-Neu
  if ($tabellen) {
    Hinweis "Im neuen Projekt gibt es schon Tabellen: $tabellen"
    Hinweis 'Einspielen geht dann nur mit: umzug-windows.cmd einspielen --ersetzen'
  } else { Ok 'Neues Projekt ist leer' }

  $neuExt = @(Erweiterungen 'neu')
  $fehlend = @(Erweiterungen 'alt' | Where-Object { $neuExt -notcontains $_ })
  if ($fehlend.Count) {
    Hinweis "Diese Erweiterungen sind im alten, aber nicht im neuen Projekt aktiv: $($fehlend -join ' ')"
    Hinweis 'Im neuen Projekt unter Database > Extensions einschalten (pg_cron übernimmt der Schritt cron).'
  } else { Ok 'Alle Erweiterungen des alten Projekts sind auch im neuen aktiv' }

  if (Hat-Cron 'alt') {
    $n = "$(Abfrage 'alt' 'select count(*) from cron.job where active and database = current_database()')".Trim()
    Ok "Altes Projekt hat $n aktive(n) Cron-Auftrag/Aufträge; sie werden mit übertragen"
  }

  Write-Host ''
  Write-Host 'Zeilen im alten Projekt:'
  Zeige-Zeilen (Sql-Datei 'alt' '../sql/zeilen.sql')
}

function Cmd-Sichern {
  Schritt 'Altes Projekt sichern'
  $basis = 'alt_' + (Get-Date -Format 'yyyyMMdd-HHmmss')

  $vorher = @(Sql-Datei 'alt' '../sql/zeilen.sql')
  if ($script:PgExit -ne 0) { Fehler 'Zeilen im alten Projekt nicht lesbar.' }
  Pg 'alt' 'pg_dump' @('--format=custom', '--schema=public', '--schema=intern', '--no-publications', '--no-subscriptions',
                       '--no-security-labels', "--file=$basis.dump")
  if ($script:PgExit -ne 0) { Fehler 'pg_dump ist gescheitert, siehe Meldung oben.' }
  $struktur = @(Sql-Datei 'alt' '../sql/struktur.sql')
  if ($script:PgExit -ne 0) { Fehler 'Struktur nicht lesbar.' }
  Schreibe "$basis.struktur.txt" $struktur
  $nachher = @(Sql-Datei 'alt' '../sql/zeilen.sql')
  if ($script:PgExit -ne 0) { Fehler 'Zeilen im alten Projekt nicht lesbar.' }
  Schreibe "$basis.zeilen.txt" $nachher

  if (Hat-Cron 'alt') {
    $cron = @(Sql-Datei 'alt' '../sql/cron-export.sql')
    if ($script:PgExit -ne 0) { Fehler 'Cron-Aufträge nicht lesbar.' }
    Schreibe "$basis.cron.sql" $cron
  }
  Schreibe 'letzte-sicherung' $basis

  if (($vorher -join "`n") -ne ($nachher -join "`n")) {
    Hinweis 'Während der Sicherung hat sich im alten Projekt etwas geändert.'
    Hinweis 'Sind die Anmeldungen wirklich gestoppt? Sonst "umzug-windows.cmd sichern" noch einmal ausführen.'
  }
  Ok "Gesichert nach arbeit\$basis.dump"
  Zeige-Zeilen $nachher
}

function Cmd-Einspielen([bool]$Ersetzen) {
  Schritt 'In das neue Projekt einspielen'
  Letzte-Sicherung
  Write-Host "Sicherung: arbeit\$($script:Basis).dump"

  $tabellen = Tabellen-Neu
  if ($tabellen) {
    if (-not $Ersetzen) {
      Fehler "Im neuen Projekt gibt es schon Tabellen: $tabellen`nWenn das ein früherer Versuch war: umzug-windows.cmd einspielen --ersetzen"
    }
    Frage "Im NEUEN Projekt werden diese Tabellen samt Inhalt ersetzt: $tabellen. Weiter?"
  }

  # Inhaltsverzeichnis der Sicherung in zwei Teile: alles außer Rechten, und die Rechte.
  # Weggelassen werden das Schema public selbst und Erweiterungen, die Supabase
  # im neuen Projekt schon mitbringt, sowie Standardrechte für künftige Tabellen.
  Pg 'neu' 'pg_restore' @('--list', '--file=inhalt.list', "$($script:Basis).dump")
  if ($script:PgExit -ne 0) { Fehler 'Sicherung nicht lesbar.' }
  $inhalt = Lies 'inhalt.list'
  Schreibe 'haupt.list' @($inhalt | Where-Object {
    $_ -notmatch '^\d+; \d+ \d+ (DEFAULT ACL|ACL) ' -and $_ -notmatch ' SCHEMA - public ' -and
    $_ -notmatch 'COMMENT - SCHEMA public' -and $_ -notmatch ' EXTENSION ' })
  Schreibe 'rechte.list' @($inhalt | Where-Object { $_ -match '^\d+; \d+ \d+ ACL ' -and $_ -notmatch 'SCHEMA public' })

  $clean = @()
  if ($Ersetzen) { $clean = @('--clean', '--if-exists') }

  Write-Host 'Tabellen, Funktionen, Policies und Daten ...'
  Pg 'neu' 'pg_restore' (@('--dbname=postgres', '--no-owner', '--single-transaction', '--exit-on-error') + $clean +
                         @('--use-list=haupt.list', "$($script:Basis).dump"))
  if ($script:PgExit -ne 0) { Fehler 'Einspielen gescheitert, im neuen Projekt wurde nichts geändert. Meldung oben lesen.' }
  Ok 'Tabellen, Funktionen, Policies und Daten eingespielt'

  Write-Host 'Rechte ...'
  Sql-Datei 'neu' '../sql/rechte-leeren.sql' | Out-Null
  if ($script:PgExit -ne 0) { Fehler 'Standardrechte ließen sich nicht entfernen.' }
  Pg 'neu' 'pg_restore' @('--dbname=postgres', '--no-owner', '--use-list=rechte.list', "$($script:Basis).dump")
  if ($script:PgExit -eq 0) { Ok 'Rechte wie im alten Projekt gesetzt' }
  else { Hinweis 'Einige Rechte ließen sich nicht setzen (Meldungen oben). Der Vergleich zeigt, welche fehlen.' }

  # Supabase-API die neuen Tabellen sofort bekannt machen
  Abfrage 'neu' "notify pgrst, 'reload schema'" | Out-Null

  Cmd-Cron
  Cmd-Vergleichen
}

function Cmd-Cron {
  Schritt 'Zeitgesteuerte Aufträge (pg_cron)'
  Letzte-Sicherung
  $datei = "$($script:Basis).cron.sql"
  $pfad = Join-Path $Arbeit $datei
  if (-not (Test-Path $pfad) -or (Get-Item $pfad).Length -eq 0) {
    Ok 'Im alten Projekt gab es keine aktiven Cron-Aufträge'
    return
  }
  if (-not (Hat-Cron 'neu')) {
    Abfrage 'neu' 'create extension if not exists pg_cron with schema pg_catalog' | Out-Null
    if ($script:PgExit -ne 0) {
      Hinweis 'pg_cron ließ sich im neuen Projekt nicht einschalten.'
      Hinweis 'Im Supabase-Dashboard unter Database > Extensions pg_cron einschalten, dann: umzug-windows.cmd cron'
      return
    }
  }
  Sql-Datei 'neu' $datei | Out-Null
  if ($script:PgExit -ne 0) { Hinweis 'Cron-Aufträge ließen sich nicht anlegen, siehe Meldung oben.'; return }
  Ok 'Cron-Aufträge im neuen Projekt:'
  Abfrage 'neu' "select jobname || '  ' || schedule || '  ' || command from cron.job order by jobid" |
    ForEach-Object { Write-Host "  $_" }
}

# Test über die REST-API mit dem anonKey, so wie die Seiten zugreifen.
function Hole([string]$Pfad, [hashtable]$Mehr) {
  $kopf = @{ apikey = $Cfg.NEU_ANON_KEY; Authorization = 'Bearer ' + $Cfg.NEU_ANON_KEY }
  $parameter = @{ Uri = $Cfg.NEU_URL.TrimEnd('/') + '/rest/v1/' + $Pfad; UseBasicParsing = $true; TimeoutSec = 20 }
  if ($Mehr) {
    foreach ($k in $Mehr.Keys) { if ($k -eq 'Body') { $parameter.Body = $Mehr[$k]; $parameter.Method = 'Post'; $parameter.ContentType = 'application/json' } else { $kopf[$k] = $Mehr[$k] } }
  }
  $parameter.Headers = $kopf
  try {
    $r = Invoke-WebRequest @parameter
    return @{ Code = [int]$r.StatusCode; Text = "$($r.Content)".Trim() }
  } catch {
    $code = 0
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    return @{ Code = $code; Text = '' }
  }
}

function Api-Test {
  if (-not $Cfg.NEU_URL -or -not $Cfg.NEU_ANON_KEY) {
    Hinweis 'NEU_URL und NEU_ANON_KEY sind nicht gesetzt, Test über die Schnittstelle übersprungen.'
    return $true
  }
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }
  $gut = $true

  $r = Hole 'events?select=id&limit=1'
  if ($r.Code -eq 200) { Ok 'Veranstaltungen lesbar' } else { Rot 'FEHLT:' "Veranstaltungen nicht lesbar (HTTP $($r.Code))"; $gut = $false }

  $r = Hole 'signups?select=id,name&limit=1'
  if ($r.Code -ne 200 -or $r.Text -eq '[]') { Ok 'Anmeldungen ohne Token nicht lesbar' }
  else { Rot 'GEFAHR:' 'Anmeldungen sind für jeden lesbar! Rechte prüfen, Seiten NICHT umstellen.'; $gut = $false }

  $r = Hole 'signups?select=token&limit=1'
  if ($r.Code -ne 200) { Ok 'Spalte signups.token ist gesperrt' }
  else { Rot 'GEFAHR:' 'signups.token ist für jeden lesbar! Rechte prüfen, Seiten NICHT umstellen.'; $gut = $false }

  foreach ($t in 'orga_keys', 'templates', 'planning', 'feedback', 'payments', 'receipts') {
    $r = Hole "$($t)?select=*&limit=1"
    if ($r.Code -ne 200 -or $r.Text -eq '[]') { Ok "$t ohne Orga-Passwort nicht lesbar" }
    else { Rot 'GEFAHR:' "$t liefert ohne Orga-Passwort Daten!"; $gut = $false }
  }

  $r = Hole 'rpc/is_orga' @{ 'X-Orga-Key' = 'falsches-passwort-zum-test'; Body = '{}' }
  if ($r.Code -eq 200 -and $r.Text -eq 'false') { Ok 'Falsches Orga-Passwort wird abgelehnt' }
  else { Rot 'FEHLT:' "is_orga() antwortet nicht wie erwartet (HTTP $($r.Code))"; $gut = $false }

  return $gut
}

function Cmd-Vergleichen {
  Schritt 'Vergleichen'
  Letzte-Sicherung
  $gut = $true

  $zeilen = @(Sql-Datei 'neu' '../sql/zeilen.sql')
  if ($script:PgExit -ne 0) { Fehler 'Zeilen im neuen Projekt nicht lesbar.' }
  $struktur = @(Sql-Datei 'neu' '../sql/struktur.sql')
  if ($script:PgExit -ne 0) { Fehler 'Struktur im neuen Projekt nicht lesbar.' }
  Schreibe 'neu.zeilen.txt' $zeilen
  Schreibe 'neu.struktur.txt' $struktur

  $d = @(Unterschiede (Lies "$($script:Basis).zeilen.txt") $zeilen)
  if ($d.Count -eq 0) { Ok 'Zeilenzahlen stimmen mit der Sicherung überein' }
  else { Rot 'ABWEICHUNG' 'bei den Zeilen (- Sicherung, + neues Projekt):'; $d | ForEach-Object { Write-Host "  $_" }; $gut = $false }

  $d = @(Unterschiede (Lies "$($script:Basis).struktur.txt") $struktur)
  if ($d.Count -eq 0) { Ok 'Tabellen, Spalten, Policies, Funktionen und Rechte stimmen überein' }
  else { Rot 'ABWEICHUNG' 'bei Struktur oder Rechten (- altes Projekt, + neues Projekt):'; $d | ForEach-Object { Write-Host "  $_" }; $gut = $false }

  # Ist im alten Projekt seit der Sicherung noch etwas dazugekommen?
  $jetztAlt = @(Sql-Datei 'alt' '../sql/zeilen.sql' 2>$null)
  if ($script:PgExit -eq 0 -and (($jetztAlt -join "`n") -ne ((Lies "$($script:Basis).zeilen.txt") -join "`n"))) {
    Hinweis 'Im alten Projekt hat sich seit der Sicherung etwas geändert.'
    Hinweis 'Dann noch einmal: umzug-windows.cmd sichern und umzug-windows.cmd einspielen --ersetzen'
    $gut = $false
  }

  if (-not (Api-Test)) { $gut = $false }

  Write-Host ''
  if ($gut) { Ok 'Umzug vollständig. Weiter mit Abschnitt 6 der Anleitung (config.js umstellen).' }
  else {
    Write-Host 'Es gibt Abweichungen. Seiten erst umstellen, wenn sie geklärt sind (ANLEITUNG.md, Abschnitt 8).' -ForegroundColor Red
    exit 1
  }
}

function Cmd-Aufraeumen {
  Schritt 'Aufräumen'
  if (-not (Test-Path $Arbeit)) { Ok 'Nichts zu löschen'; return }
  Write-Host 'Im Ordner arbeit\ liegen Sicherungen mit allen Anmeldungen und dem Orga-Passwort:'
  Get-ChildItem $Arbeit | ForEach-Object { Write-Host "  $($_.Name)" }
  Frage 'Ordner arbeit\ endgültig löschen?'
  Remove-Item $Arbeit -Recurse -Force
  Ok 'Gelöscht'
}

function Cmd-Alles([bool]$Ersetzen) {
  Cmd-Pruefen
  Write-Host ''
  Write-Host 'Während des Umzugs dürfen sich keine Eltern anmelden, sonst gehen diese Einträge verloren.'
  Frage 'Sind die Anmeldungen gestoppt und soll der Umzug jetzt laufen?'
  Cmd-Sichern
  Cmd-Einspielen $Ersetzen
}

function Hilfe {
  Get-Content -Path $PSCommandPath -Encoding UTF8 -TotalCount 11 | Select-Object -Skip 1 |
    ForEach-Object { Write-Host ($_ -replace '^# ?', '') }
}

$Aufgabe = if ($args.Count -gt 0) { "$($args[0])" } else { 'hilfe' }
$Ersetzen = @($args | Where-Object { @('--ersetzen', '-ersetzen', 'ersetzen') -contains "$_" }).Count -gt 0

switch ($Aufgabe) {
  { @('pruefen', 'sichern', 'einspielen', 'cron', 'vergleichen', 'alles') -contains $_ } {
    Lade-Env
    Bereite-Vor
    if ($Aufgabe -ne 'pruefen') { Beschreibe-Werkzeuge }
    switch ($Aufgabe) {
      'pruefen'     { Cmd-Pruefen }
      'sichern'     { Cmd-Sichern }
      'einspielen'  { Cmd-Einspielen $Ersetzen }
      'cron'        { Cmd-Cron }
      'vergleichen' { Cmd-Vergleichen }
      'alles'       { Cmd-Alles $Ersetzen }
    }
    break
  }
  'aufraeumen' { Cmd-Aufraeumen; break }
  default { Hilfe; if (@('hilfe', '-h', '--help', '/?') -notcontains $Aufgabe) { exit 1 } }
}
exit 0
