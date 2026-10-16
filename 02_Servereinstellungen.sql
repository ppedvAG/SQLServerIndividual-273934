/*
ÜBERBLICK
Diese Datei enthält praktische Hinweise zur Konfiguration einer SQL-Server-
Instanz nach der Installation. Sie besteht aus Erläuterungen und Beispielen,
nicht aus ausführbaren Einstellungsbefehlen. Die konkreten Werte sind anhand
der installierten SQL-Server-Version und der gemessenen Arbeitslast festzulegen.

DIENSTKONTEN UND WINDOWS
- Für SQL Server und SQL Server Agent getrennte, möglichst verwaltete
  Dienstidentitäten mit minimalen Rechten verwenden. Zugriff auf Netzwerkziele
  wie Backupfreigaben muss explizit eingerichtet und getestet werden.
- Das Recht „Perform volume maintenance tasks“ ermöglicht Instant File
  Initialization für geeignete Datenbankdateien. Es kann das Wachstum von
  Datendateien beschleunigen, gilt aber nicht pauschal für alle Dateien und
  Versionen; insbesondere gelten für Transaktionslogdateien Einschränkungen.
  Das benötigte Windows-Recht gezielt und nach Sicherheitsvorgaben vergeben.

SERVEROPTIONEN
- MAXDOP begrenzt den Parallelitätsgrad einer Abfrage. Die sinnvolle Einstellung
  hängt von NUMA-Topologie, CPU-Anzahl und Workload ab; siehe 03_MAXDOP.sql.
  zu berücksichtigen ist auch der Kostenschwellenwert, ab dem Parallelismus erst 
  verwedent wird. per Default auf 5 eingestellt ist das deutlich zu niederig.
  Für OLTP eignen sich meist höhere Werte wie 50 und für OLAP eher 25. 
  Aber den! korrekten Werte muss man bei sich herausfinden.
- „max server memory“ so setzen, dass Betriebssystem, Agent und weitere
  Anwendungen ausreichend Speicher behalten. Der benötigte Puffer ist
  host- und workloadabhängig. „min server memory“ reserviert nicht sofort RAM
  und ist vor allem bei mehreren Instanzen gezielt zu bewerten.

TEMPDB
- tempdb unterstützt temporäre Tabellen, Version Store und interne
  Arbeitsbereiche. Anfangsgröße und Autogrowth-Schritt planbar wählen und
  Wachstum überwachen.
- Gleich große Datendateien mit gleichen Wachstumsschritten sind eine übliche
  Ausgangsbasis. Die passende Anzahl wird anhand von Contention und Last
  bestimmt; „eine Datei pro CPU, maximal acht“ ist keine allgemeingültige Regel.
- Trace Flags 1117 und 1118 sind für moderne SQL-Server-Versionen ab SQL Server
  2016 nicht pauschal erforderlich; ihr Verhalten wurde für Benutzerdatenbanken
  integriert bzw. geändert. Vor Einsatz die Versionsdokumentation prüfen.

PRAXISBEISPIEL
Die nachfolgenden VM-Werte sind lediglich ein Rechenbeispiel: Bei 16 GB
Hostspeicher könnten etwa 4 GB für Windows und 2 GB für einen Domänencontroller
reserviert werden. Die verbleibenden Ressourcen werden nicht automatisch
gleichmäßig auf SQL-Instanzen verteilt. Kapazität, Reserve und Spitzenlast
messen und die Datenbankeinstellungen nach einer VM-Anpassung überprüfen.

WEITERE THEMEN
Die Einstellung der SQL-Datenbankoptionen ist in 04_Datenbankeinstellungen.sql
beschrieben. Datenbankpfade und Backups müssen zur konkreten Speicher- und
Wiederherstellungsstrategie passen.
*/
