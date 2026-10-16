/*
SQL SERVER: PERFMON, WAITSTATS, BASELINE UND HARDWARESIZING
Stand: 13.10.2026 | SQL Server unter Windows

Diese SQL-Datei ist ein kommentiertes Nachschlagewerk. Sie führt keine Abfragen
oder Änderungen aus. Windows-Counter und SQL-Waittypen werden getrennt benannt.

MESSPLAN UND BEWERTUNG
- Mindestens 2–4 repräsentative Wochen inklusive Spitzen, ETL, Backups, CHECKDB,
  Indexwartung und Monatsabschluss messen; bei seltenen Spitzen länger.
- Perfmon-Abstand 15 Sekunden als Startpunkt, kurzfristige Diagnose 1–5 Sekunden.
  Zeitstempel, Zeitzone, Instanz, Datenbank, Volume und CPU/NUMA erfassen.
- Normalbetrieb, Spitzen und Wartung getrennt betrachten. Anwendungsantwortzeit,
  Fehler und fachlichen Durchsatz ergänzen: Hardwarewerte allein genügen nicht.
- Mittel, P50, P95, P99, Maximum und Dauer der Grenzwertüberschreitungen auswerten.
  P95 bedeutet: 95 % der Messwerte liegen höchstens bei diesem Wert.
  P95 der Intervallmittelwerte ist NICHT P95 der einzelnen I/O-Operationen.
- [PLAN] kennzeichnet eigene Start-/Orientierungswerte, keine Herstellerlimits.
  Sie müssen an Last, SLA und eine gesunde Vergleichsbaseline angepasst werden.
  Wiederholte Überschreitungen über 5–15 Minuten untersuchen; bei SLA-Verletzung
  sofort reagieren. Ein grüner Wert schließt andere Engpässe nicht aus.
- Englische Perfmon-Pfade: lokalisierte Namen vor Ort prüfen. SQLServer: gilt für
  die Standardinstanz; benannte Instanzen meist MSSQL$INSTANZ:... . sqlservr-PID
  eindeutig der gewünschten Instanz zuordnen.
- SQL-Counter gibt es in sys.dm_os_performance_counters, Windows-Counter nicht
  vollständig. cntr_value ist je nach cntr_type Rohwert, nicht automatisch Rate:
  Rate = Delta(Zähler)/Delta(Sekunden); Quoten brauchen Base-Counter, Mittelwerte
  die passenden Zähler-/Base-Deltas. Perfmon bereitet diese Werte bereits auf.
- Waitstats und Datei-I/O aus zwei Snapshots als Deltas auswerten. Neustarts,
  Reset, Reattach und negative Deltas erkennen; keine globale Waitstat-Rücksetzung.
  Wait-ms/Wait = Delta(wait_time_ms)/Delta(waiting_tasks_count).
  Datei-Lese-ms = Delta(io_stall_read_ms)/Delta(num_of_reads), Schreiben analog.
  Bei Nenner 0 keinen Durchschnitt berechnen. Parallelworker warten gleichzeitig:
  summierte Waitzeit ist keine verstrichene Uhrzeit.
- Byte/s /1024² = MiB/s; KB-Counter hier als KiB interpretieren; sec *1000 = ms.
- Bei VMs Hostlast, CPU-Ready/Steal, RAM-Ballooning/Swapping und Limits ergänzen.

QUELLEN: Microsoft Learn. Definitionen/Diagnose stammen aus diesen Quellen;
Zahlen mit [PLAN] sind ausdrücklich eigene Planungsannahmen.
[CPU] https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-high-cpu-usage-issues
[MEM] https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-memory-manager-object
[BUF] https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-buffer-manager-object
[GRANT] https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-memory-grant-issues
[IO] https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-sql-io-performance
[WAIT] https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-wait-stats-transact-sql
[NET] https://learn.microsoft.com/en-us/troubleshoot/sql/database-engine/performance/troubleshoot-query-async-network-io
[TEMP] https://learn.microsoft.com/en-us/sql/relational-databases/databases/tempdb-database
[COUNTER] https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-performance-counters-transact-sql
[DB] https://learn.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-databases-object
[CONFIG] https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/server-memory-server-configuration-options
*/

/*
01 | CPU
Name: % Processor Time
Erfassung: Perfmon \Processor(_Total)\% Processor Time; zusätzlich je Prozessor.
Beschreibung: Beschäftigung der Windows-Prozessoren; _Total ist über CPUs gemittelt.
Einheit: Prozent, _Total 0–100.
Grenzwerte: [PLAN] <70 % Reserve; 70–85 % prüfen; >85 % anhaltend zusammen mit
  Warteschlangen oder verletztem Antwortzeitziel kritisch.
Erläuterung: Einzelne ausgelastete Kerne können bei niedrigem Gesamtwert einen
  seriellen Engpass zeigen. Mit SQL-Prozesslast und Runnable Tasks korrelieren.
Maßnahme / Hardware: Teure Abfragen, Indizes, Pläne und Fremdprozesse prüfen.
  CPU erst bei bestätigter Sättigung ausbauen; Einzelkernleistung beachten.
Quelle: [CPU]
*/

/*
02 | CPU
Name: Process(sqlservr) – % Processor Time
Erfassung: Perfmon \Process(sqlservr*)\% Processor Time; PID zuordnen.
Beschreibung: CPU-Nutzung der konkreten SQL-Server-Instanz.
Einheit: Prozent; klassischer Process-Counter kann 100 * logische CPUs erreichen.
Grenzwerte: Zum Hostvergleich durch Anzahl der bereitgestellten logischen CPUs
  teilen. [PLAN] Danach 70/85 % als Startorientierung wie in Eintrag 01.
Erläuterung: CPU-Affinität und VM-Limits können nutzbare Kapazität reduzieren.
  Host hoch / SQL niedrig deutet auf Fremdlast oder andere Instanzen hin.
Maßnahme / Hardware: Query Store, CPU-Zeit/Abfrage, logische Reads und Compilations
  prüfen. Bei Fremdlast zuerst Hostkonkurrenz beseitigen.
Quelle: [CPU]
*/

/*
03 | CPU – ergänzende DMV
Name: runnable_tasks_count
Erfassung: sys.dm_os_schedulers, nur status = VISIBLE ONLINE; je Scheduler.
Beschreibung: Ausführbare SQL-Worker, die auf CPU-Zuteilung warten.
Einheit: Anzahl, Momentaufnahme.
Grenzwerte: Ziel häufig 0. [PLAN] Wiederholt >1 je Scheduler untersuchen;
  anhaltend >2 plus hohe CPU/SLA-Probleme dringend. Kein Herstellerlimit.
Erläuterung: Mittelwerte über alle Scheduler können NUMA-/Lastungleichheit verdecken.
Maßnahme / Hardware: CPU-intensive Abfragen, Parallelität und VM-Scheduling prüfen.
  Zusammen mit hoher CPU belastbarer Hinweis für zusätzliche CPU-Kapazität.
Quelle: [CPU], [WAIT]
*/

/*
04 | CPU
Name: Processor Queue Length
Erfassung: Perfmon \System\Processor Queue Length.
Beschreibung: Windows-Threads, die auf Prozessorzeit warten.
Einheit: Anzahl; hostweite Momentaufnahme.
Grenzwerte: Kein universeller Grenzwert. Anhaltend wachsende Queue bei hoher CPU
  und schlechter Antwortzeit auffällig. Nicht pauschal 2 pro Kern verwenden.
Erläuterung: Enthält auch Nicht-SQL-Threads; nicht mit SQL Runnable Tasks gleichsetzen.
Maßnahme / Hardware: Mit Prozesslast, Einzelkernlast und Hypervisorwerten bestätigen;
  CPU-Zuteilung/Fremdlast/Abfragen prüfen, erst danach Kerne dimensionieren.
Quelle: [CPU]
*/

/*
05 | Lastprofil
Name: Batch Requests/sec
Erfassung: Perfmon \SQLServer:SQL Statistics\Batch Requests/sec.
Beschreibung: Eingehende T-SQL-Batches pro Sekunde.
Einheit: Batches/s.
Grenzwerte: Kein fixer Grenzwert. Gesunde Baseline und Lasttrend dokumentieren.
Erläuterung: Batches unterscheiden sich stark im Aufwand. Eine höhere Batchrate
  bedeutet nicht automatisch mehr nutzbaren fachlichen Durchsatz.
Maßnahme / Hardware: CPU-Sekunden und I/O pro vergleichbarem Geschäftsvorgang
  messen. Für Migration Lastmix, Gleichzeitigkeit und Wachstum dokumentieren.
Quelle: [CPU], [COUNTER]
*/

/*
06 | CPU / Planwiederverwendung
Name: SQL Compilations/sec und SQL Re-Compilations/sec
Erfassung: Perfmon \SQLServer:SQL Statistics\SQL Compilations/sec bzw.
  \SQLServer:SQL Statistics\SQL Re-Compilations/sec.
Beschreibung: Planübersetzungen bzw. erneute Statementübersetzungen.
Einheit: Ereignisse/s.
Grenzwerte: Kein fixer Grenzwert. [PLAN] Compilations/Batch Requests >10 % bei
  CPU-Problemen untersuchen; bei Batchrate 0 keinen Quotienten berechnen.
Erläuterung: Nur Heuristik, keine exakte Wiederverwendungsquote. Ad-hoc-Last,
  OPTION(RECOMPILE), Statistik-/Schemaänderungen beeinflussen Werte.
Maßnahme / Hardware: Parametrisierung und Recompile-Ursachen prüfen. Mehr CPU
  kompensiert Planmissbrauch nur vorübergehend.
Quelle: [CPU], [COUNTER]
*/

/*
07 | RAM / Windows
Name: Available MBytes
Erfassung: Perfmon \Memory\Available MBytes.
Beschreibung: Für neue Anforderungen verfügbarer physischer Windows-Speicher.
Einheit: MiB; zusätzlich Prozent des sichtbaren physischen RAM.
Grenzwerte: [PLAN] >10 % Reserve; 5–10 % prüfen; <5 % anhaltend plus Paging oder
  OS-Speicherdruck kritisch. Absolute OS-Reserve passend zur Servergröße prüfen.
Erläuterung: SQL nutzt RAM absichtlich. Wenig verfügbarer RAM allein beweist
  keinen Mangel. Mit Grants, Paging und max server memory betrachten.
Maßnahme / Hardware: Reserve für OS/Agent/Backup/Fremddienste sicherstellen.
  RAM bei nachgewiesenem Speicherbedarf ausbauen, Speicherlimit prüfen.
Quelle: [CONFIG]
*/

/*
08 | RAM / Workspace
Name: Memory Grants Pending
Erfassung: Perfmon \SQLServer:Memory Manager\Memory Grants Pending.
Beschreibung: Abfragen, die auf Speicher für Sort-/Hashoperationen warten.
Einheit: Anzahl wartender Prozesse.
Grenzwerte: Ziel 0; wiederholt >0 untersuchen. Dringlichkeit nach Wartezeit/SLA,
  nicht nach einem universellen roten Anzahlwert.
Erläuterung: Mit RESOURCE_SEMAPHORE und Grantgrößen lesen. Falsche Kardinalität,
  sehr große Grants, hohe Gleichzeitigkeit oder Resource-Governor-Limits möglich.
Maßnahme / Hardware: Pläne, Statistiken, Indizes und Gleichzeitigkeit optimieren;
  RAM nur nach Prüfung von Bedarf und Konfigurations-/Editionsgrenzen erweitern.
Quelle: [MEM], [GRANT]
*/

/*
09 | RAM / Workspace
Name: Granted Workspace Memory (KB)
Erfassung: Perfmon \SQLServer:Memory Manager\Granted Workspace Memory (KB).
Beschreibung: Umfang des aktuell gewährten Workspace Memory.
Einheit: KiB; /1024² = GiB.
Grenzwerte: Kein fixer Grenzwert. Hohe Werte mit Pending Grants und Wartezeit prüfen.
Erläuterung: Gewährter Speicher ist nicht vollständig tatsächlich genutzt.
  Ein einzelner übergroßer Grant kann andere Abfragen verdrängen.
Maßnahme / Hardware: sys.dm_exec_query_memory_grants mit requested/granted/used/
  max_used ergänzen. Grantspitzen getrennt vom Cachebedarf für RAM modellieren.
Quelle: [MEM], [GRANT]
*/

/*
10 | RAM / SQL Memory Manager
Name: Total Server Memory (KB) und Target Server Memory (KB)
Erfassung: Perfmon \SQLServer:Memory Manager\Total Server Memory (KB) bzw.
  \SQLServer:Memory Manager\Target Server Memory (KB).
Beschreibung: Zugesagter SQL-Speicher und aktueller Speicherzielwert.
Einheit: KiB.
Grenzwerte: Kein universelles Sollverhältnis. Total nahe Target ist nach Warm-up
  normal. Eine Differenz nur mit tatsächlicher Nachfrage und Druck bewerten.
Erläuterung: Startphase und kalter Cache beeinflussen Werte. Total ist nicht der
  gesamte Prozessspeicher. Total=Target beweist keinen zusätzlichen RAM-Bedarf.
Maßnahme / Hardware: Speicherlimit, Edition, OS-Druck und Prozessspeicher prüfen;
  RAM nicht allein aus diesem Verhältnis ableiten.
Quelle: [MEM], [CONFIG]
*/

/*
11 | RAM / Daten-Cache
Name: Page life expectancy (PLE)
Erfassung: Perfmon \SQLServer:Buffer Manager\Page life expectancy;
  zusätzlich \SQLServer:Buffer Node(*)\Page life expectancy je NUMA-Knoten.
Beschreibung: Indikator für Seitenverweildauer im Buffer Pool ohne erneute Referenz.
Einheit: Sekunden.
Grenzwerte: Kein allgemeiner 300-Sekunden-Grenzwert. [PLAN] Wiederholt <50 % der
  gesunden Vergleichsbaseline prüfen; <20 % plus Reads/SLA-Problemen dringend.
Erläuterung: Scans, Wartung und Neustart senken PLE. Nur vergleichbare Lastfenster
  gegenüberstellen; ein Gesamtwert kann einzelne NUMA-Probleme verdecken.
Maßnahme / Hardware: Unnötige Scans und Cacheverdrängung prüfen. RAM hilft, wenn
  der regelmäßig benötigte Arbeitsdatensatz nicht ausreichend im Cache bleibt.
Quelle: [BUF]
*/

/*
12 | RAM / Cacheverdrängung
Name: Lazy writes/sec
Erfassung: Perfmon \SQLServer:Buffer Manager\Lazy writes/sec.
Beschreibung: Dirty Buffers, die der Lazy Writer für wiederverwendbare Buffer schreibt.
Einheit: Buffer/s.
Grenzwerte: Kein fixer Grenzwert; anhaltender Anstieg zur Baseline zusammen mit
  PLE-Abfall und vielen physischen Reads auffällig.
Erläuterung: Nicht mit Checkpoint writes gleichsetzen. Einzelne Spitzen allein
  belegen keinen RAM-Mangel.
Maßnahme / Hardware: Scans, Speicherlimit und OS-Druck prüfen. RAM erst bei
  bestätigtem Cache-Druck erweitern.
Quelle: [BUF]
*/

/*
13 | RAM / I/O-Last
Name: Page reads/sec und Page writes/sec
Erfassung: Perfmon \SQLServer:Buffer Manager\Page reads/sec bzw. Page writes/sec.
Beschreibung: Physische Datenbankseiten, die SQL liest bzw. schreibt.
Einheit: 8-KiB-Seiten/s.
Grenzwerte: Kein fixer Grenzwert; gegen Baseline, Latenz und Lastvolumen bewerten.
Erläuterung: Seiten/s sind nicht Storage-IOPS. Read-Ahead und zusammengefasste
  I/Os ändern die Operationsgrößen; Writes auch durch Checkpoints.
Maßnahme / Hardware: Bei unnötigen Reads Pläne/Indizes und Cachebedarf prüfen.
  Für Storage-Sizing echte Datei-I/O-Operationen und Bytevolumen ergänzen.
Quelle: [BUF], [IO]
*/

/*
14 | RAM / Cachequote
Name: Buffer cache hit ratio
Erfassung: Perfmon \SQLServer:Buffer Manager\Buffer cache hit ratio;
  bei DMV-Rohwerten den zugehörigen Base-Counter berücksichtigen.
Beschreibung: Anteil der gesuchten Seiten, die im Daten-Cache gefunden werden.
Einheit: Prozent.
Grenzwerte: Kein belastbarer fixer Sizing-Grenzwert. Auch >99 % kann bei sehr
  vielen logischen Reads erhebliche physische I/O bedeuten.
Erläuterung: Langer kumulativer Zeitraum kann kurzfristigen Druck verdecken.
Maßnahme / Hardware: PLE, physische Reads, Latenz und Abfragepläne ergänzen.
  RAM nicht allein aus der Hit Ratio berechnen.
Quelle: [BUF], [COUNTER]
*/

/*
15 | RAM / Betriebssystem
Name: Pages Input/sec und Pages Output/sec
Erfassung: Perfmon \Memory\Pages Input/sec bzw. Pages Output/sec.
Beschreibung: Einlesen bei Hard Faults bzw. Auslagern zum Freimachen von RAM.
Einheit: Speicherseiten/s.
Grenzwerte: Kein fixer Grenzwert. Dauerhaft erhöht plus Available-RAM-Mangel
  und schlechter Antwortzeit untersuchen.
Erläuterung: Hard Faults können auch dateibasierte Seiten betreffen. Pages/sec
  allein beweist kein Pagefile-Paging des SQL Buffer Pools; Page Faults/sec
  enthält zusätzlich Soft Faults.
Maßnahme / Hardware: Prozessspeicher, Working Set und Pagefile-I/O prüfen.
  OS-Reserve korrigieren, bei realem hostweitem Druck RAM erweitern.
Quelle: [CONFIG]
*/

/*
16 | Datenträger / Datenlesen
Name: Avg. Disk sec/Read
Erfassung: Perfmon \LogicalDisk(*)\Avg. Disk sec/Read; alternativ PhysicalDisk.
Beschreibung: Mittlere Dauer der Lese-I/Os eines Messintervalls.
Einheit: Sekunden; zur Bewertung *1000 = Millisekunden.
Grenzwerte: [PLAN] <10 ms Startorientierung; 10–20 ms prüfen; >20 ms anhaltend
  mit Last-/SLA-Problemen kritisch. Microsoft nennt ca. 10–15 ms als ungefähre
  Diagnoseorientierung. Moderne SSD-Ziele können deutlich niedriger liegen.
Erläuterung: Je Volume und Datei prüfen, nicht nur _Total. Kleine Latenz im
  Leerlauf beweist keine Reserve unter Last. Counter ist ein Intervallmittelwert.
Maßnahme / Hardware: IOPS, MiB/s, Queue, PAGEIOLATCH und Datei-I/O ergänzen.
  Pfad, Limits, Nachbarlast und unnötige Reads vor Storagekauf prüfen.
Quelle: [IO]
*/


/*
17 | Datenträger / Datenschreiben
Name: Avg. Disk sec/Write – Datenvolume
Erfassung: Perfmon \LogicalDisk(Datenvolume)\Avg. Disk sec/Write.
Beschreibung: Mittlere Schreibdauer auf dem Datenvolume.
Einheit: Sekunden; *1000 = ms.
Grenzwerte: [PLAN] <10 ms, 10–20 ms prüfen, >20 ms anhaltend plus Lastproblem
  kritisch; für Flash ggf. strengere Ziele vereinbaren.
Erläuterung: Checkpoints, Backup, SAN-Cache und Filtertreiber beeinflussen Werte.
  Gemeinsame Volumes können einzelne langsame Datenbankdateien verdecken.
Maßnahme / Hardware: Datei-Deltas und Schreibdurchsatz ergänzen; Storagekonkurrenz
  reduzieren, benötigte IOPS/Bandbreite gleichzeitig mit Latenzziel bereitstellen.
Quelle: [IO]
*/

/*
18 | Datenträger / Logschreiben
Name: Avg. Disk sec/Write – Logvolume
Erfassung: Perfmon \LogicalDisk(Logvolume)\Avg. Disk sec/Write; DMV je Logdatei.
Beschreibung: Log-Schreiblatenz beeinflusst die Dauer bestätigter Transaktionen.
Einheit: Sekunden; *1000 = ms.
Grenzwerte: [PLAN] <5 ms Zielorientierung; 5–10 ms prüfen; >10 ms anhaltend plus
  WRITELOG/Commitproblemen dringend. Keine universelle Herstellergrenze.
Erläuterung: Bei gemeinsamem Volume ist Perfmon nicht logspezifisch. Kleine
  synchrone Writes benötigen niedrige Latenz, große Änderungen auch Bandbreite.
Maßnahme / Hardware: Logdateilatenz, Flushrate und Transaktionsmuster prüfen.
  Persistentes, latenzarmes Storage mit ausreichender Bandbreite vorsehen.
Quelle: [IO], [DB]
*/

/*
19 | Datenträger / IOPS
Name: Disk Reads/sec und Disk Writes/sec
Erfassung: Perfmon \LogicalDisk(*)\Disk Reads/sec bzw. Disk Writes/sec.
Beschreibung: Lese-/Schreiboperationen pro Sekunde je Volume.
Einheit: IOPS; bei DMV Delta(reads+writes)/Sekunden.
Grenzwerte: Kein allgemeines Maximum. Grenze ist die nachhaltig erreichbare
  Leistung bei vereinbarter Latenz, Blockgröße und Read/Write-Mix.
Erläuterung: Kleine Random-I/Os und große sequenzielle I/Os sind nicht gleichwertig.
  Beworbene maximale Storage-IOPS sind keine garantierte Dauerleistung.
Maßnahme / Hardware: P95/P99 und längere Spitzen messen; Zielsystem mit realem
  Mix testen. IOPS, Bandbreite und Latenzziel gleichzeitig erfüllen.
Quelle: [IO]
*/

/*
20 | Datenträger / Durchsatz
Name: Disk Read Bytes/sec und Disk Write Bytes/sec
Erfassung: Perfmon \LogicalDisk(*)\Disk Read Bytes/sec bzw. Disk Write Bytes/sec.
Beschreibung: Gelesenes bzw. geschriebenes Datenvolumen pro Sekunde.
Einheit: Byte/s; /1024² = MiB/s.
Grenzwerte: Kein fixer Grenzwert; gegen gemessene End-to-End-Leistung vergleichen.
Erläuterung: Backups, Restore, ETL und Scans können durch Bandbreite begrenzt sein.
  SAN, Controller, VM-Limits und geteilte Ressourcen gehören zum Messpfad.
Maßnahme / Hardware: Separate Spitzen- und Wartungsanforderungen planen.
  IOPS allein reichen als Storageanforderung nicht aus.
Quelle: [IO]
*/

/*
21 | Datenträger / Warteschlange
Name: Avg. Disk Queue Length / Current Disk Queue Length
Erfassung: Perfmon \LogicalDisk(*)\Avg. Disk Queue Length bzw. Current Disk Queue Length.
Beschreibung: Mittlere bzw. momentane Zahl ausstehender I/O-Anforderungen.
Einheit: Anzahl; Durchschnitt bzw. Snapshot.
Grenzwerte: Kein pauschales Limit von 2 bei RAID/SAN/NVMe. Steigende Queue
  zusammen mit steigender Latenz ist auffällig.
Erläuterung: Hohe Queue bei guter Latenz kann normale Parallelität bedeuten;
  der Counter enthält auch Nicht-SQL-I/O.
Maßnahme / Hardware: IOPS, Latenz und Limits gemeinsam prüfen. Keine Anzahl
  benötigter Datenträger aus Queue Length allein ableiten.
Quelle: [IO]
*/

/*
22 | Datenträger / Kapazität
Name: % Free Space und Free Megabytes
Erfassung: Perfmon \LogicalDisk(*)\% Free Space bzw. Free Megabytes.
Beschreibung: Noch verfügbare Kapazität auf dem Volume.
Einheit: Prozent und MiB.
Grenzwerte: [PLAN] >20 % Reserve; 10–20 % prüfen; <10 % dringend. Absolute freie
  GB, Wachstumsrate und Zeit bis Voll zusätzlich betrachten.
Erläuterung: Freier Platz im Datenbankfile ist separat vom freien Volumeplatz.
  Auch 20 % reichen bei großem Wachstum oder Wartung eventuell nicht aus.
Maßnahme / Hardware: Wachstum, Autogrowth, tempdb, Log und Backups planen.
  Kapazität vor dem nächsten großen Vorgang erweitern; nicht mit IOPS verwechseln.
Quelle: [IO], [TEMP]
*/

/*
23 | Datenbank / Loglast
Name: Log Bytes Flushed/sec und Log Flushes/sec
Erfassung: Perfmon \SQLServer:Databases(DB)\Log Bytes Flushed/sec bzw. Log Flushes/sec.
Beschreibung: Persistiertes Logvolumen und Zahl der Flushoperationen pro Sekunde.
Einheit: Byte/s und Flushes/s.
Grenzwerte: Kein fixer Grenzwert; mit Loglatenz, WRITELOG und Transaktionen lesen.
Erläuterung: Viele kleine Commits belasten Latenz, große Änderungen Bandbreite.
  Bytes/Flushes ergibt bei Nenner >0 die mittlere Flushgröße.
Maßnahme / Hardware: Unnötige Einzelcommits/Änderungen prüfen; Transaktionsgröße
  fachlich passend wählen. Logstorage für Spitzenbandbreite UND Latenz auslegen.
Quelle: [DB], [IO]
*/

/*
24 | Datenbank / Logkapazität
Name: Percent Log Used
Erfassung: Perfmon \SQLServer:Databases(DB)\Percent Log Used.
Beschreibung: Anteil des belegten Transaktionslogs.
Einheit: Prozent.
Grenzwerte: [PLAN] >70 % beobachten; >85 % prüfen; >95 % dringend bei fehlender
  Wiederverwendung oder Wachstumsreserve. Absolute Reserve zusätzlich prüfen.
Erläuterung: Lange Transaktionen, fehlende Logbackups und AG/Replikation können
  Trunkierung verhindern. log_reuse_wait_desc ist für die Ursache wichtig.
Maßnahme / Hardware: Wiederverwendungsblocker beheben, Log vorab groß genug
  anlegen. Dauerndes Shrink/Grow vermeiden; Recovery Model nicht blind ändern.
Quelle: [DB]
*/

/*
25 | tempdb – ergänzende DMVs
Name: tempdb-Dateilatenz und belegter Platz
Erfassung: sys.dm_io_virtual_file_stats, database_id=2; in tempdb zusätzlich
  sys.dm_db_file_space_usage; Perfmon Databases(tempdb) ergänzend.
Beschreibung: Latenz je Datei und Verbrauch durch User-/Internal Objects/Versionen.
Einheit: ms/I/O und MiB/GiB.
Grenzwerte: [PLAN] <5 ms Ziel; 5–10 ms prüfen; >10 ms plus Waits/SLA dringend.
  Platzbedarf nach simultaner Spitze, nächster großer Operation und Reserve.
Erläuterung: Spills, temporäre Objekte und lange Snapshot-Transaktionen erhöhen
  Bedarf. ADR kann Versionen in der Benutzerdatenbank halten; Version/Settings prüfen.
Maßnahme / Hardware: Spills/lange Transaktionen beheben; gleiche Datendateigrößen
  und feste Growth-Schritte. Schnelle SSD behebt Allocation-Latches nicht direkt.
Quelle: [TEMP], [IO]
*/

/*
26 | Netzwerk
Name: Bytes Total/sec; ergänzend Bytes Sent/sec und Bytes Received/sec
Erfassung: Perfmon \Network Interface(*)\Bytes Total/sec bzw. Sent/Received;
  Current Bandwidth für nominelle Linkrate ergänzen.
Beschreibung: Übertragene Datenmenge je Netzwerkadapter.
Einheit: Byte/s; Current Bandwidth in bit/s.
Grenzwerte: Kein universeller SQL-Grenzwert. Gegen nutzbare Richtungsbandbreite
  vergleichen; Byte/s *8 = bit/s. Bei Vollduplex Richtungen getrennt bewerten.
Erläuterung: Teaming, virtuelle NICs, Offload und Fremdlast beeinflussen Werte.
  Mit ASYNC_NETWORK_IO, Ergebnismenge und Clientverarbeitung korrelieren.
Maßnahme / Hardware: Ergebnisse verkleinern, Client/Pfad prüfen. Schnellere NIC
  nur bei bestätigter Bandbreitengrenze; SQL-CPU/RAM nicht pauschal erweitern.
Quelle: [NET]
*/

/*
27 | Netzwerk
Name: Segments Retransmitted/sec
Erfassung: Perfmon \TCPv4\Segments Retransmitted/sec; ggf. TCPv6.
Beschreibung: TCP-Segmente, die wegen fehlender Bestätigung erneut gesendet werden.
Einheit: Segmente/s, hostweit.
Grenzwerte: Möglichst gering; kein allgemeiner fester Wert. Anstieg zur gesunden
  Baseline und Retransmit-Anteil unter Last untersuchen.
Erläuterung: Keine eindeutige SQL-Zuordnung aus diesem Counter. Paketverlust,
  Endpunktüberlastung und Verzögerungen ggf. mit Netzwerk-Trace unterscheiden.
Maßnahme / Hardware: Treiber, Pfad, Drops und Client prüfen. Mehr SQL-RAM oder
  zusätzliche SQL-Kerne beheben Paketverlust nicht.
Quelle: [NET]
*/

/*
28 | SQL-Waittyp / Client – KEIN Perfmon-Counter
Name: ASYNC_NETWORK_IO
Erfassung: sys.dm_os_wait_stats; aktive Requests in sys.dm_exec_requests ergänzen.
Beschreibung: SQL Server wartet, weil der Client Ergebnisse nicht schnell genug
  abnimmt bzw. deren Empfang bestätigt.
Einheit: Delta-Wartezeit ms, Anzahl, ms/Wait; ggf. ms je fachlicher Transaktion.
Grenzwerte: Kein universeller Wert wie „unter 2“. Weniger Wartezeit je vergleichbarer
  Anfrage günstig; kritisch, wenn relevante Antwortzeitverlängerung entsteht.
Erläuterung: Große Ergebnisse, zeilenweise langsame Verarbeitung, Client-CPU/RAM/
  I/O oder Netzwerk möglich. Hoher Waitanteil beweist keinen Netzwerkengpass.
  Beispiel: Eine Million Zeilen werden übertragen und vom Client langsam formatiert.
  Hohe Client-CPU und langer ASYNC_NETWORK_IO passen zusammen; hohe SQL-CPU ist
  hierfür nicht zwingend. Langsame Clientabnahme kann Sperren länger halten.
Maßnahme / Hardware: Serverseitig filtern/aggregieren, Ergebnisse begrenzen,
  Client schneller lesen lassen. Clientlast und NIC/Retransmits prüfen; SQL-Hardware
  nicht allein aus diesem Wait erweitern.
Quelle: [NET], [WAIT]
*/

/*
29 | SQL-Waittyp / CPU
Name: SOS_SCHEDULER_YIELD
Erfassung: sys.dm_os_wait_stats.
Beschreibung: SQL-Worker hat CPU-Zeit abgegeben und wartet auf weitere Ausführung.
Einheit: Delta-ms, Anzahl, ms/Wait.
Grenzwerte: Kein fixer Grenzwert. Hoher Anteil allein kann normal sein; mit hoher
  CPU, Runnable Tasks und verletztem Antwortzeitziel bewerten.
Erläuterung: CPU-intensive Abfragen und viele logische Reads erzeugen viele Yields.
  Der Wait ist kein CPU-Prozentwert.
Maßnahme / Hardware: Abfragen/Indizes/Pläne optimieren. CPU erst bei Sättigung
  dimensionieren; bei seriellen Anteilen ist Leistung je Kern entscheidend.
Quelle: [CPU], [WAIT]
*/

/*
30 | SQL-Waittyp / RAM
Name: RESOURCE_SEMAPHORE
Erfassung: sys.dm_os_wait_stats; sys.dm_exec_query_memory_grants ergänzen.
Beschreibung: Abfrage wartet auf Workspace-Memory-Grant.
Einheit: Delta-ms, Anzahl und aktive Grantwartezeit.
Grenzwerte: Ziel keine anhaltenden produktiven Wartezeiten. Wiederholtes Auftreten
  plus Pending Grants oder SLA-Verletzung untersuchen.
Erläuterung: Überhöhte Grants, Gleichzeitigkeit oder Resource-Governor-Limits
  möglich. Nicht mit Kompilierungsspeicher-Waits gleichsetzen.
Maßnahme / Hardware: Grantgrößen, Kardinalität und Limits prüfen. RAM nur nach
  bestätigtem Bedarf innerhalb der Konfigurations-/Editionsgrenzen erweitern.
Quelle: [GRANT], [WAIT]
*/

/*
31 | SQL-Waittyp / Daten-I/O
Name: PAGEIOLATCH_SH / PAGEIOLATCH_EX
Erfassung: sys.dm_os_wait_stats; Datei-I/O-Deltas ergänzen.
Beschreibung: Warten auf Datenseiten, deren physischer I/O noch läuft.
Einheit: Delta-ms, Anzahl, ms/Wait.
Grenzwerte: Microsoft nennt ca. 10–15 ms als Orientierung für anhaltend langsame
  I/Os. ms/Wait ist jedoch kein exakter Disk-Latenzcounter; Dateilatenz ergänzen.
Erläuterung: Hohe Summe mit kleinen Einzelwartezeiten kann durch viele Reads
  entstehen. Ursache kann langsames Storage ODER zu viel Lesen/kleiner Cache sein.
Maßnahme / Hardware: Dateilatenz, PLE und physische Reads vergleichen. Gute
  Latenz: zuerst Readmenge/Cache; schlechte Latenz: Storagepfad/Überlastung prüfen.
Quelle: [IO], [WAIT]
*/

/*
32 | SQL-Waittyp / Log-I/O
Name: WRITELOG
Erfassung: sys.dm_os_wait_stats.
Beschreibung: Warten auf den Abschluss eines Log-Flush.
Einheit: Delta-ms, Anzahl, ms/Wait.
Grenzwerte: [PLAN] >5 ms Mittelwert prüfen; >10 ms anhaltend plus Commit-SLA-
  Problemen dringend; mit Logdateilatenz bestätigen, kein Herstellerlimit.
Erläuterung: Group Commit und viele kleine Transaktionen beeinflussen Anzahl
  und Dauer. Waitzeit zeigt nicht die erforderliche Logkapazität in GB.
Maßnahme / Hardware: Logvolumen/Flushrate, Dateilatenz und Transaktionsmuster
  prüfen. Latenzarmes persistentes Storage; RAM ist keine Standardantwort.
Quelle: [IO], [WAIT]
*/

/*
33 | SQL-Waittypen / Parallelität
Name: CXPACKET / CXCONSUMER / CXSYNC_PORT / CXSYNC_CONSUMER
Erfassung: sys.dm_os_wait_stats; verfügbare Typen versionsabhängig.
Beschreibung: Koordination und Synchronisation paralleler Abfrageausführung.
Einheit: Delta-ms und Anzahl je Typ.
Grenzwerte: Keine pauschale kritische Quote. Große Summen können normalen
  effizienten Parallelbetrieb begleiten.
Erläuterung: Skew, langsamer Worker, Spills und I/O können dominieren. Gleichzeitige
  Workerwartezeiten sind keine zusätzliche verstrichene Abfragelaufzeit.
Maßnahme / Hardware: Plan, Workerverteilung, Grants und I/O prüfen. MAXDOP/Cost
  Threshold nach NUMA/Last testen, nicht allein wegen dieser Waits MAXDOP=1 setzen.
Quelle: [WAIT]
*/

/*
34 | SQL-Waittyp / Sperren
Name: LCK_M_*
Erfassung: sys.dm_os_wait_stats; aktive Blocking Chains ergänzen.
Beschreibung: Warten auf inkompatible Sperren anderer Transaktionen.
Einheit: Delta-ms, aktive Blockierdauer und betroffene Sessions.
Grenzwerte: Keine allgemeine ms-Grenze; Dauer gegen fachliches Antwortzeitziel.
Erläuterung: Lange Transaktionen und langsame Clientabnahme können Sperren länger
  halten. RCSI verhindert nicht alle Konflikte, insbesondere Writer/Writer.
Maßnahme / Hardware: Blockierer, Transaktionsgrenzen und Indizes prüfen; RCSI nach
  Anwendungstest erwägen. Hardware nur bei Ressourcenursache der langen Laufzeit.
Quelle: [WAIT], [NET]
*/

/*
35 | SQL-Waittyp / In-Memory-Contention
Name: PAGELATCH_UP / PAGELATCH_EX
Erfassung: sys.dm_os_wait_stats; aktive wait_resource zur Zuordnung ergänzen.
Beschreibung: Synchronisation beim Zugriff auf bereits im Speicher liegende Seiten.
Einheit: Delta-ms, Anzahl und betroffene Ressourcen.
Grenzwerte: Keine allgemeine Grenze; relevante wiederholte Wartezeit untersuchen.
Erläuterung: PAGELATCH ist NICHT PAGEIOLATCH. Möglich sind tempdb-Allocation-
  Contention oder Hot Pages in Benutzerdatenbanken.
Maßnahme / Hardware: Ressource zuordnen; tempdb-Dateikonfiguration oder Hot-Page-
  Design prüfen. Schnellere SSD löst einen Speicher-Latch nicht direkt.
Quelle: [WAIT], [TEMP]
*/

/*
36 | SQL-Waittyp / Worker
Name: THREADPOOL
Erfassung: sys.dm_os_wait_stats; aktive Tasks/Requests ergänzen.
Beschreibung: Aufgabe wartet auf einen verfügbaren SQL-Worker.
Einheit: Delta-ms, Anzahl und aktive wartende Aufgaben.
Grenzwerte: Ziel keine anhaltenden produktiven THREADPOOL-Waits; bei vielen
  betroffenen Anfragen dringend.
Erläuterung: Blocking, lange Requests, hohe Gleichzeitigkeit und Parallelität
  können Worker binden. Bedeutet nicht automatisch zu wenig CPU-Kerne.
Maßnahme / Hardware: Blocking/Gleichzeitigkeit/Parallelität beheben. max worker
  threads nicht blind erhöhen; CPU/RAM nach Ursachenanalyse dimensionieren.
Quelle: [WAIT]
*/

/*
37 | Abgeleiteter Wait-Indikator / CPU
Name: Signal-Wait-Anteil
Erfassung: Summe Delta(signal_wait_time_ms) / Summe Delta(wait_time_ms) *100.
Beschreibung: Anteil der Wartezeit nach Freigabe der Ressource bis CPU-Ausführung.
Einheit: Prozent; gleiche dokumentierte Wait-Auswahl, Nenner >0.
Grenzwerte: Kein allgemeiner Grenzwert. [PLAN] >20 % als Zusatzsignal prüfen,
  nicht allein als rote CPU-Bewertung verwenden.
Erläuterung: Idle-/Background-Waits konsistent herausfiltern. Wenig Gesamtwartezeit
  kann eine hohe, praktisch unbedeutende Quote erzeugen.
Maßnahme / Hardware: Mit CPU/Runnable Tasks bestätigen. Keine Kernberechnung
  aus dieser Quote; Abfragen und VM-Zuteilung prüfen.
Quelle: [WAIT]
*/

/*
ENTSCHEIDUNGSREGELN FÜR DIE MIGRATION
CPU hoch + SQL-CPU hoch + Runnable Queue + CPU-intensive langsame Abfragen:
  zuerst optimieren, danach zusätzliche/schnellere CPU bewerten.
Pending Grants/RESOURCE_SEMAPHORE oder Cacheverdrängung mit vielen Reads:
  Grants, Pläne, OS-Reserve prüfen, verbleibenden RAM-Bedarf messen.
Dateilatenz hoch + I/O-Waits + Last/Queue:
  Pfad/Limits/Nachbarlast prüfen, Storagebedarf nach Mix bestimmen.
ASYNC_NETWORK_IO, LCK_M_* oder PAGELATCH_* allein:
  zuerst Client/Blocking/Contention diagnostizieren, kein pauschaler Hardwarekauf.

RECHENMODELLE [PLAN] – DURCH LASTTEST ZU BESTÄTIGEN
CPU-Einheiten neu >= alte Einheiten * SQL-Auslastung * Lastfaktor
                    / Zielauslastung / relative Leistung je neuer Einheit.
Beispiel: 16 *0,75 *1,15^3 /0,65 /1,25 = 22,46 => ca. 24 Einheiten planen.
  15 % jährliches Lastwachstum, 3 Jahre, 65 % Zielauslastung sind Annahmen.
  Relative Leistung 1,25 muss aus repräsentativem Test stammen. Physische Kerne,
  logische CPUs und vCPUs sind nicht austauschbar; SMT, NUMA, Lizenz/Edition
  berücksichtigen. Serielle Last skaliert nicht linear mit mehr Kernen.

RAM neu = benötigter heißer Daten-/Index-Cache + Spitzen-Workspace/weitere SQL-
          Komponenten + OS/Agent/Backup/Fremddienste + Wachstumsreserve.
  DB-Dateigröße ist kein RAM-Bedarf. Gesättigter aktueller Speicher zeigt nur die
  Zuteilung; zusätzliche Nachfrage mit mehreren Speicherstufen unter gleicher Last
  testen. max server memory begrenzt nicht jede SQL-Prozessallokation.

IOPS neu >= relevante gemessene Spitzen-IOPS * Lastfaktor / Zielkapazitätsanteil.
MiB/s neu analog und separat; vereinbarte Latenz gleichzeitig erfüllen.
Beispiel: 12.000 *1,15^3 /0,70 = 26.072,14 => mindestens ca. 26.073 IOPS.
          250 MiB/s *1,15^3 /0,70 = 543,17 => mindestens ca. 544 MiB/s.
  70 % ist eigene Reserveannahme. Mit realem Mix/Blockgrößen/synchronen Logwrites
  lang genug testen, damit kurzer Cacheeffekt nicht als Dauerleistung gilt.
  P95 lässt seltene Spitzen aus: P99, Spitzenzeiträume und SLA ergänzen.
  Separat ermittelte P95 verschiedener Volumes nicht blind summieren; gemeinsame
  Storageanforderungen aus zeitgleich gemessenen, aggregierten Reihen bestimmen.

Kapazität neu >= Daten + Indizes + Logspitzen + tempdb-Spitzen + Wartungs-/
                Wachstumsbedarf + lokal benötigte Backups + Reserve.
  Log nach größter Transaktion/Indexwartung und möglichem Backup-/AG-Rückstau.
  tempdb nach simultaner Spitze, Version Store und Growthreserve.
  Ausfallbetrieb mitplanen: verbleibender Knoten muss zusätzliche Last bewältigen.

VORHER/NACHHER-ABNAHME
CPU-Generation/Kerne/vCPU/NUMA, RAM, SQL-Version/Edition/CU, MAXDOP, max server
memory, Dateiverteilung und Storage-/VM-Limits dokumentieren. Bei vergleichbarer
Datenmenge, Parallelität und Lastmix nach Warm-up Antwortzeit, CPU-Sekunden je
Vorgang, I/O und Waits vergleichen; kalte Starts separat testen. Dimensionierung
gilt erst als bestätigt, wenn vereinbarte Ziele auch mit Wachstum, Wartung und
vorgesehenem Ausfallbetrieb erreichbar sind.
*/
