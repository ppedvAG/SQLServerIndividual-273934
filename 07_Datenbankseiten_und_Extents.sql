/*
ÜBERBLICK
Dieses Labor zeigt, wie SQL Server Daten in 8-KiB-Seiten und Extents verwaltet.
Es legt in Northwind eine Beispieltabelle an, fügt viele Datensätze ein und
stellt eine DMV zur Analyse der physischen Indexstruktur vor.

BEGRIFFE UND PRAXISTIPPS
- Eine Datenseite ist 8.192 Byte groß. Der nutzbare Platz für Zeilen ist
  wegen Seitenkopf und Verwaltungsinformationen kleiner; eine Zeile muss
  innerhalb der SQL-Server-Grenzen in eine Seite passen.
- Ein Extent umfasst acht zusammenhängende Seiten (64 KiB). SQL Server kann
  Seiten einzeln oder als einheitliche Extents zuweisen.
- Gleichzeitiger Zugriff wird durch interne Synchronisierung geschützt.
  Latches schützen Seitenzugriffe im Speicher; sie sind von I/O-Waits zu
  unterscheiden. Spinlocks sind ein anderer Synchronisationsmechanismus.
- sys.dm_db_index_physical_stats ist das aktuelle Werkzeug zur Untersuchung
  physischer Indexeigenschaften. DETAILED kann bei großen Objekten aufwendig
  sein; für erste Prüfungen LIMITED oder SAMPLED in Betracht ziehen.

VORAUSSETZUNGEN
Die Tabelle dbo.PageLab wird neu angelegt. Falls sie bereits existiert, vor
dem Start kontrolliert entfernen oder einen anderen Tabellennamen verwenden.
Die wiederholte Einfügung ist ein Last-/Speicherexperiment, kein Produktions-
skript.
*/

-- Wählt Northwind als Datenbankkontext.
USE [Northwind];
GO

-- Erstellt eine Tabelle mit einer Identitätsspalte und einer großen festen
-- Zeichenkettenspalte, um die Auswirkung der Zeilenbreite zu beobachten.
CREATE TABLE dbo.PageLab
(
    Id int IDENTITY(1, 1) NOT NULL,
    DataValue char(4100) NOT NULL
);
GO

-- Fügt einen Beispieldatensatz ein. GO 20000 führt den Batch im SSMS/sqlcmd-
-- Client 20.000-mal aus; dadurch entsteht absichtlich ein großes Testobjekt.
INSERT INTO dbo.PageLab (DataValue)
VALUES ('XY');
GO 20000

-- Zeigt Seiten- und Fragmentierungsinformationen für den Testindex.
-- DETAILED scannt genauer und kann bei großen Objekten zusätzliche I/O-Kosten
-- verursachen.
SELECT
    ips.index_type_desc,
    ips.alloc_unit_type_desc,
    ips.page_count,
    ips.avg_page_space_used_in_percent,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
(
    DB_ID(),
    OBJECT_ID(N'dbo.PageLab'),
    NULL,
    NULL,
    N'DETAILED'
) AS ips;
GO

/*
AUSWERTUNG
Eine große Datei trotz kleinerer Nutzdatenmenge kann durch ungenutzten Platz
in Seiten entstehen. CHAR(4100) belegt feste Breite; mehrere Zeilen passen
deshalb nicht unbedingt auf dieselbe Seite. Vergleiche page_count und
avg_page_space_used_in_percent mit einer Tabelle variabler Spaltenbreite.

DBCC SHOWCONTIG war ein früheres Diagnosewerkzeug und ist veraltet. Für neue
Analysen die DMV sys.dm_db_index_physical_stats verwenden.
*/
