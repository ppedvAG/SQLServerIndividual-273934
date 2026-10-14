/*
ÜBERBLICK
Diese Datei beschreibt die SQL-Server-Systemdatenbanken und zeigt Beispiele
für vollständige, differentielle und Transaktionslog-Backups einer
Benutzerdatenbank. Die Befehle sichern TestDb; passe Datenbank und Zielpfad an.

SYSTEMDATENBANKEN
- master speichert instanzweite Metadaten, Logins und Konfigurationen.
- model dient als Vorlage für neu erstellte Datenbanken.
- msdb speichert unter anderem SQL-Agent-Aufträge, Wartungspläne und
  Backupverlauf. SSIS-Inhalte hängen von installierten Komponenten ab.
- tempdb enthält temporäre Objekte und Arbeitsbereiche und wird beim Start
  der Instanz neu erstellt; sie wird nicht gesichert.
- distribution wird bei entsprechender Replikationskonfiguration verwendet.
- Resource Database ist eine interne, schreibgeschützte Systemdatenbank.

BACKUP-PRAXISTIPPS
- Systemdatenbanken regelmäßig sichern. Nach Änderungen an master oder model
  sowie bei Änderungen an Agent-Aufträgen in msdb gezielt ein Backup erstellen.
- Die Wiederherstellungsstrategie mit Restore-Tests validieren. Eine
  Backupdatei allein beweist nicht, dass eine Wiederherstellung möglich ist.
- Vollständige Backups bilden die Basis; differentielle Backups benötigen das
  passende vollständige Backup. Log-Backups setzen das FULL- oder BULK_LOGGED-
  Wiederherstellungsmodell und eine geplante Log-Backup-Kette voraus.
- Das Dienstkonto des SQL Servers benötigt Schreibrechte im Zielverzeichnis.
  Backups nach Möglichkeit auf getrenntem, geschütztem Speicher ablegen.
*/

-- Erstellt ein vollständiges Backup von TestDb. Der Pfad muss erreichbar sein
-- und das SQL-Server-Dienstkonto benötigt dort Schreibrechte.
BACKUP DATABASE [TestDb]
TO DISK = N'C:\_SQLBACKUP\TestDb_full.bak'
WITH
    INIT,
    NAME = N'TestDb – vollständige Sicherung',
    CHECKSUM,
    COMPRESSION,
    STATS = 10;
GO

-- Erstellt ein differentielles Backup seit dem letzten vollständigen Backup.
BACKUP DATABASE [TestDb]
TO DISK = N'C:\_SQLBACKUP\TestDb_diff.bak'
WITH
    DIFFERENTIAL,
    INIT,
    NAME = N'TestDb – differenzielle Sicherung',
    CHECKSUM,
    COMPRESSION,
    STATS = 10;
GO

-- Sichert Transaktionslogeinträge. Nur mit passendem Recovery Model und
-- geplanter Backupkette ausführen; dies ersetzt kein vollständiges Backup.
BACKUP LOG [TestDb]
TO DISK = N'C:\_SQLBACKUP\TestDb_log.trn'
WITH
    INIT,
    NAME = N'TestDb – Transaktionslog-Sicherung',
    CHECKSUM,
    COMPRESSION,
    STATS = 10;
GO
