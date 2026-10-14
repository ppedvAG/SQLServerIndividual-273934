/*
ÜBERBLICK
MAXDOP (max degree of parallelism) begrenzt, wie viele Prozessoren SQL Server
für einen parallelen Ausführungsplan einer einzelnen Abfrage verwenden darf.
Der Wert ist eine Obergrenze und keine Zusage, dass alle diese Prozessoren
verwendet werden. Der Abfrageoptimierer entscheidet anhand des Plans und der
Kosten, ob parallel ausgeführt wird.

WIE DIE EINSTELLUNGEN ZUSAMMENSPIELEN
- Serveroption, datenbankbezogene Einstellung und Abfragehinweis bilden
  Obergrenzen. Die Abfrage kann diese Grenzen weiter einschränken; ein
  MAXDOP-Hinweis sollte nicht ohne Messung pauschal eingesetzt werden.
- MAXDOP = 0 lässt SQL Server grundsätzlich alle verfügbaren Prozessoren
  berücksichtigen; versions- und plattformabhängige Grenzen gelten weiterhin.
  Microsofts Empfehlungen für den Wert hängen unter anderem von NUMA und
  Prozessorgruppen ab. „8“ ist keine universelle Standardeinstellung.
- Ein hoher DOP kann die verstrichene Zeit senken, aber CPU-Verbrauch und
  Konkurrenz erhöhen. Vergleiche deshalb Antwortzeit, CPU-Zeit, I/O und
  gleichzeitige Last; wiederhole Messungen unter repräsentativen Bedingungen.
- Ab SQL Server 2022 kann Degree of Parallelism Feedback geeignete
  wiederkehrende Abfragen anpassen, sofern Version, Kompatibilitätsgrad und
  Konfiguration dies unterstützen. Das bedeutet nicht, dass jede Abfrage
  automatisch mit einer variablen Kernzahl ausgeführt wird.

VORAUSSETZUNGEN
Das Beispiel verwendet die Datenbank Northwind und die Tabelle KU. Passe den
Datenbank- und Tabellennamen an deine Umgebung an. STATISTICS IO/TIME liefert
Metriken für die jeweilige Verbindung; die Ausgabe wird im Client angezeigt.
*/

-- Aktiviert für diese Verbindung die Anzeige von logischen/physikalischen
-- Lesevorgängen sowie CPU- und verstrichener Zeit der folgenden Abfragen.
SET STATISTICS IO, TIME ON;

-- Gruppiert Frachtkosten nach Land und Stadt. Der Abfragehinweis begrenzt
-- diese Abfrage auf höchstens sechs Prozessoren.
SELECT
    ShipCountry,
    ShipCity,
    SUM(Freight) AS TotalFreight
FROM dbo.KU
GROUP BY
    ShipCountry,
    ShipCity
OPTION (MAXDOP 6);

/*
Die folgenden Werte sind historische Beispielmessungen, keine allgemeingültige
Leistungsgarantie:
- Bei 8 Kernen: CPU-Zeit 923 ms, verstrichene Zeit 144 ms
- Bei 4 Kernen: CPU-Zeit 625 ms, verstrichene Zeit 166 ms
- Bei 1 Kern: CPU-Zeit 406 ms, verstrichene Zeit 419 ms
Verstrichene Zeit und CPU-Zeit unterscheiden sich bei paralleler Ausführung,
weil mehrere Worker gleichzeitig CPU-Zeit verbrauchen können.
*/

-- Zeigt kumulierte Wait-Statistiken der Instanz. Für eine belastbare Diagnose
-- zwei zeitlich getrennte Snapshots vergleichen und den SQL-Neustart beachten.
SELECT
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type LIKE N'CX%'
ORDER BY wait_time_ms DESC;

-- Wiederholt dieselbe Aggregation mit einer Obergrenze von acht Prozessoren,
-- um die Messwerte mit dem vorigen Lauf zu vergleichen.
SELECT
    Country,
    City,
    SUM(Freight) AS TotalFreight
FROM dbo.KU
GROUP BY
    Country,
    City
OPTION (MAXDOP 8);

-- Wechselt in master; der folgende USE-Befehl wechselt anschließend nach
-- Northwind. GO beendet jeweils den aktuellen Batch im SSMS/sqlcmd-Client.
USE [master];
GO

-- Wählt die Beispieldatenbank aus. Ändere dies, falls sie anders benannt ist.
USE [Northwind];
GO

-- Legt für diese Datenbank eine MAXDOP-Obergrenze von vier fest.
-- Diese Datenbankoption wird von unterstützten Abfragen berücksichtigt.
ALTER DATABASE SCOPED CONFIGURATION
SET MAXDOP = 4;
GO
