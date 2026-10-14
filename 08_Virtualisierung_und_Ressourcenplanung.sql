/*
ÜBERBLICK
Dieses Dokument fasst Überlegungen zur Dimensionierung von SQL Server in
virtualisierten Umgebungen zusammen. Es enthält keine ausführbaren SQL-
Anweisungen. Die Zahlen sind Rechenbeispiele und keine Dimensionierungs-
empfehlung für einen konkreten Server.

CPU UND STORAGE
- Prüfen, ob die VM unter Last tatsächlich CPU-, RAM- und Storage-Ressourcen
  erhält. Bei virtualisierten Umgebungen zusätzlich Hostauslastung,
  CPU-Ready-/Steal-Zeit, Limits und konkurrierende VMs messen.
- Häufig ist unnötige I/O-Last ein wesentlicher Engpass. Abfragen, Indizes,
  Cachetreffer und Backup-/Wartungsjobs prüfen, bevor Storage erweitert wird.
- Datenbankdateien, Logdateien und Backups getrennt planen. Getrennte
  Laufwerksbuchstaben allein bedeuten nicht zwingend getrennte physische
  Storage-Ressourcen.
- Storage gleichzeitig nach Latenz, IOPS, Durchsatz und Kapazität bewerten.
  Die Messung muss den realen I/O-Mix sowie Spitzen- und Wartungslast abdecken.

NUMA UND CPU-ZUWEISUNG
- NUMA ordnet Prozessoren lokalen Speicherbereichen zu. Zugriffe auf den
  Speicher eines anderen Knotens können eine höhere Latenz haben.
- VM-Topologie, vCPU-Zuweisung und sichtbare NUMA-Konfiguration mit der
  tatsächlichen Hosttopologie und den SQL-Server-Anforderungen abgleichen.
- Mehr vCPUs lösen keinen Engpass durch langsame Einzelthreads oder
  Hostkonkurrenz automatisch. Abfragepläne und Scheduler-Waits ergänzend prüfen.

RAM-PLANUNG
Beispiel: Ein Host mit 16 GB RAM könnte 4 GB für Windows reservieren, 2 GB
einem Domänencontroller zuweisen und den verbleibenden Speicher auf SQL-VMs
verteilen. Die Reserven für Betriebssystem, Agenten, Backupsoftware und
Spitzenbedarf müssen konkret gemessen werden. Dynamischen VM-Speicher und
Ballooning/Swapping ebenfalls berücksichtigen.

CHECKLISTE
- Lastprofil einschließlich Wartung, Wachstum und Ausfallbetrieb messen.
- SQL-Version, Edition, Kompatibilitätsgrad, MAXDOP und Speicherlimits
  dokumentieren.
- Vor und nach Änderungen Antwortzeit, CPU, I/O und Waits unter vergleichbarer
  Last gegenüberstellen.
- Hardware- bzw. VM-Erweiterungen erst nach Ursachenanalyse dimensionieren.
*/
