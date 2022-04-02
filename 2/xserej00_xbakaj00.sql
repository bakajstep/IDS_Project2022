-- SQL skript pro vytvoření základních objektů schématu databáze.
-- Zadání č. 33. – Lékárna.
--------------------------------------------------------------------------------
-- Autor: Šerejch Radek <xserej00@stud.fit.vutbr.cz>.
-- Autor: Bakaj Štěpán <xbakaj00@stud.fit.vutbr.cz>.

-------------------------------- DROP ------------------------------------------


DROP TABLE Telefon;
DROP TABLE Zasoby_prodej;
DROP TABLE Prodej;
DROP TABLE Zasoby;
DROP TABLE Pojistovna;
DROP TABLE Zamestnanec;
DROP TABLE Lek;


-------------------------------- CREATE ----------------------------------------

CREATE TABLE Zamestnanec
(
    ID                    INT GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    Jmeno                 VARCHAR(50),
    Prijmeni              VARCHAR(50),
    Mesto                 VARCHAR(50),
    PSC                   VARCHAR(6),
    Ulice                 VARCHAR(50),
    Cislo_popisne         INT,
    Cislo_bankovniho_uctu VARCHAR(40),
    Predpisovy_prodej     NUMBER(1)
);



CREATE TABLE Prodej
(
    ID             INT GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    Datum          TIMESTAMP(2),
    ID_zamestnance INT,
    CONSTRAINT zamestnanec_prodej_FK FOREIGN KEY (ID_zamestnance) REFERENCES Zamestnanec (ID) ON DELETE SET NULL
);

-- Zvolili jsme sloučení do jedné tabulky, protože se jednalo o přídání dvou atributů.

CREATE TABLE Lek
(
    Kod                INT PRIMARY KEY,
    Nazev              VARCHAR(50),
    Vyrobce            VARCHAR(50),
    Lekova_forma       VARCHAR(25),
    Cesta              VARCHAR(25),
    Ucina_latka        VARCHAR(50),
    Velikost_baleni    INT,
    Cena               INT,
    Prodej             VARCHAR(1) CHECK (Prodej IN ('V', 'R')),
    Doplatek           INT,
    Teplota_skladovani INT
);



CREATE TABLE Zasoby
(
    ID             INT GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    Datum_spotreby DATE not null,
    Mnozstvi       INT,
    Kod_leku       INT,
    CONSTRAINT Lek_FK FOREIGN KEY (Kod_leku) REFERENCES Lek (Kod) ON DELETE SET NULL
);

CREATE TABLE Telefon
(
    ID_zamestnance INT,
    Poradove_cislo INT,
    Telefon        VARCHAR(25) NOT NULL,
    Popis          VARCHAR(255),
    PRIMARY KEY (ID_zamestnance, Poradove_cislo),
    CONSTRAINT Telefon_FK FOREIGN KEY (ID_zamestnance) REFERENCES Zamestnanec (ID) ON DELETE CASCADE
);

CREATE TABLE Pojistovna
(
    Kod   INT PRIMARY KEY,
    Nazev VARCHAR(255)
);

CREATE TABLE Zasoby_prodej
(
    ID_prodeje       INT,
    ID_zasoby        INT,
    Kod_pojistovny   INT,
    Cislo_pojistence VARCHAR(10),
    PRIMARY KEY (ID_prodeje, ID_zasoby),
    CONSTRAINT Pojistovna_FK FOREIGN KEY (Kod_pojistovny) REFERENCES Pojistovna (Kod) ON DELETE SET NULL,
    CONSTRAINT Prodej_FK FOREIGN KEY (ID_prodeje) REFERENCES Prodej (ID) ON DELETE CASCADE ,
    CONSTRAINT Zasoby_FK FOREIGN KEY (ID_zasoby) REFERENCES Zasoby (ID) ON DELETE CASCADE
);


-------------------------------- INSERT VALUES ---------------------------------

INSERT INTO Zamestnanec ( Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Jan', 'Novák', 'Brno', 60200, 'Kolejní', 2, '123456789/9999', 1);
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu, Predpisovy_prodej)
VALUES ('Jana', 'Nováková', 'Brno', 60200, 'Kolejní', 2, '987654321/9999', 0);
INSERT INTO Zamestnanec ( Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ( 'Josef', 'Kadlec', 'Kuřim', 66434, 'Stodolní', 28, '369258147/9999', 0);

INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0229792, 'IBALGIN', 'Sanofi', 'Potahovaná tableta', 'Perorální podání', 'IBUPROFEN', 36, 99, 'V', NULL, 25);
INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0087906, 'KORYLAN', 'Zentiva', 'Tableta', 'Perorální podání', 'PARACETAMOL;HEMIHYDRÁT KODEIN-FOSFÁTU', 10, 120,
        'R', 50, 25);
