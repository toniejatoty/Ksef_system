if not exists(select * from sys.databases where name = 'ksef')
begin 
create database Ksef
end
go
use Ksef


GO


drop table FaWiersz
drop table fa
drop table podmiot2
drop table podmiot1
drop table TKodKraju
drop table TKodWaluty
drop table LOG_ERR
drop table LOG_H
drop table Staging_Naglowek
drop table Staging_Pozycje
go 
CREATE TABLE TKodKraju (
    KodISO CHAR(2) PRIMARY KEY, -- Np. 'PL'
    NazwaPanstwa NVARCHAR(100)
);
CREATE TABLE TKodWaluty (
    KodISO CHAR(3) PRIMARY KEY, -- Np. 'PLN'
    Nazwa_waluty NVARCHAR(100)
);
create table Podmiot1(
id int primary key identity(1,1),
NIP char(10) not null,
Nazwa nvarchar(512) not null,
TKodKraju CHAR(2) not null,
Adres nvarchar(512) not null
constraint fk_kraj_p1 foreign key (TKodKraju) references tkodkraju(kodISO),
constraint check_nip check(NIP like '[1-9]%' and substring(nip, 2,2)<>'00' and NIP not like '%[^0-9]%')
)
create table Podmiot2(
id int primary key identity(1,1),
NIP char(10) not null,
TKodKraju CHAR(2) not null,
Adres nvarchar(512) not null,
JST integer not null default 2, --jednostka samorzadu terytorialnego  -- Warto�� "1" oznacza, �e faktura dotyczy jednostki podrz�dnej JST. W takim przypadku, aby udost�pni� faktur� jednostce podrz�dnej JST, nale�y wype�ni� sekcj� Podmiot3, w szczeg�lno�ci poda� NIP lub ID-Wew i okre�li� rol� jako 8.                   Warto�� "2" oznacza, �e faktura nie dotyczy jednostki podrz�dnej JST
GV integer not null default 2 -- znacznik cz�onka grupy vat --Znacznik cz�onka grupy VAT.                                                                Warto�� "1" oznacza, �e faktura dotyczy cz�onka grupy VAT. W takim przypadku, aby udost�pni� faktur� cz�onkowi grupy VAT, nale�y wype�ni� sekcj� Podmiot3, w szczeg�lno�ci poda� NIP lub ID-Wew i okre�li� rol� jako 10. Warto�� "2" oznacza, �e faktura nie dotyczy cz�onka grupy VAT
constraint gv_check check(GV in (1,2)),
constraint jst_check check(jst in (1,2)),
constraint fk_kraj_p2 foreign key (TKodKraju) references tkodkraju(kodISO),
constraint check_nip2 check(NIP like '[1-9]%' and substring(nip, 2,2)<>'00' and NIP not like '%[^0-9]%')
)

create table Fa(
id int primary key identity(1,1),
p1 int not null constraint fk_podmiot1 foreign key (p1) references Podmiot1(id),
p2 int not null constraint fk_podmiot2 foreign key (p2) references Podmiot2(id),
KodWaluty Char(3) not null constraint fk_waluta foreign key (KodWaluty) references TKodWaluty(KodISO),
P_1 date not null default CAST(GETDATE() AS DATE) CONSTRAINT CHK_P1_Range CHECK (P_1 BETWEEN '2006-01-01' AND '2050-01-01'),--data wystawienia
P_2 nvarchar(256) unique not null, -- numer faktury unique
P_13_1 decimal(18,2) null, --netto przy 23%,22%  -- _2 to 8%,7% -- _3 to 5%  -- _6 to 0%
P_14_1 decimal(18,2) null, --vat przy 23%,22%   -- _2 to 8%,7%   -- _3 to 5% -- _6 to 0%
P_15 decimal(18,2) not null, --brutto
--adnotacje
    P_16 TINYINT NOT NULL  default 2 CONSTRAINT CHK_P16 CHECK (P_16 IN (1, 2)), --W przypadku dostawy towar�w lub �wiadczenia us�ug, w odniesieniu do kt�rych obowi�zek podatkowy powstaje zgodnie z art. 19a ust. 5 pkt 1 lub art. 21 ust. 1 ustawy - wyrazy "metoda kasowa"; nale�y poda� warto�� "1", w przeciwnym przypadku - warto�� "2"
    P_17 TINYINT NOT NULL default 2 CONSTRAINT CHK_P17 CHECK (P_17 IN (1, 2)), --W przypadku faktur, o kt�rych mowa w art. 106d ust. 1 ustawy - wyraz "samofakturowanie"; nale�y poda� warto�� "1", w przeciwnym przypadku - warto�� "2"
    P_18 TINYINT NOT NULL default 2 CONSTRAINT CHK_P18 CHECK (P_18 IN (1, 2)), -- W przypadku dostawy towar�w lub wykonania us�ugi, dla kt�rych obowi�zanym do rozliczenia podatku od warto�ci dodanej lub podatku o podobnym charakterze jest nabywca towaru lub us�ugi - wyrazy "odwrotne obci��enie"; nale�y poda� warto�� "1", w przeciwnym przypadku - warto�� "2"
    P_18A TINYINT NOT NULL default 2 CONSTRAINT CHK_P18a CHECK (P_18a IN (1, 2)), --W przypadku faktur, w kt�rych kwota nale�no�ci og�em przekracza kwot� 15 000 z� lub jej r�wnowarto�� wyra�on� w walucie obcej, obejmuj�cych dokonan� na rzecz podatnika dostaw� towar�w lub �wiadczenie us�ug, o kt�rych mowa w za��czniku nr 15 do ustawy - wyrazy "mechanizm podzielonej p�atno�ci", przy czym do przeliczania na z�ote kwot wyra�onych w walucie obcej stosuje si� zasady przeliczania kwot stosowane w celu okre�lenia podstawy opodatkowania; nale�y poda� warto�� "1", w przeciwnym przypadku - warto�� "2"
    --zwolnienie
        P_19 TINYINT NULL, -- zwolniony z vat
        P_19N TINYINT default 1 NULL, -- niezwolniony
            P_19A TINYINT NULL, -- jakas tam ustawa
            P_19B TINYINT NULL, --jakas dyrektywa
            P_19C TINYINT null, -- inna inna podstawa prawna
       
    --nowe srodki transport
        P_22N TINYINT null default 1, -- zak�adam ze nie handluje samochodami tu jest sporo opcji
    
    P_23 TINYINT not null default 2 constraint CHK_P23 check(P_23 in (1,2)), -- jakies tr�jstronne
    -- jakies tam marze to chodzi czy podatek od ca�ego czy od wypracowanego zysku
        P_PMarzyN TINYINT null default 1, -- zakladam ze normalnie 
RodzajFaktury char(3) not null constraint che_rodzajfaktury check (RodzajFaktury in ('VAT', 'KOR', 'ZAL', 'ROZ','UPR','KOR_ZAL','KOR_ROZ')),


       CONSTRAINT CHK_Zwolnienie_Logic CHECK (
        (P_19N = 1 AND P_19 IS NULL AND P_19A IS NULL AND P_19B IS NULL AND P_19C IS NULL)
        OR
            (P_19 = 1 AND P_19N IS NULL AND (
            (P_19A = 1 AND P_19B IS NULL AND P_19C IS NULL) OR
            (P_19A IS NULL AND P_19B =1 AND P_19C IS NULL) OR
            (P_19A IS NULL AND P_19B IS NULL AND P_19C =1 ))))
       )


create table FaWiersz(
    id int primary key identity(1,1),
    P_7 nvarchar(512), -- jakas nazwa
    P_8A varchar(256), --jednostka
    P_8B decimal(22,6), -- ilosc
    P_9A decimal(22,8), -- cena per jednostka netto
    P_11 as cast(round(P_8B * P_9A,2) as decimal(18,2)) persisted, -- cena laczna netto
    P_12 varChar(5) constraint ch_P_12 check (P_12 in ('23','22','8','7','5','4','3','0 KR','0 WDT','0 EX','zw','oo','np I','np II')), -- stawka 
    id_fa nvarchar(256) constraint fk_key foreign key (id_fa) references  Fa(P_2)
    )


INSERT INTO TKodKraju (KodISO, NazwaPanstwa) VALUES ('PL', 'POLSKA')
insert into TKodWaluty (KodISO,  Nazwa_waluty) values ('PLN', 'Polski zloty')
INSERT INTO Podmiot1 (NIP, Nazwa, TKodKraju, Adres) 
VALUES ('1111111111', 'Moja Firma Sp. z o.o.', 'PL', 'ul. Wiejska 4/6, 00-902 Warszawa');
/*INSERT INTO Podmiot2 (NIP,TKodKraju, Adres ) VALUES ('2222222222','PL', 'ul. Wiejska 4/6, 00-902 Warszawa');
INSERT INTO Fa (p1,p2,KodWaluty, P_1,P_2, P_13_1, P_14_1, P_15, P_16, P_17, P_18, P_18A, P_19N, P_22N, P_23, P_PMarzyN, RodzajFaktury)
VALUES (1,1,'PLN','2026-04-27', 'F/001/2026',100.00,23.00, 123.00, 2, 2, 2, 2, 1, 1, 2, 1, 'VAT');

INSERT INTO FaWiersz (id_fa, P_7,P_8A, P_8B, P_9A, P_12)
VALUES 
(1, 'Konsultacje techniczne KSeF', 'kg',2, 40.00, '23'), -- 2 szt * 40.00 = 80.00 netto
(1, 'Analiza dokumentacji API', 'time',1, 20.00, '23');   -- 1 szt * 20.00 = 20.00 netto
*/




CREATE TABLE Staging_Naglowek (
    Raw_NIP_Sprzedawcy NVARCHAR(255),
    Raw_Nazwa_Sprzedawcy NVARCHAR(255),
    Raw_Kod_kraju_Sprzedawcy nvarchar(255),
    Raw_Adres_Sprzedawcy NVARCHAR(255),
    Raw_NIP_Nabywcy NVARCHAR(255),
    Raw_kod_kraju_nabywcy nvarchar(255),
    Raw_Adres_Nabywcy NVARCHAR(255),
    Raw_NumerFaktury NVARCHAR(255),
    Raw_DataWystawienia NVARCHAR(255),
    Raw_KodWaluty NVARCHAR(255),
    Raw_KwotaNetto nvarchar(255),
    Raw_KwotaVat nvarchar(255),
    Raw_KwotaBrutto NVARCHAR(255),
    Raw_RodzajFaktury nvarchar(255)
);

CREATE TABLE Staging_Pozycje (
    Raw_NumerFaktury NVARCHAR(255), 
    Raw_NazwaTowaru NVARCHAR(255),
    Raw_jednostka nvarchar(255),
    Raw_Ilosc NVARCHAR(255),
    Raw_CenaJednostkowa NVARCHAR(255),
    Raw_StawkaVAT NVARCHAR(255)
);




CREATE TABLE dbo.LOG_H 
(	log_id		int not null IDENTITY CONSTRAINT PK_LOG_H PRIMARY KEY
,	usr_name	nvarchar(50) NOT NULL DEFAULT USER_NAME()
,	susr_name	nvarchar(50) NOT NULL DEFAULT SUSER_NAME()
,	[host_name]	nvarchar(50) NOT NULL DEFAULT HOST_NAME()
,	log_dt		datetime	NOT NULL DEFAULT GETDATE()
,	h_desc		nvarchar(256) NOT NULL
)
GO
CREATE TABLE dbo.LOG_ERR
(	row_id int not null IDENTITY CONSTRAINT PK_LOG_ERR PRIMARY KEY
,	log_id int not null CONSTRAINT FK_LOG_ERR__LOG_H FOREIGN KEY REFERENCES LOG_H(log_id)
,	err_desc nvarchar(256) NOT NULL
)
GO


go
CREATE or alter PROCEDURE pr_PrzeniesDaneZETL
AS
BEGIN

    declare @i int
    SET NOCOUNT ON;
    insert into log_h(h_desc)
    values('sprawdzam nagłówek')
    set @i = SCOPE_IDENTITY()

    begin try
begin transaction

    declare @n int
    set @n = (SELECT COUNT(1) FROM Staging_Naglowek)
	if @n != 1
    begin
    ;THROW 50001, 'W pliku nagłówkowym nie ma faktury lub wiecej niż 1 faktura', 1;
    end


    if exists(
    SELECT Raw_NIP_Sprzedawcy, Raw_Nazwa_Sprzedawcy, Raw_Kod_kraju_Sprzedawcy, Raw_Adres_Sprzedawcy
    FROM Staging_Naglowek sn
    WHERE NOT EXISTS (SELECT 1 FROM Podmiot1 p WHERE p.NIP = sn.Raw_NIP_Sprzedawcy and p.Adres = sn.Raw_Adres_Sprzedawcy and p.TKodKraju = sn.Raw_Kod_kraju_Sprzedawcy and sn.Raw_Nazwa_Sprzedawcy = p.Nazwa )
)
begin
;throw 50001, 'zly wystawca faktury powinien być tej firmy',1;
return
end

    if exists (select 1 from TKodKraju left join Staging_Naglowek on Raw_kod_kraju_nabywcy = KodISO where kodISO is null )
    begin
    ;throw 50001, 'nie ma takiego kraju nabywcy w bazie',1
    end


    if not exists(select 1 from TKodWaluty join Staging_Naglowek on Raw_KodWaluty = KodISO)
    begin
    ;throw 50001, 'nie ma takiej waluty w slowniku',1
    end

    if exists(select 1 from Staging_Naglowek where try_cast(Raw_DataWystawienia as datetime ) is null )
    begin
    ;throw 50001, 'nie mozna zmienic typu daty wystawienia na date',1
    end

    if exists (select 1 from Staging_Naglowek where try_cast(Raw_DataWystawienia as date) != cast(getdate() as date ))
    begin
    ;throw 50001, 'data wystawienia inna niz dzisiejsza data',1
    end

    if exists (select  1 from Fa join Staging_Naglowek on Raw_NumerFaktury = P_2)
    begin
    ;throw 50001, 'istnieje juz w bazie faktura o takim numerze',1
    end

    if exists (select 1 from Staging_Naglowek where TRY_CAST(replace(Raw_KwotaNetto, ',','.') as decimal(18,2)) is null)
    begin
    ;throw 50001,'nie mozna castowac kwoty netto', 1
    end
    if exists (select 1 from Staging_Naglowek where TRY_CAST(replace(Raw_KwotaVat, ',','.') as decimal(18,2)) is null)
    begin
    ;throw 50001,'nie mozna castowac kwoty vat', 1
    end


    if exists (select 1 from Staging_Naglowek where TRY_CAST(replace(Raw_KwotaBrutto, ',','.') as decimal(18,2)) is null)
    begin
    ;throw 50001,'nie mozna castowac kwoty brutto', 1
    end
    commit transaction
    end try
    begin catch
    if @@TRANCOUNT >0 rollback transaction
        truncate table Staging_Pozycje
    truncate table Staging_Naglowek
    insert into LOG_ERR(log_id, err_desc)
    values(@i, ERROR_MESSAGE())
    ;throw

    
    end catch
    
    insert into log_h(h_desc)
    values('sprawdzam pozycje')
    set @i = SCOPE_IDENTITY()
    
    begin try
    begin transaction
    
    if exists(select 1 from Staging_Pozycje where try_cast(replace(raw_Ilosc,',','.')as decimal(22,6)) is null)
    begin
    ;throw 50001, 'nie mozna castowac ilosci na decimal',1
    end

    if exists(select 1 from Staging_Pozycje where try_cast(replace(Raw_CenaJednostkowa,',','.' )as decimal(22,8)) is null)
    begin
    ;throw 50001, 'nie mozna castowac ceny jednostkowej na decimal',1
    end

    if exists(select 1 from Staging_Pozycje where try_cast(Raw_StawkaVAT as varchar(5)) is null)
    begin
    ;throw 50001, 'nie mozna castowac stawki vat na varcahr 5',1
    end


    INSERT INTO Podmiot2 (NIP,TKodKraju, Adres )
    SELECT DISTINCT Raw_NIP_Nabywcy, try_cast(Raw_kod_kraju_nabywcy as char(2)), Raw_Adres_Nabywcy
    FROM Staging_Naglowek sn
    WHERE NOT EXISTS (SELECT 1 FROM Podmiot2 p WHERE p.NIP = sn.Raw_NIP_Nabywcy and p.Adres = sn.Raw_Adres_Nabywcy and p.TKodKraju = sn.Raw_kod_kraju_nabywcy );


    INSERT INTO Fa (p1, p2, KodWaluty, P_1, P_2, P_13_1, P_14_1, P_15, P_16, P_17, P_18, P_18A, P_19N, RodzajFaktury)
    SELECT 
        (SELECT TOP 1 id FROM Podmiot1 WHERE NIP = sn.Raw_NIP_Sprzedawcy and Nazwa = sn.Raw_Nazwa_Sprzedawcy and Adres = sn.Raw_Adres_Sprzedawcy and TKodKraju = sn.Raw_Kod_kraju_Sprzedawcy),
        (SELECT TOP 1 id FROM Podmiot2 WHERE NIP = sn.Raw_NIP_Nabywcy and Adres = sn.Raw_Adres_Nabywcy and TKodKraju = sn.Raw_kod_kraju_nabywcy),
        sn.Raw_KodWaluty,
        sn.Raw_DataWystawienia,
        sn.Raw_NumerFaktury,
        replace(sn.Raw_KwotaNetto, ',','.'),
        replace(sn.Raw_Kwotavat, ',','.'),
        REPLACE(sn.Raw_KwotaBrutto, ',', '.'),
        2, 2, 2, 2, 1, Raw_RodzajFaktury
    FROM Staging_Naglowek sn

    INSERT INTO FaWiersz (id_fa, P_7,P_8A, P_8B, P_9A, P_12)
    select distinct Raw_NumerFaktury, Raw_NazwaTowaru, Raw_jednostka, Raw_Ilosc, Raw_CenaJednostkowa, Raw_StawkaVAT
    from Staging_Pozycje

    truncate table Staging_Pozycje
    truncate table Staging_Naglowek
    commit transaction

    end try
    begin catch
    if @@TRANCOUNT > 0 rollback transaction
        truncate table Staging_Pozycje
    truncate table Staging_Naglowek
    insert into LOG_ERR(log_id, err_desc)
    values(@i, ERROR_MESSAGE())
    ;throw

    
    end catch
END



go
CREATE or alter PROCEDURE dbo.GenerujKSeF_XML
    @NumerFaktury NVARCHAR(50)
AS
BEGIN
SET NOCOUNT ON;
WITH XMLNAMESPACES (
    'http://www.w3.org/2001/XMLSchema-instance' AS xsi,
    'http://www.w3.org/2001/XMLSchema' AS xsd,
    DEFAULT 'http://crd.gov.pl/wzor/2025/06/25/13775/'
)

SELECT 
    'FA (3)'                              AS [Naglowek/KodFormularza/@kodSystemowy],
    '1-0E'                                AS [Naglowek/KodFormularza/@wersjaSchemy],
    'FA'                                  AS [Naglowek/KodFormularza],
    3                                     AS [Naglowek/WariantFormularza],
    case when GETUTCDATE() between '2025-09-01' and '2050-01-01' then FORMAT(GETUTCDATE(), 'yyyy-MM-ddTHH:mm:ssZ') else cast(1/0 as varchar)  end AS [Naglowek/DataWytworzeniaFa], 
    p1.NIP                               AS [Podmiot1/DaneIdentyfikacyjne/NIP],
    p1.Nazwa                             AS [Podmiot1/DaneIdentyfikacyjne/Nazwa],
    
    p1.TKodKraju                         AS [Podmiot1/Adres/KodKraju],
    p1.Adres                               AS [Podmiot1/Adres/AdresL1],
    p2.NIP                               AS [Podmiot2/DaneIdentyfikacyjne/NIP],
    p2.TKodKraju                         AS [Podmiot2/Adres/KodKraju],
    p2.Adres                               AS [Podmiot2/Adres/AdresL1],
    p2.JST                                 AS [Podmiot2/JST],
    p2.GV                                 AS [Podmiot2/GV],
-- 3. SEKCJA FA (DANE FAKTURY)
    fa.KodWaluty                         AS [Fa/KodWaluty],
    fa.P_1                               AS [Fa/P_1],
    fa.P_2                               AS [Fa/P_2],
    fa.P_13_1                            AS [Fa/P_13_1],
    fa.P_14_1                            AS [Fa/P_14_1],
    fa.P_15                              AS [Fa/P_15],
    fa.P_16                              AS [Fa/Adnotacje/P_16],
    fa.P_17                              AS [Fa/Adnotacje/P_17],
    fa.P_18                              AS [Fa/Adnotacje/P_18],
    fa.P_18A                             AS [Fa/Adnotacje/P_18A],
    fa.P_19N                             AS [Fa/Adnotacje/Zwolnienie/P_19N],
    fa.P_22N                             AS [Fa/Adnotacje/NoweSrodkiTransportu/P_22N],
    fa.P_23                              AS [Fa/Adnotacje/P_23],
    fa.P_PMarzyN                         AS [Fa/Adnotacje/PMarzy/P_PMarzyN],
    fa.RodzajFaktury                     AS [Fa/RodzajFaktury],
    (
        SELECT 
            ROW_NUMBER() OVER(ORDER BY fw.id) AS [NrWierszaFa],
            fw.P_7                            AS [P_7],
            fw.P_8A                           AS [P_8A],
            fw.P_8B                           AS [P_8B],
            fw.P_9A                           AS [P_9A],
            fw.P_11                           AS [P_11],
            fw.P_12                           AS [P_12]
        FROM FaWiersz fw
        WHERE fw.id_fa = fa.P_2
        FOR XML PATH('FaWiersz'), TYPE
    ) [Fa]
    
    FROM Fa fa
    JOIN Podmiot1 p1 ON fa.p1 = p1.id
    JOIN Podmiot2 p2 ON fa.p2 = p2.id
    where fa.P_2 = @NumerFaktury
    FOR XML PATH('Faktura');
    END;
GO
exec GenerujKSeF_XML @NumerFaktury ='F/001/2026'


select * from Podmiot2
select * from Fa
select * from FaWiersz
select * from LOG_ERR
select * from LOG_H