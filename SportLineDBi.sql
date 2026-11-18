/* SPORTLINE BAZA - VELIKI ANALITICKI SKUP PODATAKA
   Microsoft SQL Server / SSMS
   Sve poslovne tabele, kolone, kategorije i statusi su na srpskom (bez kvacica u SQL imenima).
   Skripta kreira bazu, tabele, relacije i veci skup sinteticnih podataka za Power BI.
   Pokrenuti CELOKUPNU skriptu od pocetka. Baza SportLineBazaVelika se resetuje i ponovo pravi.
*/
USE master;
GO
IF DB_ID(N'SportLineBazaVelika') IS NOT NULL
BEGIN
    ALTER DATABASE SportLineBazaVelika SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SportLineBazaVelika;
END;
GO
CREATE DATABASE SportLineBazaVelika;
GO
USE SportLineBazaVelika;
GO

CREATE TABLE dbo.Kategorije(
 KategorijaID INT IDENTITY(1,1) CONSTRAINT PK_Kategorije PRIMARY KEY,
 NazivKategorije NVARCHAR(100) NOT NULL CONSTRAINT UQ_Kategorije_Naziv UNIQUE,
 Opis NVARCHAR(300) NULL
);
GO
CREATE TABLE dbo.Proizvodi(
 ProizvodID INT IDENTITY(1,1) CONSTRAINT PK_Proizvodi PRIMARY KEY,
 SifraProizvoda NVARCHAR(40) NOT NULL CONSTRAINT UQ_Proizvodi_Sifra UNIQUE,
 NazivProizvoda NVARCHAR(150) NOT NULL,
 KategorijaID INT NOT NULL,
 Brend NVARCHAR(80) NOT NULL,
 Velicina NVARCHAR(30) NULL,
 Boja NVARCHAR(50) NULL,
 NabavnaCena DECIMAL(12,2) NOT NULL CHECK(NabavnaCena>=0),
 ProdajnaCena DECIMAL(12,2) NOT NULL CHECK(ProdajnaCena>=0),
 MinimalnaZaliha INT NOT NULL DEFAULT(5) CHECK(MinimalnaZaliha>=0),
 Aktivan BIT NOT NULL DEFAULT(1),
 DatumUnosa DATE NOT NULL DEFAULT(CONVERT(date,GETDATE())),
 CONSTRAINT FK_Proizvodi_Kategorije FOREIGN KEY(KategorijaID) REFERENCES dbo.Kategorije(KategorijaID)
);
GO
CREATE TABLE dbo.Lokacije(
 LokacijaID INT IDENTITY(1,1) CONSTRAINT PK_Lokacije PRIMARY KEY,
 NazivLokacije NVARCHAR(120) NOT NULL CONSTRAINT UQ_Lokacije_Naziv UNIQUE,
 TipLokacije NVARCHAR(20) NOT NULL CHECK(TipLokacije IN(N'Skladiste',N'Prodavnica')),
 Grad NVARCHAR(80) NOT NULL,
 Aktivna BIT NOT NULL DEFAULT(1)
);
GO
CREATE TABLE dbo.Dobavljaci(
 DobavljacID INT IDENTITY(1,1) CONSTRAINT PK_Dobavljaci PRIMARY KEY,
 NazivDobavljaca NVARCHAR(150) NOT NULL,
 Drzava NVARCHAR(80) NOT NULL,
 KontaktEmail NVARCHAR(150) NULL,
 StandardniRokIsporukeDana INT NOT NULL CHECK(StandardniRokIsporukeDana>=0),
 Aktivan BIT NOT NULL DEFAULT(1)
);
GO
CREATE TABLE dbo.ProizvodiDobavljaci(
 ProizvodDobavljacID INT IDENTITY(1,1) CONSTRAINT PK_ProizvodiDobavljaci PRIMARY KEY,
 DobavljacID INT NOT NULL,
 ProizvodID INT NOT NULL,
 NabavnaCenaKodDobavljaca DECIMAL(12,2) NOT NULL CHECK(NabavnaCenaKodDobavljaca>=0),
 RokIsporukeDana INT NOT NULL CHECK(RokIsporukeDana>=0),
 SifraProizvodaKodDobavljaca NVARCHAR(60) NULL,
 PrimarniDobavljac BIT NOT NULL DEFAULT(0),
 CONSTRAINT FK_PD_Dobavljaci FOREIGN KEY(DobavljacID) REFERENCES dbo.Dobavljaci(DobavljacID),
 CONSTRAINT FK_PD_Proizvodi FOREIGN KEY(ProizvodID) REFERENCES dbo.Proizvodi(ProizvodID),
 CONSTRAINT UQ_PD UNIQUE(DobavljacID,ProizvodID)
);
GO
CREATE TABLE dbo.Prodaja(
 ProdajaID BIGINT IDENTITY(1,1) CONSTRAINT PK_Prodaja PRIMARY KEY,
 DatumProdaje DATETIME2(0) NOT NULL,
 LokacijaID INT NOT NULL,
 KanalProdaje NVARCHAR(20) NOT NULL CHECK(KanalProdaje IN(N'Prodavnica',N'Internet')),
 StatusProdaje NVARCHAR(20) NOT NULL DEFAULT(N'Zavrsena') CHECK(StatusProdaje IN(N'Zavrsena',N'Otkazana',N'Vracena')),
 EksternaOznaka NVARCHAR(60) NULL,
 CONSTRAINT FK_Prodaja_Lokacije FOREIGN KEY(LokacijaID) REFERENCES dbo.Lokacije(LokacijaID)
);
GO
CREATE TABLE dbo.StavkeProdaje(
 StavkaProdajeID BIGINT IDENTITY(1,1) CONSTRAINT PK_StavkeProdaje PRIMARY KEY,
 ProdajaID BIGINT NOT NULL,
 ProizvodID INT NOT NULL,
 Kolicina INT NOT NULL CHECK(Kolicina>0),
 ProdajnaCenaPoKomadu DECIMAL(12,2) NOT NULL CHECK(ProdajnaCenaPoKomadu>=0),
 PopustProcenat DECIMAL(5,2) NOT NULL DEFAULT(0) CHECK(PopustProcenat BETWEEN 0 AND 100),
 CONSTRAINT FK_SP_Prodaja FOREIGN KEY(ProdajaID) REFERENCES dbo.Prodaja(ProdajaID),
 CONSTRAINT FK_SP_Proizvodi FOREIGN KEY(ProizvodID) REFERENCES dbo.Proizvodi(ProizvodID)
);
GO
CREATE TABLE dbo.Nabavke(
 NabavkaID BIGINT IDENTITY(1,1) CONSTRAINT PK_Nabavke PRIMARY KEY,
 DobavljacID INT NOT NULL,
 OdredisnaLokacijaID INT NOT NULL,
 DatumPorucivanja DATE NOT NULL,
 OcekivaniDatumIsporuke DATE NOT NULL,
 StvarniDatumIsporuke DATE NULL,
 StatusNabavke NVARCHAR(25) NOT NULL DEFAULT(N'Porucena') CHECK(StatusNabavke IN(N'Priprema',N'Porucena',N'Delimicno primljena',N'Primljena',N'Otkazana')),
 OznakaDobavljaca NVARCHAR(60) NULL,
 CONSTRAINT FK_Nabavke_Dobavljaci FOREIGN KEY(DobavljacID) REFERENCES dbo.Dobavljaci(DobavljacID),
 CONSTRAINT FK_Nabavke_Lokacije FOREIGN KEY(OdredisnaLokacijaID) REFERENCES dbo.Lokacije(LokacijaID),
 CONSTRAINT CK_Nabavke_Ocekivani CHECK(OcekivaniDatumIsporuke>=DatumPorucivanja),
 CONSTRAINT CK_Nabavke_Stvarni CHECK(StvarniDatumIsporuke IS NULL OR StvarniDatumIsporuke>=DatumPorucivanja)
);
GO
CREATE TABLE dbo.StavkeNabavke(
 StavkaNabavkeID BIGINT IDENTITY(1,1) CONSTRAINT PK_StavkeNabavke PRIMARY KEY,
 NabavkaID BIGINT NOT NULL,
 ProizvodID INT NOT NULL,
 PorucenaKolicina INT NOT NULL CHECK(PorucenaKolicina>0),
 NabavnaCenaPoKomadu DECIMAL(12,2) NOT NULL CHECK(NabavnaCenaPoKomadu>=0),
 PrimljenaKolicina INT NOT NULL DEFAULT(0),
 CONSTRAINT FK_SN_Nabavke FOREIGN KEY(NabavkaID) REFERENCES dbo.Nabavke(NabavkaID),
 CONSTRAINT FK_SN_Proizvodi FOREIGN KEY(ProizvodID) REFERENCES dbo.Proizvodi(ProizvodID),
 CONSTRAINT UQ_SN UNIQUE(NabavkaID,ProizvodID),
 CONSTRAINT CK_SN_PrimljenaKolicina CHECK(PrimljenaKolicina>=0 AND PrimljenaKolicina<=PorucenaKolicina)
);
GO
CREATE TABLE dbo.KretanjeZaliha(
 KretanjeZalihaID BIGINT IDENTITY(1,1) CONSTRAINT PK_KretanjeZaliha PRIMARY KEY,
 DatumKretanja DATETIME2(0) NOT NULL,
 ProizvodID INT NOT NULL,
 LokacijaID INT NOT NULL,
 VrstaKretanja NVARCHAR(25) NOT NULL CHECK(VrstaKretanja IN(N'Pocetno stanje',N'Prijem nabavke',N'Prodaja',N'Transfer ulaz',N'Transfer izlaz',N'Povrat',N'Korekcija')),
 KolicinaPromene INT NOT NULL CHECK(KolicinaPromene<>0),
 NabavnaCenaPoKomadu DECIMAL(12,2) NULL CHECK(NabavnaCenaPoKomadu IS NULL OR NabavnaCenaPoKomadu>=0),
 StavkaProdajeID BIGINT NULL,
 StavkaNabavkeID BIGINT NULL,
 GrupaTransfera UNIQUEIDENTIFIER NULL,
 Napomena NVARCHAR(300) NULL,
 CONSTRAINT FK_KZ_Proizvodi FOREIGN KEY(ProizvodID) REFERENCES dbo.Proizvodi(ProizvodID),
 CONSTRAINT FK_KZ_Lokacije FOREIGN KEY(LokacijaID) REFERENCES dbo.Lokacije(LokacijaID),
 CONSTRAINT FK_KZ_StavkeProdaje FOREIGN KEY(StavkaProdajeID) REFERENCES dbo.StavkeProdaje(StavkaProdajeID),
 CONSTRAINT FK_KZ_StavkeNabavke FOREIGN KEY(StavkaNabavkeID) REFERENCES dbo.StavkeNabavke(StavkaNabavkeID)
);
GO
CREATE INDEX IX_Prodaja_Datum ON dbo.Prodaja(DatumProdaje);
CREATE INDEX IX_Prodaja_Lokacija ON dbo.Prodaja(LokacijaID);
CREATE INDEX IX_StavkeProdaje_Proizvod ON dbo.StavkeProdaje(ProizvodID);
CREATE INDEX IX_Nabavke_Datum ON dbo.Nabavke(DatumPorucivanja);
CREATE INDEX IX_KretanjeZaliha_ProizvodLokacijaDatum ON dbo.KretanjeZaliha(ProizvodID,LokacijaID,DatumKretanja);
GO

/* OSNOVNI PODACI */
INSERT INTO dbo.Kategorije(NazivKategorije,Opis) VALUES
(N'Obuca',N'Patike i sportska obuca'),(N'Odeca',N'Majice, duksevi, trenerke i jakne'),
(N'Fitnes oprema',N'Tegovi, prostirke i elasticne trake'),(N'Fudbal',N'Lopte i dodaci za fudbal'),
(N'Planinarenje',N'Rančevi i oprema za boravak u prirodi'),(N'Plivanje',N'Kape i naocare za plivanje');
INSERT INTO dbo.Lokacije(NazivLokacije,TipLokacije,Grad) VALUES
(N'Centralno skladiste Novi Sad',N'Skladiste',N'Novi Sad'),
(N'Prodavnica Novi Sad Centar',N'Prodavnica',N'Novi Sad'),
(N'Prodavnica Beograd',N'Prodavnica',N'Beograd'),
(N'Prodavnica Nis',N'Prodavnica',N'Nis'),
(N'Prodavnica Subotica',N'Prodavnica',N'Subotica');
INSERT INTO dbo.Dobavljaci(NazivDobavljaca,Drzava,KontaktEmail,StandardniRokIsporukeDana) VALUES
(N'SportDistribucija',N'Srbija',N'nabavka@sportdistribucija.example',5),
(N'Adria Sports Supply',N'Hrvatska',N'prodaja@adriasports.example',8),
(N'EuroFit Partner',N'Srbija',N'kontakt@eurofit.example',4),
(N'ActiveWear Trade',N'Slovenija',N'office@activewear.example',9),
(N'Outdoor Centar',N'Srbija',N'prodaja@outdoorcentar.example',6),
(N'GoalLine Oprema',N'Madjarska',N'office@goalline.example',10),
(N'FitPro veleprodaja',N'Srbija',N'nabavka@fitpro.example',3),
(N'Nordic Sport Goods',N'Ceska',N'orders@nordicsport.example',12),
(N'AquaSport Partner',N'Srbija',N'kontakt@aquasport.example',4),
(N'Global Sports Import',N'Njemacka',N'sales@globalsports.example',14);
GO

/* 300 proizvoda - sinteticki, ali poslovno smisleni podaci za analitiku. */
;WITH Brojevi AS(SELECT 1 AS Broj UNION ALL SELECT Broj+1 FROM Brojevi WHERE Broj<300)
INSERT INTO dbo.Proizvodi(SifraProizvoda,NazivProizvoda,KategorijaID,Brend,Velicina,Boja,NabavnaCena,ProdajnaCena,MinimalnaZaliha,DatumUnosa)
SELECT N'SL-'+RIGHT(N'0000'+CONVERT(NVARCHAR(4),Broj),4),
 CASE (Broj-1)%6 WHEN 0 THEN N'Patike za trening ' WHEN 1 THEN N'Sportska majica ' WHEN 2 THEN N'Prostirka za vezbanje ' WHEN 3 THEN N'Fudbalska lopta ' WHEN 4 THEN N'Planinarski ranac ' ELSE N'Naocare za plivanje ' END+CONVERT(NVARCHAR(10),Broj),
 ((Broj-1)%6)+1,
 CASE Broj%5 WHEN 0 THEN N'SportLine' WHEN 1 THEN N'Active' WHEN 2 THEN N'ProFit' WHEN 3 THEN N'Move' ELSE N'OutdoorX' END,
 CASE WHEN (Broj-1)%6=0 THEN CONVERT(NVARCHAR(10),36+(Broj%10)) WHEN (Broj-1)%6=1 THEN CASE Broj%5 WHEN 0 THEN N'XXL' WHEN 1 THEN N'S' WHEN 2 THEN N'M' WHEN 3 THEN N'L' ELSE N'XL' END ELSE NULL END,
 CASE Broj%5 WHEN 0 THEN N'Crna' WHEN 1 THEN N'Plava' WHEN 2 THEN N'Bela' WHEN 3 THEN N'Crvena' ELSE N'Siva' END,
 CONVERT(DECIMAL(12,2),500+(Broj*137%9500)),
 CONVERT(DECIMAL(12,2),(500+(Broj*137%9500))*1.55),
 5+(Broj%16),DATEADD(DAY,-(Broj%500),CONVERT(date,GETDATE()))
FROM Brojevi OPTION(MAXRECURSION 300);
GO

/* Dva dobavljaca po proizvodu */
INSERT INTO dbo.ProizvodiDobavljaci(DobavljacID,ProizvodID,NabavnaCenaKodDobavljaca,RokIsporukeDana,SifraProizvodaKodDobavljaca,PrimarniDobavljac)
SELECT ((P.ProizvodID-1)%10)+1,P.ProizvodID,P.NabavnaCena,D.StandardniRokIsporukeDana,N'DOB-'+P.SifraProizvoda,1
FROM dbo.Proizvodi P JOIN dbo.Dobavljaci D ON D.DobavljacID=((P.ProizvodID-1)%10)+1;
INSERT INTO dbo.ProizvodiDobavljaci(DobavljacID,ProizvodID,NabavnaCenaKodDobavljaca,RokIsporukeDana,SifraProizvodaKodDobavljaca,PrimarniDobavljac)
SELECT (P.ProizvodID%10)+1,P.ProizvodID,CONVERT(DECIMAL(12,2),P.NabavnaCena*1.03),D.StandardniRokIsporukeDana+2,N'ALT-'+P.SifraProizvoda,0
FROM dbo.Proizvodi P JOIN dbo.Dobavljaci D ON D.DobavljacID=(P.ProizvodID%10)+1
WHERE (P.ProizvodID%10)+1<>((P.ProizvodID-1)%10)+1;
GO

/* Pocetne zalihe za svaki proizvod na svakoj lokaciji */
INSERT INTO dbo.KretanjeZaliha(DatumKretanja,ProizvodID,LokacijaID,VrstaKretanja,KolicinaPromene,NabavnaCenaPoKomadu,Napomena)
SELECT DATEADD(DAY,-400,CAST(GETDATE() AS DATETIME2(0))),P.ProizvodID,L.LokacijaID,N'Pocetno stanje',
 80+((P.ProizvodID*7+L.LokacijaID*11)%41),P.NabavnaCena,N'Sinteticki pocetni unos zaliha'
FROM dbo.Proizvodi P CROSS JOIN dbo.Lokacije L;
GO

/* 5000 prodaja sa 1-4 stavke; svaka stavka pravi odgovarajuci izlaz iz zaliha. */
DECLARE @i INT=1,@ProdajaID BIGINT,@Lokacija INT,@Datum DATETIME2(0),@Kanal NVARCHAR(20),@n INT,@j INT,
        @Proizvod INT,@Kol INT,@Cena DECIMAL(12,2),@Popust DECIMAL(5,2),@StavkaID BIGINT;
WHILE @i<=5000
BEGIN
 SET @Lokacija=CASE WHEN @i%5=0 THEN 1 ELSE 2+((@i-1)%4) END;
 SET @Kanal=CASE WHEN @Lokacija=1 THEN N'Internet' ELSE N'Prodavnica' END;
 SET @Datum=DATEADD(MINUTE,-((@i*7919)%1051200),CAST(GETDATE() AS DATETIME2(0)));
 INSERT INTO dbo.Prodaja(DatumProdaje,LokacijaID,KanalProdaje,StatusProdaje,EksternaOznaka)
 VALUES(@Datum,@Lokacija,@Kanal,CASE WHEN @i%97=0 THEN N'Otkazana' WHEN @i%113=0 THEN N'Vracena' ELSE N'Zavrsena' END,N'RAC-'+RIGHT(N'000000'+CONVERT(NVARCHAR(6),@i),6));
 SET @ProdajaID=SCOPE_IDENTITY(); SET @n=1+(@i%4); SET @j=1;
 WHILE @j<=@n
 BEGIN
  SET @Proizvod=1+((@i*13+@j*17)%300); SET @Kol=1+((@i+@j)%3);
  SELECT @Cena=ProdajnaCena FROM dbo.Proizvodi WHERE ProizvodID=@Proizvod;
  SET @Popust=CASE WHEN @i%10=0 THEN 10 WHEN @i%7=0 THEN 5 ELSE 0 END;
  INSERT INTO dbo.StavkeProdaje(ProdajaID,ProizvodID,Kolicina,ProdajnaCenaPoKomadu,PopustProcenat)
  VALUES(@ProdajaID,@Proizvod,@Kol,@Cena,@Popust);
  SET @StavkaID=SCOPE_IDENTITY();
  IF @i%97<>0 AND @i%113<>0
  BEGIN
   INSERT INTO dbo.KretanjeZaliha(DatumKretanja,ProizvodID,LokacijaID,VrstaKretanja,KolicinaPromene,NabavnaCenaPoKomadu,StavkaProdajeID,Napomena)
   SELECT @Datum,@Proizvod,@Lokacija,N'Prodaja',-@Kol,NabavnaCena,@StavkaID,N'Izlaz robe zbog zavrsene prodaje'
   FROM dbo.Proizvodi WHERE ProizvodID=@Proizvod;
  END;
  SET @j+=1;
 END;
 SET @i+=1;
END;
GO

/* 1200 nabavki sa 2-5 stavki; primljene kolicine stvaraju ulaz u zalihama. */
DECLARE @iN INT=1,@NabavkaID BIGINT,@Dobavljac INT,@Odrediste INT,@DatumPor DATE,@Rok INT,@DatumPrijema DATE,
        @BrojStavki INT,@jN INT,@ProizvodN INT,@Poruceno INT,@Primljeno INT,@CenaN DECIMAL(12,2),@StavkaN BIGINT;
WHILE @iN<=1200
BEGIN
 SET @Dobavljac=1+((@iN-1)%10);
 SET @Odrediste=CASE WHEN @iN%3=0 THEN 1 ELSE 2+((@iN-1)%4) END;
 SET @DatumPor=DATEADD(DAY,-((@iN*17)%730),CONVERT(date,GETDATE()));
 SELECT @Rok=StandardniRokIsporukeDana FROM dbo.Dobavljaci WHERE DobavljacID=@Dobavljac;
 SET @DatumPrijema=DATEADD(DAY,@Rok+(@iN%4),@DatumPor);
 INSERT INTO dbo.Nabavke(DobavljacID,OdredisnaLokacijaID,DatumPorucivanja,OcekivaniDatumIsporuke,StvarniDatumIsporuke,StatusNabavke,OznakaDobavljaca)
 VALUES(@Dobavljac,@Odrediste,@DatumPor,DATEADD(DAY,@Rok,@DatumPor),@DatumPrijema,N'Primljena',N'NAB-'+RIGHT(N'00000'+CONVERT(NVARCHAR(5),@iN),5));
 SET @NabavkaID=SCOPE_IDENTITY(); SET @BrojStavki=2+(@iN%4); SET @jN=1;
 WHILE @jN<=@BrojStavki
 BEGIN
  SET @ProizvodN=1+((@iN*19+@jN*23)%300); SET @Poruceno=20+((@iN*5+@jN*7)%81); SET @Primljeno=@Poruceno;
  SELECT @CenaN=NabavnaCena FROM dbo.Proizvodi WHERE ProizvodID=@ProizvodN;
  INSERT INTO dbo.StavkeNabavke(NabavkaID,ProizvodID,PorucenaKolicina,NabavnaCenaPoKomadu,PrimljenaKolicina)
  VALUES(@NabavkaID,@ProizvodN,@Poruceno,@CenaN,@Primljeno);
  SET @StavkaN=SCOPE_IDENTITY();
  INSERT INTO dbo.KretanjeZaliha(DatumKretanja,ProizvodID,LokacijaID,VrstaKretanja,KolicinaPromene,NabavnaCenaPoKomadu,StavkaNabavkeID,Napomena)
  VALUES(DATEADD(HOUR,10,CAST(@DatumPrijema AS DATETIME2(0))),@ProizvodN,@Odrediste,N'Prijem nabavke',@Primljeno,@CenaN,@StavkaN,N'Ulaz robe po primljenoj nabavci');
  SET @jN+=1;
 END;
 SET @iN+=1;
END;
GO

/* ============================ PROVERE ==================================== */
SELECT N'Kategorije' AS NazivTabele,COUNT_BIG(*) AS BrojRedova FROM dbo.Kategorije
UNION ALL SELECT N'Proizvodi',COUNT_BIG(*) FROM dbo.Proizvodi
UNION ALL SELECT N'Lokacije',COUNT_BIG(*) FROM dbo.Lokacije
UNION ALL SELECT N'Dobavljaci',COUNT_BIG(*) FROM dbo.Dobavljaci
UNION ALL SELECT N'ProizvodiDobavljaci',COUNT_BIG(*) FROM dbo.ProizvodiDobavljaci
UNION ALL SELECT N'Prodaja',COUNT_BIG(*) FROM dbo.Prodaja
UNION ALL SELECT N'StavkeProdaje',COUNT_BIG(*) FROM dbo.StavkeProdaje
UNION ALL SELECT N'Nabavke',COUNT_BIG(*) FROM dbo.Nabavke
UNION ALL SELECT N'StavkeNabavke',COUNT_BIG(*) FROM dbo.StavkeNabavke
UNION ALL SELECT N'KretanjeZaliha',COUNT_BIG(*) FROM dbo.KretanjeZaliha;
GO

/* Trenutna zaliha po proizvodu i lokaciji; zbir kretanja daje trenutno stanje */
SELECT P.SifraProizvoda,P.NazivProizvoda,L.NazivLokacije,
 SUM(KZ.KolicinaPromene) AS TrenutnaZaliha,P.MinimalnaZaliha,
 CASE WHEN SUM(KZ.KolicinaPromene)<=P.MinimalnaZaliha THEN N'Niska zaliha' ELSE N'Dovoljna zaliha' END AS StatusZalihe
FROM dbo.KretanjeZaliha KZ
JOIN dbo.Proizvodi P ON P.ProizvodID=KZ.ProizvodID
JOIN dbo.Lokacije L ON L.LokacijaID=KZ.LokacijaID
GROUP BY P.SifraProizvoda,P.NazivProizvoda,L.NazivLokacije,P.MinimalnaZaliha
ORDER BY P.NazivProizvoda,L.NazivLokacije;
GO

/* Prihod od prodaje po mesecu */
SELECT YEAR(P.DatumProdaje) AS Godina,MONTH(P.DatumProdaje) AS Mesec,
 COUNT(DISTINCT P.ProdajaID) AS BrojProdaja,SUM(SP.Kolicina) AS ProdataKolicina,
 SUM(SP.Kolicina*SP.ProdajnaCenaPoKomadu*(1-SP.PopustProcenat/100.0)) AS UkupanPrihod
FROM dbo.Prodaja P JOIN dbo.StavkeProdaje SP ON SP.ProdajaID=P.ProdajaID
WHERE P.StatusProdaje=N'Zavrsena'
GROUP BY YEAR(P.DatumProdaje),MONTH(P.DatumProdaje)
ORDER BY Godina,Mesec;
GO
