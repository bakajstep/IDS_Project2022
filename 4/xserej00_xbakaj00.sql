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
drop sequence ZAMESTNANEC_ID;
drop materialized view VYPIS_ZAMESTNANCU;



-------------------------------- CREATE ----------------------------------------

CREATE TABLE Zamestnanec
(
    ID                    INT DEFAULT NULL PRIMARY KEY,
    Jmeno                 VARCHAR(50),
    Prijmeni              VARCHAR(50),
    Mesto                 VARCHAR(50),
    PSC                   VARCHAR(6)
        CONSTRAINT PSC_check CHECK (REGEXP_LIKE(PSC, '^[0-9]{5}$')),
    Ulice                 VARCHAR(50),
    Cislo_popisne         INT,
    Cislo_bankovniho_uctu VARCHAR(40)
        CONSTRAINT ucet_check CHECK (REGEXP_LIKE(Cislo_bankovniho_uctu, '^(([0-9]{0,6})-)?([0-9]{2,10})\/([0-9]{4})$')),
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
    Lekova_forma       VARCHAR(40),
    Cesta              VARCHAR(35),
    Ucina_latka        VARCHAR(100),
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
    Telefon        VARCHAR(25) NOT NULL
        CONSTRAINT telefon_check CHECK (REGEXP_LIKE(Telefon,
                                                    '^(\+?420)?(2[0-9]{2}|3[0-9]{2}|4[0-9]{2}|5[0-9]{2}|72[0-9]|73[0-9]|77[0-9]|60[1-8]|56[0-9]|70[2-5]|79[0-9])[0-9]{3}[0-9]{3}$')),
    Popis          VARCHAR(255),
    PRIMARY KEY (ID_zamestnance, Poradove_cislo),
    CONSTRAINT Telefon_FK FOREIGN KEY (ID_zamestnance) REFERENCES Zamestnanec (ID) ON DELETE SET NULL
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
    Cislo_pojistence VARCHAR(10)
        CONSTRAINT cislo_pojistence_check CHECK (REGEXP_LIKE(Cislo_pojistence,
                                                             '^\d{2}(0[1-9]|1[0-2]|5[1-9]|6[0-2])(0[1-9]|1[0-9]|2[0-9]|3[0-1])\d{3,4}$'))
        CONSTRAINT csl_poj_check CHECK (mod(Cislo_pojistence, 11) = 0),
    PRIMARY KEY (ID_prodeje, ID_zasoby),
    CONSTRAINT Pojistovna_FK FOREIGN KEY (Kod_pojistovny) REFERENCES Pojistovna (Kod) ON DELETE SET NULL,
    CONSTRAINT Prodej_FK FOREIGN KEY (ID_prodeje) REFERENCES Prodej (ID) ON DELETE CASCADE,
    CONSTRAINT Zasoby_FK FOREIGN KEY (ID_zasoby) REFERENCES Zasoby (ID) ON DELETE CASCADE
);


-------------------------------- TRIGGER ----------------------------------------

-- 1. Trigger pro automatický zvýšení primárního klíče u tabulky Zamestnanec
CREATE SEQUENCE Zamestnanec_id
    START WITH 1
    INCREMENT BY 1;
CREATE OR REPLACE TRIGGER Zamestnanec_id
    BEFORE INSERT
    ON Zamestnanec
    FOR EACH ROW
BEGIN
    IF :NEW.ID IS NULL THEN
        :NEW.ID := Zamestnanec_id.NEXTVAL;
    END IF;
END;
/


---- 2. Trigger pro automatickou kontrolu zda prodej léku na předpis provedl magistr(a)
CREATE OR REPLACE TRIGGER Kontrola_prodeje
    BEFORE INSERT
    ON Zasoby_prodej
    FOR EACH ROW
DECLARE
    Je_Magistr NUMBER(1);
    Na_Predpis VARCHAR(1);
BEGIN
    IF INSERTING THEN
        SELECT Prodej
        INTO Na_Predpis
        FROM Lek
                 JOIN Zasoby Z on Lek.Kod = Z.Kod_leku
        WHERE Z.ID = :NEW.ID_zasoby;

        SELECT Predpisovy_prodej
        INTO Je_Magistr
        FROM Prodej P
                 JOIN Zamestnanec Zam on P.ID_zamestnance = Zam.ID
        WHERE P.ID = :NEW.ID_prodeje;
        IF Je_Magistr = 0 AND Na_Predpis = 'R' THEN
            RAISE_APPLICATION_ERROR(-20000, 'Tento zaměstnanec nemůže provést prodej na předpis!');
        END IF;
    END IF;
END;
/

-------------------------------- INSERT VALUES ---------------------------------

INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Jan', 'Novák', 'Brno', 60200, 'Kolejní', 2, '123456789/9999', 1);
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu, Predpisovy_prodej)
VALUES ('Jana', 'Nováková', 'Brno', 60200, 'Kolejní', 2, '987654321/9999', 0);
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Josef', 'Kadlec', 'Kuřim', 66434, 'Stodolní', 28, '369258147/9999', 0);
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Petra', 'Boháčková', 'Kuřim', 66434, 'Janáčkova', 50, '352477568/9999', 0);
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Marek', 'Dočekal', 'Jihlava', 58601, 'Nerudova', 15, '31-548763892/8888', 1);

INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0229792, 'IBALGIN', 'Sanofi', 'Potahovaná tableta', 'Perorální podání', 'IBUPROFEN', 36, 99, 'V', NULL, 25);
INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0087906, 'KORYLAN', 'Zentiva', 'Tableta', 'Perorální podání', 'PARACETAMOL;HEMIHYDRÁT KODEIN-FOSFÁTU', 10, 120,
        'R', 50, 25);
INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0254048, 'PARALEN', 'Zentiva', 'Tableta', 'Perorální podání', 'PARACETAMOL (PARACETAMOLUM)', 24, 59, 'V', NULL,
        25);
INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0223159, 'MUCOSOLVAN', 'Sanofi', 'Perorální roztok/roztok k inhalaci', 'Perorální/inhalační podání',
        'AMBROXOL-HYDROCHLORID (AMBROXOLI HYDROCHLORIDUM)', 60, 108, 'V', NULL, 25);
INSERT INTO Lek (Kod, Nazev, Vyrobce, Lekova_forma, Cesta, Ucina_latka, Velikost_baleni, Cena, Prodej, Doplatek,
                 Teplota_skladovani)
VALUES (0059739, 'STREPSILS CITRON BEZ CUKRU', 'RECKITT BENCKISER', 'Pastilka', 'Orální podání',
        'AMYLMETAKRESOL (AMYLMETACRESOLUM)2,4-DICHLORBENZYLALKOHOL (ALCOHOL 2,4-DICHLOROBENZYLICUS)', 24, 172, 'V',
        NULL, 25);

INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (1, 1, '+420774023986', 'pracovni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (1, 2, '+420774023123', 'osobni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (2, 1, '+420774023321', 'osobni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (3, 1, '+420605147852', 'osobni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (4, 1, '+420731258764', 'osobni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (5, 1, '+420702693216', 'osobni mobil');
INSERT INTO Telefon(ID_zamestnance, Poradove_cislo, Telefon, Popis)
VALUES (5, 2, '+420731528416', 'pracovní mobil');

INSERT INTO Zasoby(Datum_spotreby, Mnozstvi, Kod_leku)
VALUES (TO_DATE('2023-01-01', 'yyyy/mm/dd'), 10, 0229792);
INSERT INTO Zasoby(Datum_spotreby, Mnozstvi, Kod_leku)
VALUES (TO_DATE('2023-01-01', 'yyyy/mm/dd'), 5, 0087906);
INSERT INTO Zasoby(Datum_spotreby, Mnozstvi, Kod_leku)
VALUES (TO_DATE('2024-01-01', 'yyyy/mm/dd'), 10, 0254048);
INSERT INTO Zasoby(Datum_spotreby, Mnozstvi, Kod_leku)
VALUES (TO_DATE('2024-01-01', 'yyyy/mm/dd'), 0, 0223159);
INSERT INTO Zasoby(Datum_spotreby, Mnozstvi, Kod_leku)
VALUES (TO_DATE('2023-02-01', 'yyyy/mm/dd'), 15, 0229792);

INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-01 23:59:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 2);
INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-02 00:05:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 1);
INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-02 00:10:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 1);
INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-03 08:22:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 4);
INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-03 08:05:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 3);
INSERT INTO Prodej(Datum, ID_zamestnance)
VALUES (TO_TIMESTAMP('2022-01-03 14:59:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 4);


INSERT INTO Pojistovna(Kod, Nazev)
VALUES (111, 'všeobecná zdravotní pojišťovna');

INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (1, 1);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (2, 1);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby, Kod_pojistovny, Cislo_pojistence)
VALUES (2, 2, 111, '0101019875');
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby, Kod_pojistovny, Cislo_pojistence)
VALUES (3, 2, 111, '0101019875');
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (3, 3);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (4, 3);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (5, 1);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (5, 3);
INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby)
VALUES (1, 3);

-------------------------------- SELECT VALUES ---------------------------------

--Vypíše počet prodejů každého zaměstnance
SELECT Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni, count(Prodej.ID) as Pocet_prodeju
FROM Zamestnanec
         JOIN Prodej ON Prodej.ID_zamestnance = Zamestnanec.ID
GROUP BY Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni;

--výpis výkazů pro pojišťovnu
SELECT Pojistovna.Kod,
       Pojistovna.Nazev,
       Zasoby_prodej.Cislo_pojistence,
       Lek.Kod                   as Kod_leku,
       (Lek.Cena - Lek.Doplatek) as Proplaci_za_kus,
       count(*)                  as Pocet_kusu
FROM Pojistovna
         JOIN Zasoby_prodej on Pojistovna.Kod = Zasoby_prodej.Kod_pojistovny
         JOIN Zasoby on Zasoby_prodej.ID_zasoby = Zasoby.ID
         JOIN Lek on Zasoby.Kod_leku = Lek.Kod
GROUP BY Pojistovna.Kod, Pojistovna.Nazev, Zasoby_prodej.Cislo_pojistence, Lek.Kod, Lek.Cena, Lek.Doplatek;

--výpis léků, které jsou na skladě
SELECT Lek.Kod, Lek.Nazev, sum(Zasoby.Mnozstvi) as Na_sklade
FROM Lek
         JOIN Zasoby on Zasoby.Kod_leku = Lek.Kod
GROUP BY Lek.Kod, Lek.Nazev;

--vypis telefonu zamestnanace Jana Novaka
SELECT Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni, Telefon.Telefon, Telefon.Popis
FROM Zamestnanec
         JOIN Telefon on Zamestnanec.ID = Telefon.ID_zamestnance
WHERE Zamestnanec.Jmeno LIKE 'Jan'
  and Zamestnanec.Prijmeni LIKE 'Novák';

--vypis vsechny prodeje zamestnance Petra Bohackova ze dne 3.1.2022
SELECT Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni, Prodej.ID as ID_prodeje
FROM Zamestnanec
         JOIN Prodej on Zamestnanec.ID = Prodej.ID_zamestnance
WHERE Zamestnanec.Jmeno LIKE 'Petra'
  and Zamestnanec.Prijmeni LIKE 'Boháčková'
  and Prodej.Datum >= TO_TIMESTAMP('2022-01-03', 'YYYY-MM-DD')
  and Prodej.Datum < TO_TIMESTAMP('2022-01-04', 'YYYY-MM-DD');

-- vypis vsechny zamestnance kteri neprovedli prodej
SELECT *
FROM Zamestnanec
WHERE NOT EXISTS(SELECT * FROM Prodej WHERE Zamestnanec.ID = Prodej.ID_zamestnance);


--vypis leku ktere nejsou na sklade
SELECT Lek.Kod, Lek.Nazev
FROM Lek
WHERE (Lek.Kod) not in (SELECT Zasoby.Kod_leku FROM Zasoby)
   or (Lek.Kod) in (SELECT Zasoby.Kod_leku FROM Zasoby where Zasoby.Mnozstvi = '0');


------------------------------- PROCEDURES -------------------------------------

-- 1. Procedura na úkázání určitého léku na skladě podle kodu ze SUKLu(našeho primárního klíče)
CREATE OR REPLACE PROCEDURE zasoby_leku(lek_kod IN INT)
AS
    mnozstvi_celkem NUMBER;
    lek_jmeno       varchar(50);
    lek_id          Zasoby."ID"%TYPE;
    lek_mnozstvi    Zasoby.Mnozstvi%TYPE;
    CURSOR cursor_zasoby_id IS SELECT Kod_leku
                               FROM Zasoby;
    CURSOR cursor_zasoby_mnozstvi IS SELECT Mnozstvi
                                     FROM Zasoby;
BEGIN

    mnozstvi_celkem := 0;
    SELECT NAZEV into lek_jmeno from Lek where Kod = lek_kod;
    OPEN cursor_zasoby_id;
    OPEN cursor_zasoby_mnozstvi;
    LOOP
        FETCH cursor_zasoby_id INTO lek_id;
        FETCH cursor_zasoby_mnozstvi INTO lek_mnozstvi;

        EXIT WHEN cursor_zasoby_id%NOTFOUND;

        IF lek_id = lek_kod THEN
            mnozstvi_celkem := mnozstvi_celkem + lek_mnozstvi;
        END IF;
    END LOOP;
    CLOSE cursor_zasoby_id;
    CLOSE cursor_zasoby_mnozstvi;


    DBMS_OUTPUT.put_line(
                'ID :' || lek_kod || ' název: ' || lek_jmeno || ' mnozstvi: ' || mnozstvi_celkem
        );

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        BEGIN
            DBMS_OUTPUT.put_line(
                    'ID :' || lek_kod || ' název: ' || lek_jmeno || ' neni na sklade!'
                );
        END;

END;
/


-- 2. procedura pro výpis výkazu pro určitou pojišťovnu v daný měsíc
CREATE OR REPLACE PROCEDURE pojistovna_vykaz (Pojistovna IN INT, Datum_prodeje IN TIMESTAMP)
AS
cislo_poj VARCHAR(10);
kod INT;
proplaci INT;
proplaci_celkem INT;
CURSOR cursor_pojistovna IS SELECT Zasoby_prodej.Cislo_pojistence,Zasoby.Kod_leku, (Lek.Cena - Lek.Doplatek) as Proplaci_za_kus FROM Zasoby_prodej join Zasoby on Zasoby_prodej.ID_zasoby = Zasoby.ID join Lek on Lek.Kod = Zasoby.Kod_leku join Prodej on Zasoby_prodej.ID_prodeje = Prodej.ID WHERE Kod_pojistovny = Pojistovna and EXTRACT( MONTH from Prodej.Datum ) = EXTRACT( MONTH from Datum_prodeje ) and EXTRACT( YEAR from Prodej.Datum ) = EXTRACT( YEAR from Datum_prodeje );
BEGIN
    DBMS_OUTPUT.put_line(
                'výkaz pro pojišťovnu:  ' || Pojistovna
        );
    proplaci_celkem := 0;
    OPEN cursor_pojistovna;
    LOOP
        FETCH cursor_pojistovna INTO cislo_poj,kod,proplaci;
        
        EXIT WHEN cursor_pojistovna%NOTFOUND;
        
        proplaci_celkem := proplaci_celkem + proplaci;
        DBMS_OUTPUT.put_line(
                'číslo pojištěnce:  ' || cislo_poj || ' kód léku:   ' || kod || '   proplácí:   ' || proplaci
        );
    END LOOP;
    CLOSE cursor_pojistovna;

    DBMS_OUTPUT.put_line(
                'celkem proplácí:' || proplaci_celkem
        );
END;
/

------------------------------- MATERIALIZED VIEW -----------------------------------


CREATE MATERIALIZED VIEW vypis_zamestnancu
AS
SELECT XBAKAJ00.Zamestnanec.ID, XBAKAJ00.Zamestnanec.JMENO, XBAKAJ00.Zamestnanec.PRIJMENI
FROM XBAKAJ00.Zamestnanec;
/

-- Vypis prodeju pred insertem
SELECT *
FROM vypis_zamestnancu;

-- Vlozeni novych dat
INSERT INTO Zamestnanec (Jmeno, Prijmeni, Mesto, PSC, Ulice, Cislo_popisne, Cislo_bankovniho_uctu,
                         Predpisovy_prodej)
VALUES ('Eva', 'Nováková', 'Brno', 60200, 'Kolejní', 2, '123456788/9999', 1);

-- Vypis prodeju po insertem
SELECT *
FROM vypis_zamestnancu;


------------------------------- SHOW PROCEDURES -------------------------------------

-- Ověření funkčnosti 1. procedury
BEGIN
    zasoby_leku('0229792');
END;

-- Ověření funkčnosti 2. procedury
BEGIN
    pojistovna_vykaz('111',TO_TIMESTAMP('2022-01', 'YYYY-MM'));
END;

------------------------------- EXPLAIN PLAN -----------------------------------------

EXPLAIN PLAN FOR
SELECT Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni, count(Prodej.ID) as Pocet_prodeju
FROM Zamestnanec
         JOIN Prodej ON Prodej.ID_zamestnance = Zamestnanec.ID
GROUP BY Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni;

SELECT * FROM TABLE ( DBMS_XPLAN.DISPLAY );

CREATE INDEX zamestnanec_index ON Zamestnanec (ID, Jmeno, Prijmeni);

EXPLAIN PLAN FOR
SELECT Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni, count(Prodej.ID) as Pocet_prodeju
FROM Zamestnanec
         JOIN Prodej ON Prodej.ID_zamestnance = Zamestnanec.ID
GROUP BY Zamestnanec.ID, Zamestnanec.Jmeno, Zamestnanec.Prijmeni;

SELECT * FROM TABLE ( DBMS_XPLAN.DISPLAY );


-------------------------------- SHOW TRIGGERS FUNCTION ------------------------------

-- Ukázka 1. triggeru zda mají primární klíč u tabulky Zamestnanec
SELECT ID, Jmeno
FROM Zamestnanec;

-- Ukázka 2. triggeru ze nemůže provést prodej nautorizovaný lékárník
--INSERT INTO Prodej(Datum, ID_zamestnance)
--VALUES (TO_TIMESTAMP('2022-01-02 00:05:59.10', 'YYYY-MM-DD HH24:MI:SS.FF'), 2);
--INSERT INTO Zasoby_prodej(ID_prodeje, ID_zasoby, Kod_pojistovny, Cislo_pojistence)
--VALUES (7, 2, 111, '0101019875');

-------------------------------- PRIVILEGES ------------------------------------

GRANT ALL ON Zamestnanec to XSEREJ00;
GRANT ALL ON Lek to XSEREJ00;
GRANT ALL ON Prodej to XSEREJ00;
GRANT ALL ON Zasoby_prodej to XSEREJ00;
GRANT ALL ON Zasoby to XSEREJ00;
GRANT ALL ON Pojistovna to XSEREJ00;
GRANT ALL ON Telefon to XSEREJ00;
GRANT ALL ON vypis_zamestnancu to XBAKAJ00;

GRANT EXECUTE ON zasoby_leku to XSEREJ00;