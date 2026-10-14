/*
ÜBERBLICK
Dieses Skript demonstriert zentrale Datenbankobjekte anhand der Northwind-
Datenbank: Views, gespeicherte Prozeduren und benutzerdefinierte Funktionen.
Die Objekte kapseln Abfragen, sind aber keine automatische Garantie für
bessere Leistung. Vor dem Ausführen Datenbank und Beispieldaten prüfen.

PRAXISTIPPS
- Views speichern eine Abfragedefinition, normalerweise nicht deren Ergebnis.
- Prozeduren können Parameter entgegennehmen und mehrere Anweisungen bündeln.
  Parameterisierung kann Planwiederverwendung fördern; passende Datentypen
  verwenden und Pläne unter repräsentativer Last messen.
- Eine skalare Funktion pro Ergebniszeile kann teuer werden. Für große
  Ergebnismengen set-basierte Abfragen oder Inline-Tabellenwertfunktionen
  bevorzugen und den tatsächlichen Ausführungsplan prüfen.
- Die Beispiele nutzen Tabellen aus der Northwind-Datenbank und setzen
  voraus, dass diese vorhanden sind.
*/

-- Wechselt in die Northwind-Datenbank; GO trennt Batches im Client.
USE [Northwind];
GO

-- Erstellt oder aktualisiert eine View, die Kunden-, Bestell- und Produktdaten
-- in einer gemeinsamen Abfrageschnittstelle bereitstellt.
CREATE OR ALTER VIEW dbo.vKundeumsatz
AS
SELECT
    c.CompanyName,
    c.City,
    c.Country,
    o.OrderID,
    o.OrderDate,
    o.Freight,
    o.CustomerID,
    od.ProductID,
    od.UnitPrice,
    od.Quantity,
    p.ProductName
FROM dbo.Customers AS c
INNER JOIN dbo.Orders AS o
    ON o.CustomerID = c.CustomerID
INNER JOIN dbo.[Order Details] AS od
    ON od.OrderID = o.OrderID
INNER JOIN dbo.Products AS p
    ON p.ProductID = od.ProductID;
GO

-- Gibt die Zeilen der View zurück. Für die Praxis nur benötigte Spalten filtern.
SELECT
    CompanyName,
    City,
    Country,
    OrderID,
    OrderDate,
    ProductName,
    Quantity,
    UnitPrice
FROM dbo.vKundeumsatz;

-- Erstellt oder aktualisiert eine Prozedur, die Bestellpositionen für ein
-- Produkt zurückgibt. Der Parametername und seine Verwendung stimmen überein.
CREATE OR ALTER PROCEDURE dbo.procDemo
    @ProductId int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CompanyName,
        c.City,
        c.Country,
        o.OrderID,
        o.OrderDate,
        o.Freight,
        o.CustomerID,
        od.ProductID,
        od.UnitPrice,
        od.Quantity,
        p.ProductName
    FROM dbo.Customers AS c
    INNER JOIN dbo.Orders AS o
        ON o.CustomerID = c.CustomerID
    INNER JOIN dbo.[Order Details] AS od
        ON od.OrderID = o.OrderID
    INNER JOIN dbo.Products AS p
        ON p.ProductID = od.ProductID
    WHERE od.ProductID = @ProductId;
END;
GO

-- Führt die Prozedur für Produkt 1 aus; eine vorhandene Produkt-ID einsetzen.
EXEC dbo.procDemo @ProductId = 1;
GO

-- Erstellt oder aktualisiert eine skalare Funktion, die den Positionswert
-- einer Bestellung aus Einzelpreis und Menge summiert.
CREATE OR ALTER FUNCTION dbo.fRsumme
(
    @Bestellnummer int
)
RETURNS money
AS
BEGIN
    RETURN
    (
        SELECT SUM(UnitPrice * Quantity)
        FROM dbo.[Order Details]
        WHERE OrderID = @Bestellnummer
    );
END;
GO

-- Berechnet die Positionssumme für die Beispielbestellung 10248.
SELECT dbo.fRsumme(10248) AS OrderTotal;

-- Berechnet für jede Bestellung die Summe. Bei großen Tabellen kann der
-- skalare Funktionsaufruf pro Zeile Leistung kosten; Ausführungsplan prüfen.
SELECT
    o.OrderID,
    dbo.fRsumme(o.OrderID) AS OrderTotal
FROM dbo.Orders AS o;

-- Zeigt die Bestelldetails; in produktiven Abfragen Spalten gezielt auswählen.
SELECT
    OrderID,
    ProductID,
    UnitPrice,
    Quantity
FROM dbo.[Order Details];

-- Sucht Kunden, deren ID mit A beginnt; % steht für beliebig viele Zeichen.
SELECT
    CustomerID,
    CompanyName
FROM dbo.Customers
WHERE CustomerID LIKE N'A%';

-- Zeigt eine alternative Präfixsuche; LEFT auf der Spalte kann einen Indexscan
-- verursachen, daher ist LIKE mit Präfix für diesen Zweck oft geeigneter.
SELECT
    CustomerID,
    CompanyName
FROM dbo.Customers
WHERE LEFT(CustomerID, 1) = N'A';

-- Sucht einen einzelnen Kunden anhand seines Primärschlüsselwerts.
SELECT
    CustomerID,
    CompanyName,
    City,
    Country
FROM dbo.Customers
WHERE CustomerID = N'ALFKI';
