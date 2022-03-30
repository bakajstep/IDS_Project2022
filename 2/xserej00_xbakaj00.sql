CREATE TABLE Zamestnanec (
  ID INT primary key,
  Jmeno VARCHAR(50),
  Prijmeni VARCHAR(50),
  Mesto VARCHAR(50),
  PSC VARCHAR(6),
  Ulice VARCHAR(50),
  Cislo_popisne INT,
  Cislo_bankovniho_uctu VARCHAR(25),
  Predpisovy_prodej NUMBER(1)
);

CREATE TABLE Prodej (
  ID INT primary key,
  Datum TIMESTAMP(2),
  ID_zamestnance INT,
  FOREIGN KEY (ID_zamestnance) REFERENCES Zamestnanec(ID)
);

CREATE TABLE Lek (
  Kod INT primary key,
  Nazev VARCHAR(50),
  Vyrobce VARCHAR(50),
  Lekova_forma VARCHAR(25),
  Cesta VARCHAR(25),
  Ucina_latka VARCHAR(50),
  Velikost_baleni INT,
  Cena INT,
  Doplatek INT,
  Teplota_skladovani INT
);

CREATE TABLE Zasoby (
  ID INT primary key,
  Datum_spotreby DATE not null,
  Mnozstvi INT,
  Kod_leku INT not null,
  FOREIGN KEY (Kod_leku) REFERENCES Lek(Kod)
);

CREATE TABLE Telefon (
  ID_zamestnance INT,
  Poradove_cislo INT,
  Telefon VARCHAR(25),
  Popis VARCHAR(255),
  primary key(ID_zamestnance, Poradove_cislo)
);

CREATE TABLE Pojistovna (
  Kod INT primary key,
  Nazev VARCHAR(255)
);

CREATE TABLE zasoby_prodej (
  ID_prodeje INT,
  ID_zasoby INT,
  Kod_pojistovny INT,
  Cislo_pojistence VARCHAR(10),
  primary key(ID_prodeje, ID_zasoby),
  FOREIGN KEY (Kod_pojistovny) REFERENCES Pojistovna(Kod),
  FOREIGN KEY (ID_prodeje) REFERENCES Prodej(ID),
  FOREIGN KEY (ID_zasoby) REFERENCES Zasoby(ID)
);

