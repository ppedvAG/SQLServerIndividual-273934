/*
ÜBERBLICK
Dieses Skript zeigt ausgewählte Einstellungen auf Datenbankebene für Northwind:
Statistiken, Datums-Korrelation, verzögerte Dauerhaftigkeit, MAXDOP,
Optimizer-Hotfixes und Snapshot-Isolation. Die Optionen haben versions- und
anwendungsabhängige Auswirkungen. Vor produktiver Änderung dokumentieren,
testen und einen Rückweg planen.

PRAXISTIPPS
- Das Skript führt Änderungen aus. Vor dem Start Datenbanknamen, SQL-Server-
  Version und gewünschte Einstellungen kontrollieren.
- READ_COMMITTED_SNAPSHOT kann die benötigte Version Store-Kapazität in tempdb
  erhöhen und beim Aktivieren Verbindungen blockieren. Wartungsfenster und
  Lasttest einplanen.
- DELAYED_DURABILITY = ALLOWED erlaubt Transaktionen, verzögerte Dauerhaftigkeit
  anzufordern; es schaltet nicht automatisch jede Transaktion auf verzögert.
  Bei Serverausfall können bestätigte, noch nicht persistierte Transaktionen
  verloren gehen.
- Die DMV-Abfrage für Datei-I/O liefert kumulative Werte seit Start/Reset.
  Für Latenzen zwei Snapshots als Differenz auswerten und bei null I/Os keinen
  Durchschnitt berechnen.
*/

-- Wählt Northwind als Kontext für die datenbankbezogenen Einstellungen.
-- ALTER DATABASE SCOPED CONFIGURATION gilt für die aktuelle Datenbank.
USE [Northwind];
GO

-- Aktiviert inkrementelle automatische Statistiken für Northwind.
-- Dies ist vor allem für partitionierte Tabellen relevant; andernfalls ist
-- der inkrementelle Modus nicht von Nutzen.
ALTER DATABASE [Northwind]
    SET AUTO_CREATE_STATISTICS ON (INCREMENTAL = ON);
GO

-- Beispiel für eine manuelle Aktualisierung inkrementeller Statistiken.
-- Nur nach Anpassung von Tabelle, Statistik und Partition ausführen.
-- UPDATE STATISTICS [dbo].[Record] [idx_record_name]
--     WITH RESAMPLE ON PARTITIONS (1);

-- Aktiviert die Optimierung für korrelierte Datumsfelder.
-- Sie kann bei bestimmten Abfragemustern helfen; anhand des realen Plans prüfen.
ALTER DATABASE [Northwind]
    SET DATE_CORRELATION_OPTIMIZATION ON WITH NO_WAIT;
GO

-- Erlaubt verzögerte Dauerhaftigkeit. Die Anwendung muss die möglichen
-- Auswirkungen eines Serverausfalls auf bestätigte Transaktionen tolerieren.
ALTER DATABASE [Northwind]
    SET DELAYED_DURABILITY = ALLOWED WITH NO_WAIT;
GO

-- Begrenzt den maximalen Parallelitätsgrad von Abfragen in Northwind auf vier.
ALTER DATABASE SCOPED CONFIGURATION
    SET MAXDOP = 4;
GO

-- Aktiviert verfügbare Abfrageoptimierer-Hotfixes für diese Datenbank.
-- Verhalten und Verfügbarkeit hängen von Version und Kompatibilitätsgrad ab.
ALTER DATABASE SCOPED CONFIGURATION
    SET QUERY_OPTIMIZER_HOTFIXES = ON;
GO

-- Erlaubt Snapshot-Isolation für Verbindungen, die diese Isolationsstufe wählen.
ALTER DATABASE [Northwind]
    SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

-- Aktiviert zeilenbasierte Versionsverwaltung für READ COMMITTED.
-- Vorher Auswirkungen auf tempdb und Anwendungskompatibilität testen.
ALTER DATABASE [Northwind]
    SET READ_COMMITTED_SNAPSHOT ON WITH NO_WAIT;
GO

-- Leert den Prozedurcache nur für die aktuelle Datenbank.
-- Dies kann nach Planänderungen für Tests nützlich sein, verursacht aber
-- erneute Kompilierungen und sollte nicht routinemäßig in Produktion erfolgen.
ALTER DATABASE SCOPED CONFIGURATION
    CLEAR PROCEDURE_CACHE;
GO

-- Ermittelt kumulative Lese-/Schreibvorgänge und Wartezeiten der Datenbankdateien.
-- Für aussagekräftige Latenzen die Zählerdifferenz zwischen zwei Snapshots nutzen.
SELECT
    DB_NAME(vfs.database_id) AS DatabaseName,
    mf.name AS LogicalFileName,
    mf.type_desc AS FileType,
    vfs.num_of_reads,
    vfs.io_stall_read_ms,
    vfs.num_of_writes,
    vfs.io_stall_write_ms,
    vfs.size_on_disk_bytes
FROM sys.dm_io_virtual_file_stats(DB_ID(N'Northwind'), NULL) AS vfs
INNER JOIN sys.master_files AS mf
    ON mf.database_id = vfs.database_id
   AND mf.file_id = vfs.file_id
ORDER BY
    mf.type_desc,
    mf.name;
