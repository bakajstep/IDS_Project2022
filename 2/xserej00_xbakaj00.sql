TODO

CREATE TABLE `Volny_prodej` (
  `` <type> 
);

CREATE TABLE `Zamestnanec` (
  `ID` INT primary key,
  `Jmeno` VARCHAR(50),
  `Prijmeni` VARCHAR(50),
  `Mesto` VARCHAR(50),
  `PSC` VARCHAR(6),
  `Ulice` VARCHAR(50),
  `Cislo_popisné` INT,
  `Cislo_bankovniho_uctu` VARCHAR(25),
  `Predpisovy_prodej` NUMBER(1)
);

CREATE TABLE `Prodej` (
  `ID` INT primary key,
  `Datum` TIMESTAMP(2),
  `ID_zamestnance` INT,
  FOREIGN KEY (`ID_zamestnance`) REFERENCES `Zamestnanec`(`ID`)
);

CREATE TABLE `Lek` (
  `Kod` INT primary key,
  `Nazev` VARCHAR(50),
  `Vyrobce` VARCHAR(50),
  `Lekova_forma` VARCHAR(25),
  `Cesta` VARCHAR(25),
  `Ucina_latka` VARCHAR(50),
  `Velikost_baleni` INT,
  `Cena` INT,
  `Teplota_skladovani` INT
);

TODO

CREATE TABLE `Na_predpis` (
  `Doplatek` INT
);

CREATE TABLE `Zasoby` (
  `ID` INT primary key,
  `Datum spotřeby` DATE not null,
  `Množství` INT,
  `Kod_leku` INT not null,
  FOREIGN KEY (`Kod_leku`) REFERENCES `Lek`(`Kod`)
);

CREATE TABLE `Telefon` (
  `Poradove_cislo` int,
  `Telefon` VARCHAR(25),
  `Popis` VARCHAR(255)
);

CREATE TABLE `Pojistovna` (
  `Kod` INT primary key,
  `Nazev` VARCHAR(255)
);

CREATE TABLE `zasoby-prodej` (
  `Kod_pojistovny` INT not null,
  `ID_prodeje` INT,
  `Cislo_pojistence` VARCHAR(10),
  primary key(ID_prodeje, Kod_pojistovny),
  FOREIGN KEY (`Kod_pojistovny`) REFERENCES `Pojistovna`(`Kod`),
  FOREIGN KEY (`ID_prodeje`) REFERENCES `Prodej`(`ID`)
);

