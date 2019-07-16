DROP TABLE Darca                    CASCADE CONSTRAINTS;
DROP TABLE Klient                   CASCADE CONSTRAINTS;
DROP TABLE Zamestnanec              CASCADE CONSTRAINTS;
DROP TABLE Odber                    CASCADE CONSTRAINTS;
DROP TABLE Rezervacia               CASCADE CONSTRAINTS;
DROP TABLE Pobocka                  CASCADE CONSTRAINTS;
DROP TABLE Zamestnanci_Na_Pobocke   CASCADE CONSTRAINTS;
DROP TABLE Zamestnanec_Kona_Odber   CASCADE CONSTRAINTS;

DROP SEQUENCE ID_Odber_SEQ;

CREATE TABLE Darca 
(
  ID_Darca INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  Meno varchar(20) not null,
  Priezvisko varchar(20) not null,
  Adresa varchar(30) not null,
  TelCislo varchar(13) not null check (regexp_like(TelCislo,'^\+\d{12}$')),
  KrvnaSkupina varchar(2) check(KrvnaSkupina = 'A' or KrvnaSkupina = 'B' or KrvnaSkupina = 'AB' or KrvnaSkupina = '0')
);

CREATE TABLE Klient 
(
  ID_Klient INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  Meno varchar(20) not null,
  Priezvisko varchar(20) not null,
  Adresa varchar(30) not null,
  TelCislo varchar(13) not null check (regexp_like(TelCislo,'^\+\d{12}$')),
  KlubovaKarta varchar(16) not null check (regexp_like(KlubovaKarta,'^\d{16}$'))
);

CREATE TABLE Zamestnanec 
(
  ID_Zamestnanec INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  Meno varchar(20) not null,
  Priezvisko varchar(20) not null,
  Adresa varchar(30) not null,
  TelCislo varchar(13) not null check (regexp_like(TelCislo,'^\+\d{12}$')), --421 515 151 221,
  Pozicia varchar(20)
);

CREATE TABLE Zamestnanci_Na_Pobocke 
(
  ID_Zamestnanci_Na_Pobocke INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  ID_Zamestnanec int not null,
  ID_Pobocka int
);

CREATE TABLE Zamestnanec_Kona_Odber 
(
  ID_Zamestnanec_Kona_Odber INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  ID_Zamestnanec int,
  ID_Odber int
);

CREATE TABLE Odber 
(
  ID_Odber INT NOT NULL primary key, --trigger for generating ID below
  ID_Pobocka int,
  ID_Rezervacia int,
  ID_Darca int not null,
  DatumOdberu date not null,
  TestDarcu int check(TestDarcu = 0 or TestDarcu = 1 or TestDarcu = null), -- true, false or null
  TestKrvi int check(TestKrvi = 0 or TestKrvi = 1 or TestKrvi = null) -- true, false or null
);

CREATE TABLE Rezervacia
(
  ID_Rezervacia INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  ID_Klient int not null,
  ID_Pobocka int not null,
  DatumRezervacie date not null,
  DatumVyzdvihnutia date
);

CREATE TABLE Pobocka
(
  ID_Pobocka INT GENERATED ALWAYS AS IDENTITY(START with 1 INCREMENT by 1) primary key,
  Sidlo varchar(30) not null,
  StavBanky int not null check(StavBanky >= 0)
);


ALTER TABLE  Odber       ADD CONSTRAINT FK_Odber_Od_Darcu           FOREIGN KEY(ID_Darca)      REFERENCES Darca;
ALTER TABLE  Rezervacia  ADD CONSTRAINT FK_Ma_Klienta               FOREIGN KEY(ID_Klient)     REFERENCES Klient;
ALTER TABLE  Rezervacia  ADD CONSTRAINT FK_Rezervacia_Na_Pobocke    FOREIGN KEY(ID_Pobocka)    REFERENCES Pobocka;
ALTER TABLE  Odber       ADD CONSTRAINT FK_Odber_Na_Pobocke         FOREIGN KEY(ID_Pobocka)    REFERENCES Pobocka;
ALTER TABLE  Odber       ADD CONSTRAINT FK_Odber_Rezervovany_Na     FOREIGN KEY(ID_Rezervacia) REFERENCES Rezervacia;

ALTER TABLE  Zamestnanci_Na_Pobocke  ADD CONSTRAINT FK_Pobocka_ma_zamestnanca       FOREIGN KEY(ID_Zamestnanec) REFERENCES Zamestnanec;
ALTER TABLE  Zamestnanci_Na_Pobocke  ADD CONSTRAINT FK_Zamestnanec_robi_na_pobocke  FOREIGN KEY(ID_Pobocka)     REFERENCES Pobocka;

ALTER TABLE  Zamestnanec_Kona_Odber  ADD CONSTRAINT FK_Zamestnanec_kona_odber  FOREIGN KEY(ID_Odber)       REFERENCES Odber;
ALTER TABLE  Zamestnanec_Kona_Odber  ADD CONSTRAINT FK_Odber_od_zamestnanaca   FOREIGN KEY(ID_Zamestnanec) REFERENCES Zamestnanec;

CREATE SEQUENCE ID_Odber_SEQ;
CREATE OR REPLACE TRIGGER ID_Odber_TRG
BEFORE INSERT ON Odber
FOR EACH ROW
BEGIN
SELECT ID_Odber_SEQ.NEXTVAL
INTO :new.ID_Odber
FROM DUAL;
END;
/

CREATE OR REPLACE TRIGGER Rezervacia_Davky_TRG
AFTER UPDATE ON Odber
FOR EACH ROW
BEGIN
IF :new.TestKrvi = 0 THEN 
  RAISE VALUE_ERROR; 
END IF;
END;
/

CREATE OR REPLACE TRIGGER Zvys_StavBanky_TRG
AFTER INSERT ON Odber
FOR EACH ROW
DECLARE
stav INT;
BEGIN
SELECT StavBanky + 1 INTO stav FROM Pobocka WHERE ID_Pobocka = :new.ID_Pobocka;
UPDATE Pobocka SET StavBanky = stav WHERE ID_Pobocka = :new.ID_Pobocka AND :new.TestKrvi = 1;
END;
/

CREATE OR REPLACE TRIGGER Zniz_StavBanky_TRG
AFTER UPDATE ON Rezervacia
FOR EACH ROW
DECLARE
stav INT;
BEGIN
SELECT COUNT(*) INTO stav FROM Pobocka NATURAL JOIN Odber WHERE ID_Rezervacia = :new.ID_Rezervacia;
UPDATE Pobocka SET StavBanky = StavBanky-stav WHERE ID_Pobocka = :new.ID_Pobocka AND :new.DatumVyzdvihnutia IS NOT NULL;
END;
/

------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO Darca (Meno, Priezvisko, Adresa, TelCislo, KrvnaSkupina) VALUES ('Jozef', 'Vajda', 'Bratislava', '+421155511311', 'A');
INSERT INTO Darca (Meno, Priezvisko, Adresa, TelCislo, KrvnaSkupina) VALUES ('Peter', 'Bartos', 'Nitra', '+421155511099', 'A');
INSERT INTO Darca (Meno, Priezvisko, Adresa, TelCislo, KrvnaSkupina) VALUES ('Ivan', 'Abraham', 'Brno', '+420148941131', 'AB');
INSERT INTO Darca (Meno, Priezvisko, Adresa, TelCislo, KrvnaSkupina) VALUES ('Ferdinand', 'Zahorsky', 'Praha', '+420148941789', '0');

INSERT INTO Klient (Meno, Priezvisko, Adresa, TelCislo, KlubovaKarta) VALUES ('Peter', 'Novak', 'Nitra', '+421789547318', '1234567891278967');
INSERT INTO Klient (Meno, Priezvisko, Adresa, TelCislo, KlubovaKarta) VALUES ('Adam', 'Boros', 'Breclav', '+420789258318', '1234565879234567');
INSERT INTO Klient (Meno, Priezvisko, Adresa, TelCislo, KlubovaKarta) VALUES ('Tomas', 'Nemeth', 'Olomouc', '+420789758318', '1237249679234567');

INSERT INTO Pobocka (Sidlo, StavBanky) VALUES ('Praha', 0);
INSERT INTO Pobocka (Sidlo, StavBanky) VALUES ('Brno', 0);

INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (2, 2,'07-01-2019', 0, 0);
INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (2, 4,'03-03-2019', 1, 1);
INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (1, 1,'15-03-2019', 1, 1);
INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (1, 3,'25-04-2019', 1, 1);
INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (1, 3,'27-04-2019', 1, 0);
INSERT INTO Odber (ID_Pobocka, ID_Darca, DatumOdberu, TestDarcu, TestKrvi) VALUES (1, 4,'28-04-2019', 1, 1);

INSERT INTO Rezervacia (ID_Pobocka, ID_Klient, DatumRezervacie) VALUES (1, 1, '15-02-2019');
INSERT INTO Rezervacia (ID_Pobocka, ID_Klient, DatumRezervacie) VALUES (2, 3, '16-02-2019');
INSERT INTO Rezervacia (ID_Pobocka, ID_Klient, DatumRezervacie) VALUES (1, 2, '20-04-2019');
UPDATE Odber SET ID_Rezervacia = 1 WHERE ID_Odber = 2;
UPDATE Odber SET ID_Rezervacia = 1 WHERE ID_Odber = 3;
UPDATE Odber SET ID_Rezervacia = 2 WHERE ID_Odber = 4;
UPDATE Odber SET ID_Rezervacia = 3 WHERE ID_Odber = 6;
UPDATE Rezervacia SET DatumVyzdvihnutia = '18-02-2019' WHERE ID_Rezervacia = 1;
UPDATE Rezervacia SET DatumVyzdvihnutia = '19-02-2019' WHERE ID_Rezervacia = 2;

INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Peter', 'Zigo', 'Zilina', '+421784877318', 'Sef');
INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Patricia', 'Faludiova', 'Kosice', '+421784787725', 'Sestra');
INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Pavlina', 'Matkova', 'Poprad', '+421257787318', 'Sestra');
INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Adam', 'Ryhcly', 'Bratislava', '+421787482578', 'Sef');
INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Andrea', 'Novakova', 'Liptovsky Mikulas', '+421729887725', 'Sestra');
INSERT INTO Zamestnanec (Meno, Priezvisko, Adresa, TelCislo, Pozicia) VALUES ('Alena', 'Meszarosova', 'Banska Bystrica', '+421252438478', 'Sestra');

INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (1,5);
INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (2,6);
INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (3,2);
INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (4,2);
INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (5,3);
INSERT INTO Zamestnanec_Kona_Odber (ID_Odber, ID_Zamestnanec) VALUES (6,3);

INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (1,1);
INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (1,2);
INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (1,3);
INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (2,4);
INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (2,5);
INSERT INTO Zamestnanci_Na_Pobocke (ID_Pobocka, ID_Zamestnanec) VALUES (2,6);

------------------------------------------------------------------------------------------------------------------------------------------------------
--Vypis zamestnancov pracujucich na pobocke v Prahe
SELECT ID_Zamestnanec, Meno, Priezvisko, Sidlo
FROM Zamestnanec NATURAL JOIN Zamestnanci_Na_Pobocke NATURAL JOIN Pobocka
WHERE Sidlo ='Praha';

--Vypis poctu vykonanych odberov na roznych pobockach, pozn.: ak je test darcu NULL(darca sa nedostavil)
--alebo 0 (darca neni vhodny na darovanie krvi) tak sa odber nevykona.
SELECT Sidlo, COUNT(*) Pocet_Vykonanych_Odberov
FROM Odber NATURAL JOIN Pobocka
WHERE TestDarcu=1
GROUP BY Sidlo
ORDER BY Pocet_Vykonanych_Odberov;

--Vypis poctu rezervacii vybavenych v urcitom dni
SELECT DatumVyzdvihnutia, COUNT(*) Pocet_Vybavenych_Rezervacii
FROM Klient NATURAL JOIN Rezervacia
WHERE DatumVyzdvihnutia IS NOT NULL
GROUP BY DatumVyzdvihnutia;

--Vypis darcov len s krvnou skupinou A, ktory absolvovali test krvi
SELECT DISTINCT D.*
FROM Darca D, Odber O
WHERE D.ID_Darca=O.ID_Darca AND D.KrvnaSkupina='A' AND NOT EXISTS
    (SELECT * 
     FROM Darca D
     WHERE D.ID_Darca=O.ID_Darca AND O.TestKrvi<>1);

--Vypis darcov, ktory mali odber krvi na pobocke v Brne
SELECT ID_Darca, Meno, Priezvisko
FROM Darca
WHERE ID_Darca IN
   (SELECT ID_Darca FROM Odber
    WHERE ID_Pobocka IN
     (SELECT ID_Pobocka  FROM Pobocka
      WHERE Sidlo='Brno'));
      
------------------------------------------------------------------------------------------------------------------------------------------------------
SET SERVEROUTPUT ON;

--Uspesnost odberov jednotlivych darcov
CREATE OR REPLACE PROCEDURE Uspesnost_Darcov_PRC
IS
pocet_celkovo INT;
pocet_uspesnych INT;
meno_darcu Darca.Meno%TYPE;
priezvisko_darcu Darca.Priezvisko%TYPE;
CURSOR CRS IS
 SELECT * FROM Darca;
BEGIN
FOR Item IN CRS
LOOP
meno_darcu := Item.Meno;
priezvisko_darcu := Item.Priezvisko;
pocet_celkovo := 0;
pocet_uspesnych := 0;
SELECT COUNT(*) INTO pocet_celkovo FROM Odber NATURAL JOIN Darca WHERE Meno = meno_darcu;
IF pocet_celkovo = 0 THEN
  DBMS_OUTPUT.PUT_LINE('Darca ' || meno_darcu || ' ' || priezvisko_darcu || ' este nemal odber.');
ELSE
  SELECT COUNT(*) INTO pocet_uspesnych FROM Odber NATURAL JOIN Darca WHERE Meno = meno_darcu AND TestKrvi = 1;
  DBMS_OUTPUT.PUT_LINE('Uspesnost darcu ' || meno_darcu || ' ' || priezvisko_darcu || ' je ' || ROUND((pocet_uspesnych/pocet_celkovo)*100,2) || '%');
END IF;
END LOOP;
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Nastala neocakavana chyba.');
END Uspesnost_Darcov_PRC;
/

EXECUTE Uspesnost_Darcov_PRC();

--Mnozstvo odobranych davok daneho klienta v %
CREATE OR REPLACE PROCEDURE Mnozstvo_Davok_PRC (cislo_klienta IN INT)
IS
pocet_celkovo INT;
pocet_odobranych INT;
temp INT;
meno_klienta VARCHAR(40);
CURSOR celkovo_CRS IS
 SELECT * FROM Rezervacia WHERE DatumVyzdvihnutia IS NOT NULL;
CURSOR odobranych_CRS IS
 SELECT * FROM Rezervacia NATURAL JOIN Klient WHERE ID_Klient = cislo_klienta AND DatumVyzdvihnutia IS NOT NULL;
BEGIN
pocet_celkovo := 0;
pocet_odobranych := 0;
SELECT CONCAT(CONCAT(Meno, ' '),Priezvisko) INTO meno_klienta FROM Klient WHERE ID_Klient = cislo_klienta;
FOR Item in celkovo_CRS
LOOP
SELECT COUNT(*) INTO temp FROM Odber WHERE ID_Rezervacia = Item.ID_Rezervacia;
pocet_celkovo := pocet_celkovo + temp;
END LOOP;
FOR Item in odobranych_CRS
LOOP
SELECT COUNT(*) INTO temp FROM Odber WHERE ID_Rezervacia = Item.ID_Rezervacia;
pocet_odobranych := pocet_odobranych + temp;
END LOOP;
DBMS_OUTPUT.PUT_LINE('Klient ' || meno_klienta || ' odobral celkovo ' || ROUND((pocet_odobranych/pocet_celkovo)*100,2) || '% vsetkych davok.');
EXCEPTION
WHEN zero_divide THEN
DBMS_OUTPUT.PUT_LINE('Zatial neboli zadane ziadne rezervacie.');
WHEN no_data_found THEN
DBMS_OUTPUT.PUT_LINE('Klient nebol najdeny.');
WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('Nastala neocakavana chyba.');
END Mnozstvo_Davok_PRC;
/

EXECUTE Mnozstvo_Davok_PRC(1);

------------------------------------------------------------------------------------------------------------------------------------------------------
EXPLAIN PLAN FOR
SELECT DatumVyzdvihnutia, COUNT(*) Pocet_Vybavenych_Rezervacii
FROM Klient NATURAL JOIN Rezervacia
WHERE DatumVyzdvihnutia IS NOT NULL
GROUP BY DatumVyzdvihnutia;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--Creating Index
CREATE INDEX IDX ON Rezervacia(DatumVyzdvihnutia);

EXPLAIN PLAN FOR
SELECT DatumVyzdvihnutia, COUNT(*) Pocet_Vybavenych_Rezervacii
FROM Klient NATURAL JOIN Rezervacia
WHERE DatumVyzdvihnutia IS NOT NULL
GROUP BY DatumVyzdvihnutia;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

DROP INDEX IDX;
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE MATERIALIZED VIEW LOG ON xabrah04.Klient WITH PRIMARY KEY, ROWID INCLUDING NEW VALUES;
CREATE MATERIALIZED VIEW MView
NOLOGGING
CACHE
BUILD IMMEDIATE
REFRESH FAST ON COMMIT
ENABLE QUERY REWRITE
AS SELECT * FROM xabrah04.Klient;

GRANT ALL ON Darca TO xabrah04;
GRANT ALL ON Klient TO xabrah04;
GRANT ALL ON Zamestnanec TO xabrah04;
GRANT ALL ON Zamestnanci_Na_Pobocke TO xabrah04;
GRANT ALL ON Zamestnanec_Kona_Odber TO xabrah04;
GRANT ALL ON Odber TO xabrah04;
GRANT ALL ON Rezervacia TO xabrah04;
GRANT ALL ON Pobocka TO xabrah04;
GRANT EXECUTE ON Uspesnost_Darcov_PRC TO xabrah04;
GRANT EXECUTE ON Mnozstvo_Davok_PRC TO xabrah04;
GRANT ALL ON MView TO xabrah04;

SELECT * FROM Mview;
SELECT * FROM xabrah04.Klient;
INSERT INTO xabrah04.Klient (Meno, Priezvisko, Adresa, TelCislo, KlubovaKarta) VALUES ('Daniel', 'Polak', 'Bratislava', '+421775348318', '1234567847358967');
SELECT * FROM Mview;
SELECT * FROM xabrah04.Klient;
COMMIT;
SELECT * FROM Mview;
DROP MATERIALIZED VIEW MView;
DROP MATERIALIZED VIEW LOG ON xabrah04.Klient;