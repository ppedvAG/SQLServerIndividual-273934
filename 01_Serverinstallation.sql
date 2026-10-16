/*
ÜBERBLICK
Dieses Dokument sammelt Planungs- und Sicherheitsaspekte für die Installation
einer SQL-Server-Instanz. Es ist kein Installationsskript: Die Notizen müssen
an Version, Edition, Betriebssystem, Anwendung und Unternehmensrichtlinien
angepasst werden.

PLANUNG UND PRAXISTIPPS
- Zuerst Anwendungslast, Wachstum, Verfügbarkeit und Wiederherstellungsziele
  klären. Anschließend CPU, RAM und Storage anhand repräsentativer Messungen
  dimensionieren; ausreichend RAM allein verhindert keine I/O-Engpässe.
- Windows- und gemischte Authentifizierung bewusst auswählen. Windows-
  Authentifizierung bevorzugen, wenn sie zur Umgebung passt. Das eingebaute
  sa-Konto deaktivieren oder streng verwalten; kein Ersatzkonto mit einem
  fest eingetragenen Kennwort verwenden.
- SQL-Server-Dienstkonten nach dem Prinzip der geringsten Rechte einrichten.
  Verwaltete Dienstkonten sind häufig geeigneter als lokale Konten, wenn
  Netzwerkzugriffe wie Backups benötigt werden.
- Dienste wie SQL Server Agent, Volltextsuche und SQL Server Browser nur
  installieren bzw. aktivieren, wenn sie benötigt werden. Firewallregeln
  auf erforderliche Ports und Quellnetze begrenzen.
- Daten-, Transaktionslog-, tempdb- und Backup-Pfade planen. Getrennte
  Laufwerke helfen nur dann, wenn sie auch getrennte Storage-Ressourcen
  nutzen. Backups auf demselben Datenträger schützen nicht vor dessen Ausfall.
- tempdb wird unter anderem für temporäre Objekte, Sortierungen und
  Zeilenversionierung verwendet. Größe und Dateianzahl passend zur SQL-Version
  und gemessenen Last planen; keine veralteten Trace-Flag-Empfehlungen blind
  übernehmen.
- Die folgenden Abfragen sind Beispiele und setzen die jeweilige Tabelle bzw.
  Datenbank voraus. Sie geben keine Installationseinstellungen vor.
*/

-- Was leistet die Volltextsuche?
--Sie kann Maiers finden :-)
-- Sucht in einer vorhandenen Tabelle nach Familiennamen, die mit „maier“ beginnen.
-- Die Tabelle und Spalte müssen im aktuellen Datenbankkontext vorhanden sein.
--Volltextsuche ist sehr flexibel , wenn es um Suche innerhalb von  Texten geht.
--Die Siche mit Like ist nur dann sehr schnell, wenn wir von Position 1 aus suchen
SELECT *
FROM dbo.Kunden
WHERE FamName LIKE N'maier%'; --oder Meyr, oder Mair..

-- Ermittelt den Soundex-Code für eine beispielhafte Schreibweise.
SELECT SOUNDEX(N'maier') AS SoundexMaier;

-- Vergleicht den Soundex-Code einer abweichenden Schreibweise.
SELECT SOUNDEX(N'meyr') AS SoundexMeyr;
