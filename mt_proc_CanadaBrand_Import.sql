USE [CanadaOneMT]
GO

/****** Object:  StoredProcedure [dbo].[mt_proc_CanadaBrand_Import]    Script Date: 3/6/2018 7:49:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[mt_proc_CanadaBrand_Import] 
(
@Source varchar(50)
,@Destination varchar(50)
,@ISDebug bit =1
)
As
Begin

Declare 

-- All Updates to Control Tables

@SQL VARCHAR(8000)=''
--,@Source varchar(50)='MarketTrack201705'
--,@Destination varchar(50)='CanadaOneMT'
--,@ISDebug bit =1
--Exec mt_proc_CanadaBrand_Import 'MarketTrack201712','CanadaOneMT',1
/*

 select valuetitle,mediastream,adtype,count(1) 
 from pattern a 
 join [configuration] b ON a.mediastream=b.configurationid 
 join ad c on a.adid=c.adid
 group by valuetitle,mediastream,adtype
 */
SET @SQL='
--**************************************************PRINT*****************************************--
--==='+@Source+'.dbo.Media='+@Destination+'.dbo.Configuration====--

--Make sure no duplicates exist
Select Media,count(1)
From '+@Source+'.dbo.Media
Group by Media
having count(1)>1

--Make sure no duplicates exist
select description,count(distinct Media) From '+@Source+'.dbo.Media
group by description
having count(distinct Media)>1
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Category='+@Destination+'.dbo.RefCategory===--

--Make sure no duplicates exist
select Category,count(1) 
From '+@Source+'.dbo.Category C
Group by Category
having count(1)>1

--Make sure no duplicates exist
select description,count(distinct category) 
From '+@Source+'.dbo.Category C
Group by description
having count(distinct category)>1

--Update existing record
Update '+@Destination+'.dbo.RefCategory Set  CategoryName= C.Description,CreateDT=Add_date,ModifiedDT=chg_date
From '+@Source+'.dbo.Category C
JOIN '+@Destination+'.dbo.RefCategory ON RefCategory.LegacyRefCategoryID=C.Category

Insert Into '+@Destination+'.dbo.RefCategory(CategoryName,CreateDT,ModifiedDT,LegacyRefCategoryID,CreatedByID)
select distinct C.Description as CategoryName,Add_date as CreateDT,chg_date as ModifiedDT,C.Category,1046 as CreatedByID
--Select * 
From '+@Source+'.dbo.Category C
LEFT JOIN '+@Destination+'.dbo.RefCategory ON RefCategory.LegacyRefCategoryID=C.Category
WHERE RefCategory.RefCategoryID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Class='+@Destination+'.dbo.RefSubCategory===--

--Make sure no duplicates exist
select class,count(1) From '+@Source+'.dbo.Class  
Group by class
having count(1)>1

--Update existing record
Update '+@Destination+'.dbo.RefSubCategory
Set SubCategoryName=Class.Description,SubCategoryShortName=Class.Comments,CategoryID=RefCategoryID,CreatedDT=Class.add_date,ModifiedDT=Class.chg_date,Definition1=class.pc_class,Definition2=class.bcrcategory
From '+@Source+'.dbo.Class  
JOIN '+@Destination+'.dbo.RefCategory ON Class.Category=RefCategory.LegacyRefCategoryID
JOIN '+@Destination+'.dbo.RefSubCategory ON RefSubCategory.LegacyRefSubCategoryID=Class.class

Insert Into '+@Destination+'.dbo.RefSubCategory(SubCategoryCODE,SubCategoryName,SubCategoryShortName,LegacyRefSubCategoryID,CategoryID,CreatedDT,ModifiedDT,Definition1,Definition2,CreatedByID)
select distinct ''xx'',Class.Description ,Class.Comments,Class.Class,RefCategory.RefCategoryID,Class.add_date,Class.chg_date,class.pc_class,class.bcrcategory,1046 as CreatedByID
From '+@Source+'.dbo.Class  
JOIN '+@Destination+'.dbo.RefCategory ON Class.Category=RefCategory.LegacyRefCategoryID
LEFT JOIN '+@Destination+'.dbo.RefSubCategory ON RefSubCategory.LegacyRefSubCategoryID=Class.class
Where  RefSubCategory.RefSubCategoryID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Company='+@Destination+'.dbo.Advertiser===--

--Make sure no duplicates exist
select Company,count(1) From '+@Source+'.dbo.Company
Group by Company
having count(1)>1


--Update existing record
Update '+@Destination+'.dbo.Advertiser 
Set Descrip=Company.Description,Address1=Company.ad1,Address2=Company.ad2,City=Company.ad3,CreatedDT=Company.add_date,ModifiedDT=Company.chg_date,AdvertiserComments=Company.comments,ZipCode=Company.postcd,State=Company.Country,ShortName=Company.phone
From '+@Source+'.dbo.Company
JOIN '+@Destination+'.dbo.Advertiser ON Company.Company=Advertiser.LegacyAdvertiserID2

Insert Into '+@Destination+'.dbo.Advertiser(Descrip,LegacyAdvertiserID2,Address1,Address2,City,CreatedDT,ModifiedDT,AdvertiserComments,ZipCode,State,ShortName,CreatedByID)
Select Distinct Company.Description,Company.Company,Company.ad1,Company.ad2,Company.ad3,Company.add_date,Company.chg_date,Company.comments,Company.postcd,Company.Country,Company.phone,1046 as CreatedByID
From '+@Source+'.dbo.Company
LEFT JOIN '+@Destination+'.dbo.Advertiser  ON Company.Company=Advertiser.LegacyAdvertiserID2
WHERE Advertiser.Descrip IS NULL
--AND Company.Company NOT IN (Select LegacyAdvertiserID2 from '+@Destination+'.dbo.Advertiser Where LegacyAdvertiserID2 IS NOT NULL)

--Make Sure No Dupes After Insertion
;With CTE
as
(
select ROW_NUMBER() over(Partition By LegacyAdvertiserId2 Order By AdvertiserID) as Rn,* from '+ @Destination +'.dbo.Advertiser
WHERE LegacyAdvertiserId2 is not null
)
Select  * 
--Into AdvertiserDupes
--Delete
From CTE 
Where Rn>1

--==='+@Source+'.dbo.Corporation='+@Destination+'.dbo.Corporation===--

--Make sure no duplicates exist
select corp,count(1) From  '+@Source+'.dbo.Corporation
Group by corp
having count(1)>1

'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL=
'
UPDATE B
set description=a.Description
,Address1=ad1
,Address2=ad2
,City=ad3
,ZipCode=postcd
,Telephone=phone
,Country=a.country
,Comments=a.comments
,CreateDT=add_date
,ModifiedDT=chg_date
,legacyAdvertiserID=corp
FROM	'+@Source+'.dbo.corporation AS a
LEFT JOIN	'+@Destination+'.dbo.Corporation as b
ON	Cast(a.corp as int)=b.LegacyAdvertiserID

'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL=
'
Insert Into '+@Destination+'.dbo.Corporation(Description,LegacyAdvertiserID,Address1,Address2,City,CreateDT,ModifiedDT,Comments,ZipCode,State,CreatedByID)
Select  Distinct a.Description,a.Corp,a.ad1,a.ad2,a.ad3,a.add_date,a.chg_date,a.comments,a.postcd,a.Country,1046 as CreatedByID
From '+@Source+'.dbo.Corporation a
LEFT JOIN 	 '+@Destination+'.dbo.Corporation b ON Cast(a.corp as int)=b.LegacyAdvertiserID
WHERE b.Description IS NULL

--Make Sure No Dupes After Insertion
;With CTE
as
(
select ROW_NUMBER() over(Partition By LegacyAdvertiserId Order By CorporationID) as Rn,* from '+@Destination+'.dbo.Corporation
Where LegacyAdvertiserId IS NOT NULL
)
Select  * 
--Into CorporationDupes
--Delete
From CTE 
Where Rn>1
'



IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL=
'
Update A Set A.CorporationID=B.CorporationID
--Select * 
From '+@Destination+'.dbo.Advertiser A
JOIN '+@Source+'.dbo.Company ON Company.Description=A.Descrip AND Company.ad1=A.Address1 AND Company.ad2=A.Address2
JOIN '+@Source+'.dbo.Corporation ON Company.corp=Corporation.corp
JOIN '+@Destination+'.dbo.Corporation B ON B.LegacyAdvertiserID=Corporation.Corp --AND Corporation.description=B.Descrip AND  corporation.ad1=B.Address1 AND corporation.ad2=B.Address2
Where A.CorporationID IS NULL

' 

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Market,Province,Region='+@Destination+'.dbo.Market===--

--Make sure no duplicates exist
select Market,count(1) From  '+@Source+'.dbo.Market
Group by Market
having count(1)>1

--Make sure no duplicates exist
select description,count(distinct Market) 
From '+@Source+'.dbo.Market C
Group by description
having count(distinct Market)>1

--Make sure no duplicates exist
select Province,count(1) From  '+@Source+'.dbo.Province
Group by Province
having count(1)>1

--Make sure no duplicates exist
select description,count(distinct Province) 
From '+@Source+'.dbo.Province C
Group by description
having count(distinct Province)>1

--Make sure no duplicates exist
select Region,count(1) From  '+@Source+'.dbo.Region
Group by Region
having count(1)>1

--Make sure no duplicates exist
select description,count(distinct Region) 
From '+@Source+'.dbo.Region C
Group by description
having count(distinct Region)>1


--Update existing record
Update '+@Destination+'.dbo.Market
Set Descrip=M.description
From '+@Destination+'.dbo.Market CM
JOIN '+@Source+'.dbo.Market M ON CM.LegacyMarketID=M.Market 
Where Descrip<>M.description

Update '+@Destination+'.dbo.Market
Set State=P.description
From '+@Destination+'.dbo.Market CM
JOIN '+@Source+'.dbo.Province P ON CM.LegacyStateID=P.Province
Where State<>P.description

Update '+@Destination+'.dbo.Market
Set Region=R.description
From '+@Destination+'.dbo.Market CM
JOIN '+@Source+'.dbo.Region R ON CM.LegacyRegionID=R.Region
Where CM.Region<>R.description

Insert Into '+@Destination+'.dbo.Market(Descrip,State,Region,LegacyMarketID,LegacyStateID,LegacyRegionID,CreatedByID)
select M.Description,P.Description as Province,R.Description as Region ,M.Market,M.Province,M.Region,1046 as CreatedByID
--select * 
From '+@Source+'.dbo.Market M 
JOIN '+@Source+'.dbo.Province P ON M.Province=P.Province
JOIN '+@Source+'.dbo.Region R ON R.Region=M.Region
LEFT JOIN '+@Destination+'.dbo.Market CM ON CM.LegacyMarketID=M.Market
Where CM.Descrip IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Brand='+@Destination+'.dbo.RefProduct===--

--Make sure no duplicates exist
select Brand,count(1) From  '+@Source+'.dbo.Brand
Group by Brand
having count(1)>1

--Check for distinct record
select Brand,class,comp,count(1) From  '+@Source+'.dbo.Brand
Group by Brand,class,comp
having count(1)>1

select Brand,class,corp,count(1) From  '+@Source+'.dbo.Brand
Group by Brand,class,corp
having count(1)>1

--Update existing record
Update P
Set AdvertiserID=ISNULL(AA.AdvertiserID,P.AdvertiserID),SubCategoryID=Sub.RefSubCategoryID,ProductName=B.Description,CreatedDT=B.add_date,ModifiedDT=chg_date,EndDate=CASE WHEN ISNULL(obs_flag,'''')=''O'' THEN B.obs_date ELSE NULL END
From '+@Source+'.dbo.Brand B
JOIN '+@Destination+'.dbo.RefSubCategory Sub ON Sub.LegacyRefSubCategoryID=B.class
LEFT JOIN '+@Destination+'.dbo.Advertiser AA ON AA.LegacyAdvertiserID2=B.comp
--LEFT JOIN '+@Destination+'.dbo.Advertiser A ON A.LegacyAdvertiserID=B.corp
JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=B.Brand --AND P.AdvertiserID=ISNULL(AA.AdvertiserID,P.AdvertiserID) AND P.SubCategoryID =Sub.RefSubCategoryID


Insert Into '+@Destination+'.dbo.RefProduct(AdvertiserID,SubCategoryID,ProductName,CreatedDT,ModifiedDT,LegacyRefProductID,EndDate,CreatedByID)
select Distinct AA.AdvertiserID as AdvertiserID ,Sub.RefSubCategoryID,B.Description as ProductName,B.add_date as CreatedDT,chg_date as ModifiedDT,B.Brand as LegacyRefProductID,CASE WHEN ISNULL(obs_flag,'''')=''O'' THEN B.obs_date ELSE NULL END,1046 as CreatedByID
From '+@Source+'.dbo.Brand B
JOIN '+@Destination+'.dbo.RefSubCategory Sub ON Sub.LegacyRefSubCategoryID=B.class
LEFT JOIN '+@Destination+'.dbo.Advertiser AA ON AA.LegacyAdvertiserID2=B.comp
--LEFT JOIN '+@Destination+'.dbo.Advertiser A ON A.LegacyAdvertiserID=B.corp
LEFT JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=B.Brand --AND P.AdvertiserID=AA.AdvertiserID  AND P.SubCategoryID =Sub.RefSubCategoryID
Where P.ProductName IS NULL AND AA.AdvertiserID IS NOT NULL

--Make Sure No Dupes AFter Insertion
select LegacyRefProductId,count(1) 
from '+ @Destination +'.dbo.RefProduct
where LegacyRefProductId IS NOT NULL
Group by LegacyRefProductId
having count(1)>1

--Make sure not records with Orphan AdvertiserID
Select * from refproduct where advertiserid not in (select AdvertiserID From Advertiser)
select * from refproduct where advertiserid IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
update P SET P.AdvertiserID = AA.AdvertiserID
From '+@Source+'.dbo.Brand B
JOIN '+@Destination+'.dbo.RefSubCategory Sub ON Sub.LegacyRefSubCategoryID=B.class
LEFT JOIN '+@Destination+'.dbo.Advertiser AA ON AA.LegacyAdvertiserID2=B.comp
LEFT JOIN '+@Destination+'.dbo.corporation A ON A.LegacyAdvertiserID=B.corp
LEFT JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=B.brand  --AND P.ProductName=B.Description AND P.SubCategoryID =Sub.RefSubCategoryID 
Where AA.AdvertiserID IS NOT NULL and p.advertiserid <> aa.advertiserid
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
--==='+@Source+'.dbo.prtmsthdr.Language='+@Destination+'.dbo.Language===--
Insert Into '+@Destination+'.dbo.Language(Description,CreatedByID)
select L1.Description,1046 as CreatedByID from OneMT_Dev.dbo.Language L1 
LEFT JOIN '+@Destination+'.dbo.Language L2 ON L1.Description=L2.Description
WHERE L2.Description IS NULL AND L1.Description in (''English'',''French'')'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.prtmsthdr='+@Destination+'.dbo.Size===--
Insert Into '+@Destination+'.dbo.Size(Width,Height,SizingMethodID,CreatedDT,CreatedByID)
Select Distinct columns,lines, 0 as  SizingMethodID,getdate() as CreatedDT, 1046 as CreatedByID 
From '+@Source+'.dbo.prtmsthdr A
LEFT JOIN '+@Destination+'.dbo.Size B ON A.columns=B.Width AND A.lines=B.Height 
Where B.Height IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.prtmsthdr='+@Destination+'.dbo.Publication===--
--Make sure no duplicates exist
select code,type,count(1) from '+@Source+'.dbo.prtmsthdr
group by code,type
having count(1)>1
order by 2 desc

Insert Into '+@Destination+'.dbo.Publication(MarketId,Descrip,PubType,CreatedDT,ModifiedDT,LegacyPubCode,LanguageID,MagSizeID,PubCode,CreatedByID)
select B.MarketId,A.Description,0,add_date as CreatedDT,chg_date as ModifiedDT ,Code ,L.LanguageID,S.SizeID,A.type,1046 as CreatedByID
from '+@Source+'.dbo.prtmsthdr A
LEFT JOIN '+@Destination+'.dbo.Market B ON A.market=B.LegacyMarketID
LEFT JOIN '+@Destination+'.dbo.Language L ON left(L.Description,1)=A.language AND L.Description<>''English/French''
LEFT JOIN '+@Destination+'.dbo.Size S ON A.columns=S.Width AND A.lines=S.Height
LEFT JOIN '+@Destination+'.dbo.Publication P ON P.LegacyPubCode=A.Code AND P.PubCode=A.type
WHERE P.Descrip IS NULL'


IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


/*
Update A Set Pubcode=B.type
From '+@Destination+'.dbo.Publication A 
JOIN '+@Destination+'.dbo.prtmsthdr B ON A.Descrip=B.description AND A.LegacyPubCode=B.code
*/
set @SQL='
--==='+@Destination+'.dbo.Publication='+@Destination+'.dbo.PubEdition===--
--Update existing record
Update B
Set PublicationID=A.PublicationID,LanguageID=ISNULL(A.LanguageID,0),MarketID=ISNULL(A.MarketID,0),EditionName=Descrip,CreatedDT=ISNULL(A.CreatedDT,B.CreatedDT)
From '+@Destination+'.dbo.Publication A 
JOIN '+@Destination+'.dbo.PubEdition B ON A.LegacyPubCode=B.LegacyPubEditionID AND A.PubCode=B.LegacyPubCode

Insert Into '+@Destination+'.dbo.PubEdition(PublicationID,LanguageID,MarketID,EditionName,DefaultInd,CreatedDT,LegacyPubEditionID,LegacyPubCode,CreatedByID)
select Distinct A.PublicationID,CASE WHEN A.LanguageID IS NULL THEN 0 ELSE A.LanguageID END AS LanguageID,CASE WHEN  A.MarketID IS NULL THEN 0 ELSE A.MarketID END as MarketId,Descrip as EditionName,1 as DefaultInd, A.CreatedDT,A.LegacyPubCode as LegacyPubEditionID,A.PubCode as LegacyPubCode,1046 as CreatedByID
From '+@Destination+'.dbo.Publication A 
LEFT JOIN '+@Destination+'.dbo.PubEdition B ON A.LegacyPubCode=B.LegacyPubEditionID AND A.PubCode=B.LegacyPubCode
WHERE B.EditionName IS NULL

--===Make Sure no Dupes using below query, as per Jeff''s Email on 10-6-2017====--
select LegacyPubEditionID,LegacyPubCode,count(1) 
from '+ @Destination +'.dbo.PubEdition
Group by LegacyPubEditionID,LegacyPubCode
having count(1)>1'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)



SET @SQL='
--==='+@Source+'.dbo.prthmhdr='+@Destination+'.dbo.Ad===--

--Make sure no duplicates exist
select theme,count(1) From '+@Source+'.dbo.prthmhdr T 
Group by theme
having count(1)>1

--Update existing record
Update Ad
Set AdName=T.desc_key,Description=ISNULL(ISNULL(M.Description,T.Description),Ad.Description),LanguageID=ISNULL(L.LanguageID,Ad.LanguageID)
--,ProductId=ISNULL(RP.RefProductID,Ad.ProductId),AdvertiserID=ISNULL(RP.AdvertiserID,Ad.AdvertiserID)
,AddlInfo=ISNULL(P.PublicationID,Ad.AddlInfo),BreakDt=T.pub_date,MarketID=ISNULL(P.MarketID,Ad.MarketID)
,LegacyRefProductID=ISNULL(R.Brand1,Ad.LegacyRefProductID)
,LegacyPubCode=ISNULL(P.LegacyPubCode,Ad.LegacyPubCode)
From '+@Source+'.dbo.prthmhdr T 
JOIN '+@Destination+'.dbo.Ad ON Ad.LegacyAdID=T.theme AND Ad.AdType=''14''
LEFT JOIN '+@Source+'.dbo.prthmbrd R ON T.theme=R.theme
--LEFT JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=R.brand
LEFT JOIN '+@Destination+'.dbo.Language L ON Left(L.Description,1)=T.Language AND L.Description<>''English/French''
LEFT JOIN '+@Destination+'.dbo.Publication P ON P.LegacyPubCode=T.pub AND P.PubCode=T.media
LEFT JOIN '+@Source+'.dbo.bcrdatamst M ON M.theme=T.theme AND SUBSTRING(refid,3,1) IN (''M'',''P'')

Insert Into '+@Destination+'.dbo.Ad(LegacyAdID,AdName,Description,LanguageID
--,ProductId,AdvertiserID
,AdType,AddlInfo,BreakDt,MarketID
,LegacyRefProductID
,LegacyPubCode,Unclassified,CreatedBy,Campaign,CreateDate )
select Distinct T.theme,T.desc_key,ISNULL(M.Description,T.Description) as Description,L.LanguageID
--,RP.RefProductID as ProductId,RP.AdvertiserID
,''14'' as AdType,P.PublicationID,T.pub_date,P.MarketID
,R.Brand1
,P.LegacyPubCode, 0 as Unclassified ,1046 as CreatedBy,M.RefId,getdate() as CreateDate
From '+@Source+'.dbo.prthmhdr T 
LEFT JOIN '+@Source+'.dbo.prthmbrd R ON T.theme=R.theme
--LEFT JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=R.brand
LEFT JOIN '+@Destination+'.dbo.Language L ON Left(L.Description,1)=T.Language AND L.Description<>''English/French''
LEFT JOIN '+@Destination+'.dbo.Publication P ON P.LegacyPubCode=T.pub AND P.PubCode=T.media
LEFT JOIN '+@Destination+'.dbo.Ad ON Ad.LegacyAdID=T.theme --AND Ad.AdType=''14''
LEFT JOIN '+@Source+'.dbo.bcrdatamst M ON M.theme=T.theme AND SUBSTRING(refid,3,1) IN (''M'',''P'')
Where Ad.AdID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
Select LegacyAdID,count(1) 
From Ad where LegacyAdID IS NOT NULL
group by LegacyAdID
having count(1) >1'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
Insert Into '+@Destination+'.dbo.AdProduct(AdID,ProductId,PrimaryInd, CreatedBy)
Select Distinct Ad.AdID,RP.RefProductID,CASE WHEN R.brand=R.brand1 then 1 ELSE 0 END as PrimaryInd ,1046 as CreatedBy
From '+@Destination+'.dbo.Ad  
JOIN '+@Source+'.dbo.prthmbrd R ON Ad.LegacyAdID=R.theme AND Ad.AdType=''14''
JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=R.brand
LEFT JOIN '+@Destination+'.dbo.AdProduct AP ON Ad.AdID=AP.AdID AND RP.RefProductID=AP.ProductID
Where AP.AdID IS NULL'


IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--Fix as per CB-424(1-22-18)
Insert Into '+@Destination+'.dbo.AdProduct(AdID,ProductId,PrimaryInd, CreatedBy)
select distinct Ad.AdId,RefProductId, 0 as PrimaryInd,1046 as CreatedBy--b.theme,b.brand
from '+@Source+'.dbo.prt_trans_WithRn B
JOIN '+@Destination+'.dbo.Ad ON Ad.LegacyAdID=b.theme 
JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=b.brand
LEFT JOIN '+@Source+'.dbo.prthmbrd A  ON A.theme=B.theme AND A.brand=B.brand
LEFT JOIN '+@Destination+'.dbo.AdProduct AP ON AP.AdID=Ad.AdID AND AP.AdProductID=P.RefProductID
where A.theme IS NULL AND Ap.AdID IS NOT NULL
AND B.theme<>''000000''
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
INSERT INTO '+@Destination+'.dbo.Creative(AdId,PrimaryIndicator)
Select Ad.AdID ,1 AS PrimaryIndicator
From '+@Destination+'.dbo.Ad
LEFT JOIN '+@Destination+'.dbo.Creative ON Ad.AdID=Creative.AdId
Where Creative.AdId IS NULL  AND Ad.LegacyAdID IS NOT NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)



SET @SQL='
--==='+@Destination+'.dbo.Ad='+@Destination+'.dbo.Pattern===--
Insert Into '+@Destination+'.dbo.Pattern(AdId ,[Status],CreativeSignature,FormatCode,SalesStartDT,QueryCategory,LegacyRefProductID,LegacyPubCode,MediaStream,LegacyAdID,CreativeID,CreateBy)
Select Distinct A.AdID,''Valid'' as [Status],A.LegacyAdID as CreativeSignature,AddlInfo,BreakDt,MarketID,A.LegacyRefProductID,A.LegacyPubCode,84 as MediaStream,A.LegacyAdID,C.PK_Id,1046 as CreateBy
From '+@Destination+'.dbo.Ad A 
JOIN '+@Destination+'.dbo.Creative C ON A.AdId=C.AdId
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
WHERE B.AdID IS NULL AND A.AdType=''14'' AND A.LegacyAdId IS NOT NULL
option(maxdop 1)'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--Make sure below query returns 0 - Records exist in Ad but not in Pattern
Select count(1)
From '+@Destination+'.dbo.Ad A
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.LegacyAdID IS NOT NULL 
AND B.AdID IS NULL

--Make sure below query returns 0 - Records exist in Pattern but not in Ad
Select count(1)
From '+@Destination+'.dbo.Ad A
RIGHT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.AdID IS NULL AND B.LegacyAdID IS NOT NULL
'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.prt_trans='+@Destination+'.dbo.OccurrenceDetailPUB===--
IF EXISTS(SELECT name FROM '+@Source+'.dbo.sysobjects WHERE name = N''prt_trans_WithRn'' AND xtype=''U'')
	Drop Table '+@Source+'.dbo.prt_trans_WithRn 

;With CTE
as
(
Select 
TransNo,transseq,theme,Colour,brand,pub,pub_date,Size,Section,Media,cast(0 as Int) as PubSectionID,type
,ROW_NUMBER() over(Partition By Colour,Size,theme,pub_date,brand,pub,Size  Order by TransNo,transseq) as Rn
From '+@Source+'.dbo.prt_trans where type = ''A''
)
Select * 
Into '+@Source+'.dbo.prt_trans_WithRn
From CTE
Where Rn=1

CREATE NONCLUSTERED INDEX IDX_prt_trans ON '+@Source+'.dbo.prt_trans_WithRn ([pub],[section])
CREATE NONCLUSTERED INDEX IDX_prt_trans_BTP ON '+@Source+'.dbo.prt_trans_WithRn([brand] ,[theme],[pub] ,[pub_date]) INCLUDE ( [size],[colour])
CREATE NONCLUSTERED INDEX Idx_prt_trans_Media ON '+@Source+'.dbo.prt_trans_WithRn ([media] ,[pub] ) INCLUDE ( [section])
CREATE NONCLUSTERED INDEX IDX_prt_trans_Pub_Media ON '+@Source+'.dbo.prt_trans_WithRn ([pub],[Media]) INCLUDE(Pub_date)

Update t
set PubSectionID=s.pubsectionid
From '+@Source+'.dbo.prt_trans_WithRn  t
JOIN '+@Destination+'.dbo.Publication p ON t.pub = p.legacyPubCode  
JOIN '+@Destination+'.dbo.Pubsection s ON p.PublicationID = s.publicationid and t.section = s.PubSectionName 
Where t.media = ''D''
Option(maxdop 1)

IF EXISTS(SELECT name FROM tempdb.dbo.sysobjects WHERE name = N''FullPubIssue'' AND xtype=''U'')
	Drop Table tempdb.dbo.FullPubIssue

Select Distinct 1 as SenderID,A.PubEditionID,pub_date as IssueDate,getdate() as CreateDTM,''1046'' as CreateBy,A.PublicationID as PublicationID ,B.MagSizeID,B.LegacyPubCode,B.PubCode
Into tempdb.dbo.FullPubIssue
From '+@Destination+'.dbo.PubEdition A 
JOIN '+@Destination+'.dbo.Publication B ON A.PublicationID=B.PublicationID
JOIN '+@Source+'.dbo.prt_trans_WithRn T ON T.pub=B.LegacyPubCode AND T.media=B.PubCode
JOIN (select FormatCode From '+@Destination+'.dbo.Pattern) PT ON PT.FormatCode=B.PublicationID
option(maxdop 1)

Insert Into  '+@Destination+'.dbo.PubIssue (SenderID,PubEditionID,IssueDate,CreateDTM,CreateBy,PublicationID,FK_PubSection,LegacyPubCode,LegacyMediaCode)
select A.* --,1046 as CreateBy
From tempdb.dbo.FullPubIssue A
LEFT JOIN  '+@Destination+'.dbo.PubIssue B ON A.IssueDate=B.IssueDate AND A.LegacyPubCode=B.LegacyPubCode AND A.PubCode=B.LegacyMediaCode
Where B.PubIssueID IS NULL

--=================BELOW IS THE NEW CHANGE FOR MISSING RECORDS, QC BEFORE INSERTING RECORDS=================--
--====Dupes Delete from NielsenMarketTRackSizeLookup table =====--
;With CTE
as
(
Select *,ROW_NUMBER() Over(Partition By NielsenSize Order By MarketTrackSizeID) Rn
from '+@Source+'.dbo.NielsenMarketTRackSizeLookup 
)
--Select * 
Delete A
From '+@Source+'.dbo.NielsenMarketTRackSizeLookup  A
LEFT JOIN MT3SQL4.'+ Concat(Left(@Source,Len(@Source)-1),cast(cast(Right(@Source,1) as Int)-1 as varchar)) +'.dbo.NielsenMarketTRackSizeLookup  B ON A.NielsenSize=B.NielsenSize AND A.MarketTrackSizeID=B.MarketTrackSizeID
Where A.NielsenSize In (Select distinct NielsenSize  From CTE Where Rn>1)
AND B.NielsenSize IS NULL


;With CTE
as
(
Select *,ROW_NUMBER() Over(Partition By NielsenSize Order By MarketTrackSizeID) Rn
from '+@Source+'.dbo.NielsenMarketTRackSizeLookup 
)
--Select *
Delete
From CTE
Where Rn>1
--=========--
Insert Into  '+@Destination+'.dbo.OccurrenceDetailPUB (CreatedDT,AdID,PatternID,LegacyOccurrenceDetailPUBID,AdDT,PubIssueID,SizeID,MarketID,Color,Size,PubsectionID,transno ,transseq,CreatedByID)
Select Distinct getdate() as CreatedDT,A.AdID,A.PatternID,A.FormatCode as LegacyOccurrenceDetailPUBID,P.Pub_date,I.PubIssueID,Isnull(N.MarketTrackSizeID,0) as SizeID,A.QueryCategory,P.colour,P.size,P.PubsectionID,P.transno,P.transseq,1046 as CreatedByID
From '+@Destination+'.dbo.Pattern A
JOIN '+@Destination+'.dbo.Ad B ON A.AdId=B.AdId AND B.AdType=''14''
JOIN '+@Source+'.dbo.prt_trans_WithRn P ON P.theme=A.CreativeSignature --AND P.brand=A.LegacyRefProductID--AND P.pub=A.LegacyPubCode
JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=P.brand 
LEFT JOIN '+@Destination+'.dbo.PubIssue I ON p.pub_date=I.IssueDate AND P.pub=I.LegacyPubCode AND P.Media=I.LegacyMediaCode
Left JOIN '+@Source+'.dbo.NielsenMarketTRackSizeLookup as N On n.NielsenSize=P.Size 
LEFT JOIN '+@Destination+'.dbo.OccurrenceDetailPUB O ON O.transno=P.transno AND O.transseq=P.transseq
Where O.PatternID IS NULL  and P.pub_date>=''01-01-2014'''

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--Fix as per CB-424(1-22-18)
Insert Into '+@Destination+'.dbo.AdProduct(AdID,ProductId,PrimaryInd, CreatedBy)
select distinct Ad.AdId,RefProductId, 0 as PrimaryInd,1046 as CreatedBy--b.theme,b.brand
from '+@Source+'.dbo.prt_trans_WithRn B
JOIN '+@Destination+'.dbo.Ad ON Ad.LegacyAdID=b.theme 
JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=b.brand
LEFT JOIN '+@Source+'.dbo.prthmbrd A  ON A.theme=B.theme AND A.brand=B.brand
LEFT JOIN '+@Destination+'.dbo.AdProduct AP ON AP.AdID=Ad.AdID AND AP.AdProductID=P.RefProductID
where A.theme IS NULL AND Ap.AdID IS NOT NULL
AND B.theme<>''000000''
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL=' 
--===Update PrimaryOccurrenceID===--
	Update Ad Set PrimaryOccurrenceID = MinOcc
	from '+@Destination+'.dbo.Ad 
	inner join (
	Select adId, min (OccurrenceDetailPubId) MinOcc
	from '+@Destination+'.dbo.[OccurrenceDetailPUB]
	group by adId) as s1 on Ad.AdId = s1.AdId 
	where PrimaryOccurrenceID is null
	and AdType = ''14''
	
	'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL=
'insert into '+@Destination+'.[dbo].[CreativeDetailPUB](
CreativeMasterID, 
CreativeAssetName,
CreativeRepository, 
LegacyCreativeAssetName, 
CreativeFileType, 
Deleted, 
PageNumber, 
PageTypeID, 
PageName, 
PubPageNumber)
select distinct
CreativeId CreativeMasterID, 
Ad.LegacyAdID CreativeAssetName,
''archive\print\'' CreativeRepository, -- file path (eg PUB\23\Original\ so archive\print\)
Ad.LegacyAdID LegacyCreativeAssetName, --not needed by use same as file name
''jpg'' CreativeFileType, --jpg
0 Deleted, --0
1 PageNumber, --1
''B''PageTypeID, --B
1 PageName, --1
1 PubPageNumber --1
from '+@Destination+'.[dbo].AD
inner join '+@Destination+'.[dbo].[Creative] on Creative.AdId = Ad.AdId
INNER JOIN '+@Destination+'.[dbo].[Pattern] ON  [dbo].[Creative].PK_Id=[dbo].[Pattern].CreativeID
INNER JOIN '+@Destination+'.[dbo].[OccurrenceDetailPUB] ON dbo.[OccurrenceDetailPUB].[PatternID]=[Pattern].[PatternID]
where ad.LegacyAdID is not null
and CreativeId not in (select CreativeMasterID from '+@Destination+'.[dbo].[CreativeDetailPUB])
'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='Update '+@Destination+'.[DBO].[Creative] set SourceOccurrenceId= OccurrenceDetailPUBID
from '+@Destination+'.[dbo].[Creative] 
INNER JOIN '+@Destination+'.[dbo].[Pattern] ON  [dbo].[Creative].PK_Id=[dbo].[Pattern].CreativeID
INNER JOIN '+@Destination+'.[dbo].[OccurrenceDetailPUB] ON dbo.[OccurrenceDetailPUB].[PatternID]=[Pattern].[PatternID]
where  SourceOccurrenceId is null
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)




SET @SQL='
--==='+@Source+'.dbo.prtPubVolDisc='+@Destination+'.dbo.Promotion===--
Insert Into '+@Destination+'.dbo.Promotion(CropID,CategoryID,AdvertiserID,ProductID,PromoPrice,CreatedDT,CreatedByID,AuditedDT)
Select AA.* From(
Select Distinct 0 as CropID,0 as CategoryID,Adv.AdvertiserID,0 RefProductID,Discount,getdate() as CreatedDT,1046 as CreatedByID,EffectiveFrom
From  '+@Source+'.dbo.prtCompDiscLevel A 
JOIN  '+@Source+'.dbo.prtPubVolDisc D ON A.yyyy=D.yyyy AND A.media=D.Media AND A.pub=D.Pub AND A.DiscountLevel=D.DiscountLevel
JOIN  '+@Source+'.dbo.company C ON C.corp=A.corp
JOIN '+@Destination+'.dbo.Advertiser Adv ON Adv.LegacyAdvertiserID2=c.company ) AA
LEFT JOIN '+@Destination+'.dbo.Promotion P ON AA.AdvertiserID=P.AdvertiserID AND P.PromoPrice=cast(AA.Discount as decimal(18, 2)) AND P.AuditedDT=cast(AA.EffectiveFrom as datetime)
Where P.CropID IS NULL'


IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @sql='
--**************************************************TV*****************************************--

--===OneMT_Dev.dbo.RefEthinicGroup='+@Destination+'.dbo.RefEthinicGroup===--
INSERT INTO '+@Destination+'.dbo.RefEthinicGroup(CTLegacyLanguageID,EthnicGroupName,Notes,CreatedDT,ModifiedDT,ModifiedByID,CreateByID)
Select CTLegacyLanguageID,EthnicGroupName,Notes,CreatedDT,ModifiedDT,ModifiedByID ,1046 as CreateByID
From OneMT_Dev.dbo.RefEthinicGroup
Where EthnicGroupName NOT IN (Select EthnicGroupName  From '+@Destination+'.dbo.RefEthinicGroup)'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Networks='+@Destination+'.dbo.TVNetwork===--

--Make sure no duplicates exist
select * from  '+@Source+'.dbo.Network
select NetworkID,count(1) from  '+@Source+'.dbo.Networks
Group by NetworkID
having count(1)>1

--Make sure no duplicates exist
select NetworkName,count(distinct NetworkID) from  '+@Source+'.dbo.Networks
Group by NetworkName
having count(distinct NetworkID)>1

--Update existing record
Update D
Set NetworkShortName=B.NetworkName
From '+@Source+'.dbo.Network A 
JOIN '+@Source+'.dbo.Networks B ON A.network=B.networkID
JOIN '+@Source+'.dbo.Station C ON C.Station=A.Station
JOIN '+@Destination+'.dbo.TVNetwork D ON B.NetworkID=D.LegacyTVNetworkID
Where Stat_type In (''T'') 

INSERT INTO '+@Destination+'.dbo.TVNetwork(LegacyTVNetworkID,NetworkShortName,CreatedDT,CreatedByID)
select distinct B.NetworkID,B.NetworkName,getdate() as CreatedDT, 1046 as CreatedByID
From '+@Source+'.dbo.Network A 
JOIN '+@Source+'.dbo.Networks B ON A.network=B.networkID
JOIN '+@Source+'.dbo.Station C ON C.Station=A.Station
LEFT JOIN '+@Destination+'.dbo.TVNetwork D ON B.NetworkID=D.LegacyTVNetworkID
Where Stat_type In (''T'') AND D.TVNetworkID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.Networks='+@Destination+'.dbo.TVNetwork===--

--Make sure no duplicates exist
select station,count(1) 
from  '+@Source+'.dbo.station
where stat_type In (''T'') AND ISNULL(market,'''')<>''''
Group by station
having count(1)>1

Insert Into '+@Destination+'.dbo.TVStation(LegacyStation,StationShortName,EthnicGroupId,MarketID,NetworkID,CreatedDT,CreatedByID,StationFullName)
Select Distinct A.Station,call,4 as EthnicGroupId,0 as MarketId,0 as NetWorkID,getdate() as CreatedDT,1046 as CreatedByID,Description as  StationFullName
From '+@Source+'.dbo.station A
LEFT JOIN '+@Destination+'.dbo.TVStation E ON E.LegacyStation=A.Station
Where stat_type In (''T'') 
AND E.TVStationID IS NULL

INSERT Into '+@Destination+'.dbo.TVStationMap(TVStationID,MarketID,NetworkID)
Select Distinct F.TVStationID,B.MarketId,  ISNULL(D.TVNetworkID,0) as TVNetworkID
From '+@Source+'.dbo.station A
JOIN '+@Destination+'.dbo.TVStation F ON F.LegacyStation=A.Station
LEFT JOIN '+@Destination+'.dbo.Market B ON A.market=B.LegacyMarketID
LEFT JOIN '+@Source+'.dbo.Network C ON A.station=C.Station
LEFT JOIN '+@Destination+'.dbo.TVNetwork D ON C.network=D.LegacyTVNetworkID
LEFT JOIN '+@Destination+'.dbo.TVStation E ON E.LegacyStation=A.Station
LEFT JOIN '+@Destination+'.dbo.TVStationMap G ON G.TVStationID= F.TVStationID
Where stat_type In (''T'') AND G.TVStationID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Destination+'.dbo.TVProgram='+@Source+'.dbo.program===--
--Make sure no duplicates exist
select program,count(1) from '+@Source+'.dbo.program
group by program
having count(1)>1
order by 2 desc

--Update existing record
Update T
Set ProgramName=B.description
From '+@Source+'.dbo.program B 
JOIN '+@Destination+'.dbo.TVProgram T ON T.LegacyTVProgramID=B.Program 
Where ProgramName<>B.description

INSERT INTO '+@Destination+'.dbo.TVProgram(ProgramName,TVStationID,LegacyTVProgramID )
select distinct B.description,A.TVStationID,program 
From '+@Destination+'.dbo.TVStation A 
JOIN '+@Source+'.dbo.program B ON A.StationShortName=B.station_call
LEFT JOIN '+@Destination+'.dbo.TVProgram T ON T.LegacyTVProgramID=B.Program 
Where T.TVProgramID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.tvthmhdr='+@Destination+'.dbo.Ad===--
IF EXISTS(SELECT name FROM tempdb.dbo.sysobjects WHERE name = N''MaxAdId'' AND xtype=''U'')
	Drop Table tempdb.dbo.MaxAdId

select max(adid) MaxAdId Into tempdb.dbo.MaxAdId from '+@Destination+'.dbo.Ad

--Make sure no duplicates exist
select theme,count(1) From '+@Source+'.dbo.tvthmhdr T 
Group by theme
having count(1)>1

--Update existing record
Update A
Set Description=ISNULL(ISNULL(M.description,T.description),A.description)
--,ProductId=ISNULL(RP.RefProductID,A.ProductID),AdvertiserID=ISNULL(RP.AdvertiserID,A.AdvertiserID)
,AdLength=ISNULL(T.length,A.AdLength),CreateDate=ISNULL(T.creation_date,A.CreateDate),BreakDt=ISNULL(T.tape_date,A.BreakDt)
--,LegacyRefProductID=ISNULL(R.Brand,A.LegacyRefProductID)
,FirstRunDate=ISNULL(T.tape_date,A.FirstRunDate)
,LastRunDate=ISNULL(T.tape_date,A.LastRunDate)
From '+@Source+'.dbo.tvthmhdr T 
JOIN '+@Destination+'.dbo.Ad A ON A.LegacyAdID=T.theme+''TV''  AND A.AdType=''19''
--LEFT JOIN '+@Source+'.dbo.tvthmbrd R ON T.theme=R.theme
--LEFT JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=R.brand--Brand
LEFT JOIN '+@Source+'.dbo.bcrdatamst M ON M.theme=T.theme AND SUBSTRING(refid,3,1) IN (''T'')
Where isnumeric(length)=1 and length not like ''%.%''



Insert Into '+@Destination+'.dbo.Ad(LegacyAdID,Description
--,ProductId,AdvertiserID
--,LegacyRefProductID
,AdLength,BreakDt,AdType,  Unclassified ,CreatedBy,Campaign,CreateDate,FirstRunDate,LastRunDate)
Select Distinct T.theme+''TV'' as LegacyAdID,ISNULL(M.description,T.description) as Description
--,RP.RefProductID as ProductId,RP.AdvertiserID
--,R.Brand
,T.length,T.tape_date,''19'' as AdType, 0 as Unclassified ,1046 as CreatedBy,M.RefId,getdate() as CreateDate,T.tape_date as FirstRunDate,T.tape_date as LastRunDate
--Into tempdb.dbo.Test33
From '+@Source+'.dbo.tvthmhdr T 
--LEFT JOIN '+@Source+'.dbo.tvthmbrd R ON T.theme=R.theme
--LEFT JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=R.brand--Brand
LEFT JOIN '+@Destination+'.dbo.Ad A ON A.LegacyAdID=T.theme+''TV'' --AND A.AdType=''19''
LEFT JOIN '+@Source+'.dbo.bcrdatamst M ON M.theme=T.theme AND SUBSTRING(refid,3,1) IN (''T'')
Where isnumeric(length)=1 and length not like ''%.%''
 AND A.AdID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--Make sure no duplicates exist
Select LegacyAdID,count(1) 
From Ad where LegacyAdID IS NOT NULL
group by LegacyAdID
having count(1) >1'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
Insert Into '+@Destination+'.dbo.AdProduct(AdID,ProductId,PrimaryInd,CreatedBy)
Select Distinct Ad.AdID,RP.RefProductID ,CASE WHEN T.seq=0 then 1 ELSE 0 END as PrimaryInd,1046 as CreatedBy
From '+@Destination+'.dbo.Ad  
JOIN '+@Source+'.dbo.tvthmbrd T  ON Ad.LegacyAdID=T.theme+''TV'' AND Ad.AdType=''19''
JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=T.brand
LEFT JOIN '+@Destination+'.dbo.AdProduct AP ON Ad.AdID=AP.AdID AND RP.RefProductID=AP.ProductID
Where AP.AdID IS NULL'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
INSERT INTO '+@Destination+'.dbo.Creative(AdId,PrimaryIndicator)
Select Ad.AdID , 1 AS PrimaryIndicator
From '+@Destination+'.dbo.Ad
LEFT JOIN '+@Destination+'.dbo.Creative ON Ad.AdID=Creative.AdId
Where Creative.AdId IS NULL AND LegacyAdID IS NOT NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


set @SQL='
--Insert record into Creative Detail --(Change -1)
INSERT into '+@Destination+'.dbo.[CreativeDetailTV] (CreativeMasterId,
	CreativeAssetname, CreativeRepository, CreativeFileType)
select distinct
Creative.PK_Id  CreativeMasterID, 
Ad.LegacyAdID  + ''.tbd'' CreativeAssetName,
''archive\tv_weekly\'' + right(left(Ad.LegacyAdID, 10), 6) + ''\''  CreativeRepository , -- file path (eg PUB\23\Original\ so archive\print\)
''tbd'' CreativeFileType --jpg --Running query to correct to mpg
from '+@Destination+'.dbo.AD
inner join '+@Destination+'.dbo.[Creative] on Creative.AdId = Ad.AdId
where ad.LegacyAdID is not null
and Creative.PK_Id not in (select CreativeMasterID from [CreativeDetailTV])
and  (
legacyAdid like ''_-T-2017%''
)'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Destination+'.dbo.Ad='+@Destination+'.dbo.Pattern===--
Insert Into '+@Destination+'.dbo.Pattern(AdId ,[Status],CreativeSignature,FormatCode,SalesStartDT,QueryCategory,LegacyRefProductID,LegacyPubCode,LegacyAdID,MediaStream,CreativeID, CreateBy)
Select Distinct A.AdID,''Valid'' as [Status],A.LegacyAdID as CreativeSignature,AdLength,BreakDt,MarketID,A.LegacyRefProductID,A.LegacyPubCode,A.LegacyAdID, 76 as MediaStream,C.PK_Id,1046 as CreateBy
From '+@Destination+'.dbo.Ad A
JOIN '+@Destination+'.dbo.Creative C ON A.AdId=C.AdId 
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
WHERE B.AdID IS NULL AND A.AdTYpe=''19''
AND A.AdId>(select MaxAdId From tempdb.dbo.MaxAdId)


--Make sure below query returns 0 - Records exist in Ad but not in Pattern
Select count(1)
From '+@Destination+'.dbo.Ad A
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.LegacyAdID IS NOT NULL 
AND B.AdID IS NULL

--Make sure below query returns 0 - Records exist in Pattern but not in Ad
Select count(1)
From '+@Destination+'.dbo.Ad A
RIGHT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.AdID IS NULL  AND B.LegacyAdID IS NOT NULL

'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

set @SQL=
'
--================================Update the Creative with the Source from OND Occurrence table==============================--
begin tran
Update '+@Destination+'.dbo.[Creative] set SourceOccurrenceId= OccurrenceDetailTVID
from '+@Destination+'.dbo.[Creative] 
INNER JOIN '+@Destination+'.dbo.[OccurrenceDetailTV] ON [OccurrenceDetailTV].AdId=[Creative].AdId
inner join '+@Destination+'.dbo.Ad on Ad.AdId = Creative.AdId
where   (AD.legacyAdid like ''_-T-2017%'')

commit'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)



SET @SQL=
'
Update '+@Destination+'.DBO.[Creative] set SourceOccurrenceId= OccurrenceDetailTVID
from '+@Destination+'.[dbo].[Creative] 
INNER JOIN '+@Destination+'.[dbo].[Pattern] ON  [dbo].[Creative].PK_Id=[dbo].[Pattern].CreativeID
INNER JOIN '+@Destination+'.[dbo].[OccurrenceDetailTV] ON dbo.[OccurrenceDetailTV].[PatternID]=[Pattern].[PatternID]
where  SourceOccurrenceId is null'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL=' 	
--(Change-4) Also find comment below
	--===Update PrimaryOccurrenceID===--
Update Ad set PrimaryOccurrenceID = SourceOccurrenceId
FROM  '+@Destination+'.[dbo].[CreativeDetailTV] 
INNER JOIN '+@Destination+'.[dbo].[Creative] ON [dbo].[CreativeDetailTV].CreativeMasterID =[dbo].[Creative].PK_Id
INNER JOIN '+@Destination+'.[dbo].[OccurrenceDetailTV] ON dbo.[OccurrenceDetailTV].OccurrenceDetailTVID=[Creative].SourceOccurrenceId
INNER JOIN '+@Destination+'.[dbo].ad ON [dbo].[OccurrenceDetailTV].[AdID]=[dbo].[AD].[AdID]
where SourceOccurrenceId is not null
and PrimaryOccurrenceID is null
	'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)



SET @SQL='
--(Change-5)
--Check for file types
DECLARE my_cursor CURSOR
FOR
select  CreativeDetailTVId ID, ''\\192.168.3.126\Canada_Assets\CreativeAssets\'' + CreativeRepository + replace(CreativeAssetName, ''.tbd'', ''.mpg'') as Path 
from '+@Destination+'.[dbo].[CreativeDetailTV]
where CreativeRepository like ''%archive%''
and CreativeFileType = ''tbd''
OPEN my_cursor
	--declare vars
	declare @Id varchar(50)
	declare @Path as varchar(500)
declare @fileexist as int
	FETCH NEXT FROM my_cursor INTO @Id, @Path
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN	
			
			--EXECUTE code
			exec master.dbo.xp_fileexist @Path, @fileexist output
			if @fileexist=1
			begin
				Update '+@Destination+'.[dbo].[CreativeDetailTV] set CreativeFileType=''mpg'', CreativeAssetName = Replace(CreativeAssetName, ''.tbd'', ''.mpg'') where CreativeDetailTVId = @Id
			end
		END
		FETCH NEXT FROM my_cursor INTO @Id, @Path
	END
CLOSE my_cursor
DEALLOCATE my_cursor

'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)



SET @sql='
/* ===========MULTI-MEDIA INJECTION============= */
----RadioStation-----
--==='+@Source+'.dbo.station='+@Destination+'.dbo.RadioStation===--

--Make sure no duplicates exist
select station,count(1) From '+@Source+'.dbo.station  
 Where stat_type in (''R'')
 Group by station
having count(1)>1 

INSERT INTO '+@Destination+'.dbo.RadioStation(RCSStationID,LegacyStationID,StationName,CreatedDT,CreatedByID,Dma)
Select 0 as RCSStationID,station as LegacyStationID,call as StationName,getdate() as CreatedDT,1046 as CreatedByID, 0 as Dma
From '+@Source+'.dbo.station A 
JOIN '+@Source+'.dbo.market B ON A.market=B.market
LEFT JOIN '+@Destination+'.dbo.RadioStation C ON A.station=C.LegacyStationID
Where stat_type in (''R'') AND C.StationName IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL=' 
--==='+@Source+'.dbo.bcrdatamst='+@Destination+'.dbo.Ad===--

--Make sure no duplicates exist
select refid,count(1) 
From '+@Source+'.dbo.bcrdatamst
group by refid
having count(1) >1


IF EXISTS (SELECT * FROM '+@Source+'.sys.indexes WHERE name = N''IDXBrand_Brand'')
	DROp INDEX [IDXBrand_Brand] ON '+@Source+'.[dbo].[brand]

CREATE NONCLUSTERED INDEX [IDXBrand_Brand] ON '+@Source+'.[dbo].[brand] ([brand]) INCLUDE ([corp],[comp])

'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL=' 
IF NOT EXISTS(select 1 from '+@Source+'.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=''bcrdatabrd'' and COLUMN_NAME=''AdType'')
	Alter Table '+@Source+'.dbo.bcrdatabrd Add AdType SmallInt

Update '+@Source+'.dbo.bcrdatabrd 
Set AdType=
CASE 
	WHEN SUBSTRING(refid,3,1)=''R'' then 15
	WHEN SUBSTRING(refid,3,1)=''W'' then 20
	WHEN SUBSTRING(refid,3,1)=''M'' then 14
	WHEN SUBSTRING(refid,3,1)=''P'' then 14
	WHEN SUBSTRING(refid,3,1)=''T'' then 19
Else 0
End
IF NOT EXISTS(select 1 from '+@Source+'.INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=''bcrdatabrd'' and COLUMN_NAME=''RowNum'')
	Alter Table '+@Source+'.dbo.bcrdatabrd Add RowNum Int

;with
CTE
as
(
Select *,ROW_NUMBER() over(PARTITION by refId Order by brand ) as Rn From  '+@Source+'.dbo.bcrdatabrd 
)--select * 
Update CTE set RowNum=Rn


IF EXISTS (SELECT * FROM '+@Source+'.sys.indexes WHERE name = N''IDX_bcrdatabrdRownum'')
	DROp INDEX [IDX_bcrdatabrdRownum] ON '+@Source+'.[dbo].[bcrdatabrd]

CREATE NONCLUSTERED INDEX [IDX_bcrdatabrdRownum] ON '+@Source+'.[dbo].[bcrdatabrd] ([RowNum]) INCLUDE ([refid],[brand],[AdType])
'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL=' 
Insert Into '+@Destination+'.dbo.Ad(LegacyAdID,BreakDt,Description,AddlInfo,AdLength,LanguageID,AdType, Unclassified
--,LegacyRefProductId 
, CreatedBy,CreateDate,FirstRunDate,LastRunDate)--,AdvertiserID,ProductId)
select Distinct m.refid,m.tape_date,m.description,fr_description,total_length,L.LanguageID,b.AdType as AdType, 0 as Unclassified
--,x.brand
,1046 as CreatedBy,getdate() as CreateDate,tape_date as FirstRunDate,tape_date as LastRunDate --,ISNULL(AA.AdvertiserId,A.AdvertiserID) as AdvertiserID,RefProductID
From '+@Source+'.dbo.bcrdatamst m
JOIN '+@Source+'.[dbo].bcrdatabrd b on m.refid = b.refid
JOIN '+@Source+'.[dbo].brand x on b.brand = x.brand
--JOIN '+@Destination+'.dbo.RefProduct P ON P.LegacyRefProductID=x.brand
--LEFT JOIN '+@Destination+'.dbo.Advertiser AA on AA.LegacyAdvertiserID2=x.comp
--LEFT JOIN '+@Destination+'.dbo.Advertiser A on A.LegacyAdvertiserID=x.corp
LEFT JOIN '+@Destination+'.dbo.Language L ON Left(L.Description,1)=m.Language AND L.Description<>''English/French''
LEFT JOIN '+@Destination+'.dbo.Ad ON Ad.LegacyAdID=m.refid  AND Ad.AdType=cast(b.AdType as varchar)
Where  isnumeric(total_length)=1 and total_length not like ''%.%''
AND Ad.AdID IS NULL --AND ISNULL(AA.AdvertiserId,A.AdvertiserID) IS NOT NULL
AND b.AdType<>''14''--To prevent pushing records for Print'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--Make sure no duplicates exist
Select LegacyAdID,count(1) 
From Ad where LegacyAdID IS NOT NULL
group by LegacyAdID
having count(1) >1'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
Insert Into '+@Destination+'.dbo.AdProduct(AdID,ProductId,PrimaryInd,CreatedBy)
Select Distinct Ad.AdID,RP.RefProductID ,CASE WHEN b.RowNum=1 then 1 ELSE 0 END as PrimaryInd,1046 as CreatedBy
From '+@Destination+'.dbo.Ad  
JOIN '+@Source+'.dbo.bcrdatabrd b ON Ad.LegacyAdID=b.refID
JOIN '+@Destination+'.dbo.RefProduct RP ON RP.LegacyRefProductID=b.brand
LEFT JOIN '+@Destination+'.dbo.AdProduct AP ON Ad.AdID=AP.AdID AND RP.RefProductID=AP.ProductID
Where AP.AdID IS NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
INSERT INTO '+@Destination+'.dbo.Creative(AdId,PrimaryIndicator)
Select Ad.AdID ,1 AS PrimaryIndicator
From '+@Destination+'.dbo.Ad
LEFT JOIN '+@Destination+'.dbo.Creative ON Ad.AdID=Creative.AdId
Where Creative.AdId IS NULL AND LegacyAdID IS NOT NULL'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


SET @SQL='
--==='+@Destination+'.dbo.Ad='+@Destination+'.dbo.Pattern===--
Insert Into '+@Destination+'.dbo.Pattern(AdId ,[Status],CreativeSignature,MediaStream,CreativeID, CreateBy,LegacyAdId)
Select Distinct A.AdID,''Valid'' as [Status],A.LegacyAdID as CreativeSignature
,CASE
	WHEN A.AdType IN (''14'',''14'') then 84
	WHEN A.AdType=''15'' then 77
	WHEN A.AdType=''19'' then 76
	WHEN A.AdType=''20'' then 79
	Else 0
END as MediaStream
,C.PK_Id,1046 as CreateBy,A.LegacyAdId
From '+@Destination+'.dbo.Ad A 
JOIN '+@Destination+'.dbo.Creative C ON A.AdId=C.AdId 
JOIN '+@Source+'.dbo.bcrdatamst T  ON A.LegacyAdID=T.refid
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
WHERE B.AdID IS NULL'


IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--==='+@Source+'.dbo.bcrMedia='+@Destination+'.dbo.ScrapeSession===----As per CB-290 to populate ScrapeSession table
Insert Into '+@Destination+'.dbo.ScrapeSession(WebsiteID,ScrapeBeginDT,ScrapeEndDT,ScrapeDate,RunWeek,NodeID,MediaStream,CTLegacySeq)
Select B.WebsiteID,''00:00:00'' as ScrapeBeginDT,''00:00:00'' as ScrapeEndDT,''1/1/2017'' as ScrapeDate,1 as RunWeek,1 as NodeID,79 as MediaStream,A.code as CTLegacySeq
From '+@Source+'.dbo.bcrMedia A
LEFT JOIN '+@Destination+'.dbo.Website B ON A.code=B.LegacyMediaCode
LEFT JOIN '+@Destination+'.dbo.ScrapeSession C ON A.Code=C.CTLegacySeq
Where A.type = ''W'' AND C.ScrapeSessionID IS NULL'


IF @IsDebug=0
	Exec(@SQL)
Else
	Print(@SQL)

SET @SQL='
--Make sure below query returns 0 - Records exist in Ad but not in Pattern
Select count(1)
From '+@Destination+'.dbo.Ad A
LEFT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.LegacyAdID IS NOT NULL 
AND B.AdID IS NULL

--Make sure below query returns 0 - Records exist in Pattern but not in Ad
Select count(1)
From '+@Destination+'.dbo.Ad A
RIGHT JOIN '+@Destination+'.dbo.Pattern B ON A.AdId=B.AdID
Where A.AdID IS NULL  AND B.LegacyAdID IS NOT NULL
'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

Set @SQL='--**************************************************TV*****************************************--
--Insert record into Creative Detail --(Change -1)
INSERT into '+@Destination+'.dbo.[CreativeDetailTV] (CreativeMasterId,
	CreativeAssetname, CreativeRepository, CreativeFileType)
select distinct
Creative.PK_Id  CreativeMasterID, 
Ad.LegacyAdID  + ''.tbd'' CreativeAssetName,
''archive\tv_weekly\'' + right(left(Ad.LegacyAdID, 10), 6) + ''\''  CreativeRepository , -- file path (eg PUB\23\Original\ so archive\print\)
''tbd'' CreativeFileType --jpg --Running query to correct to mpg
from '+@Destination+'.dbo.AD
inner join '+@Destination+'.dbo.[Creative] on Creative.AdId = Ad.AdId
where ad.LegacyAdID is not null
and Creative.PK_Id not in (select CreativeMasterID from [CreativeDetailTV])
and  (
legacyAdid like ''_-T-2017%''
)'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
--(Change-5)
--Check for file types
DECLARE my_cursor CURSOR
FOR
select CreativeDetailTVId ID, ''\\192.168.3.126\Canada_Assets\CreativeAssets\'' + CreativeRepository + replace(CreativeAssetName, ''.tbd'', ''.mpg'') as Path 
from '+@Destination+'.[dbo].[CreativeDetailTV]
where CreativeRepository like ''%archive%''
and CreativeFileType = ''tbd''
OPEN my_cursor
	--declare vars
	declare @Id varchar(50)
	declare @Path as varchar(500)
declare @fileexist as int
	FETCH NEXT FROM my_cursor INTO @Id, @Path
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN	
			
			--EXECUTE code
			exec master.dbo.xp_fileexist @Path, @fileexist output
			if @fileexist=1
			begin
				Update '+@Destination+'.[dbo].[CreativeDetailTV] set CreativeFileType=''mpg'', CreativeAssetName = Replace(CreativeAssetName, ''.tbd'', ''.mpg'') where CreativeDetailTVId = @Id
			end
		END
		FETCH NEXT FROM my_cursor INTO @Id, @Path
	END
CLOSE my_cursor
DEALLOCATE my_cursor

'
IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

SET @SQL='
/*
--Query to identify AdType\MediaStream values
 select valuetitle,mediastream,adtype,count(1) 
 from pattern a 
 join [configuration] b ON a.mediastream=b.configurationid 
 join ad c on a.adid=c.adid
 group by valuetitle,mediastream,adtype
 */
 --======================Dummy occurrences======================--
--TV
Insert Into '+ @Destination +'.dbo.OccurrenceDetailTV(PatternID,AdId,TVRecordingScheduleID,PRCODE,AirDT,AirTime,CreatedDT,FakePatternCODE,StationID,CaptureDT,AdLength)
Select Distinct A.PatternID,A.AdId,0 as TVRecordingScheduleID,ISNULL(m.refid,Ad.LegacyAdID) as PRCODE,ISNULL(m.tape_date + m.tape_time,'''') as AirDT,ISNULL(tape_time,'''') AirTime,getdate() as CreatedDT,1 as FakePatternCODE,TVStationID,m.tape_date + m.tape_time as CaptureDT,ISNULL(total_length,0) as AdLength --1 as FakePatternCODE to identity dummy occ
From '+ @Destination +'.dbo.Pattern A
JOIN '+ @Destination +'.dbo.Ad On A.AdId=Ad.AdId
LEFT JOIN '+ @Destination +'.dbo.OccurrenceDetailTV B ON A.AdId=B.AdId
LEFT JOIN '+ @Source +'.dbo.bcrdatamst m ON m.refid=A.LegacyAdId 
LEFT JOIN '+ @Destination +'.dbo.TVStation T ON T.LegacyStation=m.station
Where B.AdId IS NULL --Records not existing in OccurrenceDetailTV
AND A.MediaStream=76 --For TV
AND A.LegacyAdID IS NOT NULL--Nielsen data only

--Update PrimaryOccurrenceID
Update Ad Set PrimaryOccurrenceID = MinOcc
	from '+ @Destination +'.dbo.Ad 
	inner join (
	Select adId, min (OccurrenceDetailTVId) MinOcc
	from '+ @Destination +'.dbo.OccurrenceDetailTV
	group by adId) as s1 on Ad.AdId = s1.AdId 
	where PrimaryOccurrenceID is null
	and AdType = ''19''
	
--RA

Insert Into '+ @Destination +'.dbo.OccurrenceDetailRA(PatternID,AdID,RCSAcIdID,AirDT,RCSStationID,RCSSequenceID,AirStartDT,AirEndDT,Deleted,CreatedDT,CreatedByID,NoTakeReasonID,RadioStationID)
Select Distinct A.PatternID,A.AdID,0 RCSAcIdID,m.tape_date + m.tape_time as AirDT,0 RCSStationID,0 RCSSequenceID,m.tape_date + m.tape_time as AirStartDT,'''' AirEndDT,0 Deleted,getdate() CreatedDT,1046 CreatedByID,1 NoTakeReasonID,T.RadioStationID as StationID--1 as NoTakeReasonID to identity dummy occ
From '+ @Destination +'.dbo.Pattern A
JOIN '+ @Destination +'.dbo.Ad On A.AdId=Ad.AdId
LEFT JOIN '+ @Destination +'.dbo.OccurrenceDetailRA B ON A.AdId=B.AdId
LEFT JOIN '+ @Source +'.dbo.bcrdatamst m ON m.refid=A.LegacyAdId 
LEFT JOIN '+ @Destination +'.dbo.RadioStation T ON T.LegacyStationID=m.station
Where B.AdId IS NULL --Records not existing in OccurrenceDetailRA
AND A.MediaStream=77 --For RA
AND A.LegacyAdID IS NOT NULL--Nielsen data only

--Update PrimaryOccurrenceID
Update Ad Set PrimaryOccurrenceID = MinOcc
	from '+ @Destination +'.dbo.Ad 
	inner join (
	Select adId, min (OccurrenceDetailRAId) MinOcc
	from '+ @Destination +'.dbo.OccurrenceDetailRA 
	group by adId) as s1 on Ad.AdId = s1.AdId 
	where PrimaryOccurrenceID is null
	and AdType = ''15''

--OND
Insert Into '+ @Destination +'.dbo.OccurrenceDetailOND(PatternID,ScrapeSessionID,ScrapePageID,AdID,ResultID,OccurrenceDT,CreatedDT,CreativeSignature,NoTakeReasonID,LegacyWebsiteID)
Select Distinct A.PatternID,S.ScrapeSessionID,2 ScrapePageID,A.AdID,0 ResultID,tape_date as OccurrenceDT,getdate() CreatedDT,m.refid as CreativeSignature,1 NoTakeReasonID,m.station--1 as NoTakeReasonID to identity dummy occ
From '+ @Destination +'.dbo.Pattern A
JOIN '+ @Destination +'.dbo.Ad On A.AdId=Ad.AdId
LEFT JOIN '+ @Destination +'.dbo.OccurrenceDetailOND B ON A.AdId=B.AdId
LEFT JOIN '+ @Source +'.dbo.bcrdatamst m ON m.refid=A.LegacyAdId 
LEFT JOIN '+ @Destination +'.dbo.RadioStation T ON T.LegacyStationID=m.station
LEFT JOIN '+ @Destination +'.dbo.Website W ON W.LegacyMediaCode=m.station--As per CB-291 to populate ScrapeSessionID,Earlier ScrapeSessionID was 20567608 as default
LEFT JOIN '+ @Destination +'.dbo.ScrapeSession S ON S.WebsiteID=W.WebsiteID--As per CB-291 to populate ScrapeSessionID,Earlier ScrapeSessionID was 20567608 as default
Where B.AdId IS NULL --Records not existing in OccurrenceDetailOND
AND A.MediaStream=79 --For OND
AND A.LegacyAdID IS NOT NULL--Nielsen data only

--Update PrimaryOccurrenceID
Update Ad Set PrimaryOccurrenceID = MinOcc
	from '+ @Destination +'.dbo.Ad 
	inner join (
	Select adId, min (OccurrenceDetailONDId) MinOcc
	from '+ @Destination +'.dbo.OccurrenceDetailOND
	group by adId) as s1 on Ad.AdId = s1.AdId 
	where PrimaryOccurrenceID is null
	and AdType = ''20''
'

IF @IsDebug=0
	Exec(@SQL)
Else
	Print(@SQL)

	Set @SQL='
Insert Into CanadaOneMT.[dbo].[CreativeDetailOND](CreativeMasterID,CreativeAssetName,CreativeRepository, LegacyAssetName, CreativeFileType)
Select Distinct
PK_Id CreativeMasterID, 
Ad.LegacyAdID + ''.tbd'' as CreativeAssetName,
concat(''archive\online_weekly\'',LEFT(replace(CreativeAssetName,''D-W-'',''''),CHARINDEX(''-'',replace(CreativeAssetName,''D-W-'',''''))-1),''\'')  CreativeRepository, -- file path (eg PUB\23\Original\ so archive\print\)
Ad.LegacyAdID LegacyAssetName, --not needed by use same as file name
''tbd'' CreativeFileType --jpg
FROM CREATIVE C with(nolock)
inner join ad  with(nolock) on ad.adid=c.adid
LEFT JOIN CREATIVEDETAILOND CD with(nolock) ON C.PK_ID=CD.CREATIVEMASTERID
Where LegacyAdID is not NULL and adtype=20 and cd.creativemasterid is null


--Check for mpg file types
DECLARE my_cursor CURSOR
FOR
select  CreativeDetailONDID ID, ''\\192.168.3.126\Canada_Assets\CreativeAssets\'' + CreativeRepository + replace(CreativeAssetName, ''.tbd'', ''.mpg'') as Path 
from CanadaOneMT.[dbo].[CreativeDetailOND]
where CreativeRepository like ''%archive%''
and CreativeFileType = ''tbd''
OPEN my_cursor
	--declare vars
	declare @Id varchar(50)
	declare @Path as varchar(500)
declare @fileexist as int
	FETCH NEXT FROM my_cursor INTO @Id, @Path
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN	
			
			--EXECUTE code
			exec master.dbo.xp_fileexist @Path, @fileexist output
			if @fileexist=1
			begin
				Update CanadaOneMT.[dbo].[CreativeDetailOND] set CreativeFileType=''mpg'', CreativeAssetName = Replace(CreativeAssetName, ''.tbd'', ''.mpg'') where CreativeDetailONDID = @Id
			end
		END
		FETCH NEXT FROM my_cursor INTO @Id, @Path
	END
CLOSE my_cursor
DEALLOCATE my_cursor

Go

--Check for jpg file types
DECLARE my_cursor CURSOR
FOR
select  CreativeDetailONDID ID, ''\\192.168.3.126\Canada_Assets\CreativeAssets\'' + CreativeRepository + replace(CreativeAssetName, ''.tbd'', ''.jpg'') as Path 
from CanadaOneMT.[dbo].[CreativeDetailOND]
where CreativeRepository like ''%archive%''
and CreativeFileType = ''tbd''
OPEN my_cursor
	--declare vars
	declare @Id varchar(50)
	declare @Path as varchar(500)
declare @fileexist as int
	FETCH NEXT FROM my_cursor INTO @Id, @Path
	WHILE (@@FETCH_STATUS <> -1)
	BEGIN
		IF (@@FETCH_STATUS <> -2)
		BEGIN	
			
			--EXECUTE code
			exec master.dbo.xp_fileexist @Path, @fileexist output
			if @fileexist=1
			begin
				Update CanadaOneMT.[dbo].[CreativeDetailOND] set CreativeFileType=''jpg'', CreativeAssetName = Replace(CreativeAssetName, ''.tbd'', ''.jpg'') where CreativeDetailONDID = @Id
			end
		END
		FETCH NEXT FROM my_cursor INTO @Id, @Path
	END
CLOSE my_cursor
DEALLOCATE my_cursor'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)


Set @SQL='
--From Lucy, Ticket CB-268
Use '+ @Destination +'
Go
--Below should return 0 - Check whether there are any records without occurrence, If yes - check MediaType and see why no Occurrence in corresponding Occ table
Select count(1)
From Ad a with(nolock)
where not exists(select 1 from occurrencedetailtv o1 with(nolock) where a.adid = o1.adid)
and not exists(select 1 from occurrencedetailra o2 with(nolock) where a.adid = o2.adid)
and not exists(select 1 from occurrencedetailpub o3 with(nolock) where a.adid = o3.adid)
and not exists(select 1 from OccurrenceDetailOND o4 with(nolock) where a.adid = o4.adid)
and not exists(select 1 from pattern p1 with(nolock) join occurrencedetailtv o5 with(nolock) on p1.patternid = o5.patternID where p1.adid = a.adid)
and not exists(select 1 from pattern p2 with(nolock) join OccurrenceDetailRA o6 with(nolock) on p2.patternid = o6.patternID where p2.adid = a.adid)
and not exists(select 1 from pattern p3 with(nolock) join occurrencedetailpub o7 with(nolock) on p3.patternid = o7.patternID where p3.adid = a.adid)
and not exists(select 1 from pattern p4 with(nolock) join OccurrenceDetailOND o8 with(nolock) on p4.patternid = o8.patternID where p4.adid = a.adid)
and LegacyAdID is not null

--From below check whether any orphan record exist in Occ table(no corresponding record in ad table)
--Below should return 0 - Radio Occurrence with no corresponding ad
Select count(1)
From OccurrenceDetailRA o 
where not exists(select 1 from Ad a where o.adid = a.adid) 
and o.MapType is null 
and o.adid is not null

--Below should return 0 - Online Occurrence with no corresponding ad
Select count(1)
From OccurrenceDetailOND o with(nolock) 
where not exists(select 1 from Ad a with(nolock)  where o.adid = a.adid)  
and o.MapType is null
and o.adid is not null

--Below should return 0 - TV Occurrence with no corresponding ad
Select count(1)
From OccurrenceDetailTV o with(nolock) 
where not exists(select 1 from Ad a with(nolock)  where o.adid = a.adid) 
and o.MapType is null 
and o.adid is not null 
and o.InputFileName is null

--Below should return 0 - Print Occurrence with no corresponding ad
Select count(1)
From OccurrenceDetailPub o with(nolock) 
where not exists(select 1 from Ad a with(nolock)  where o.adid = a.adid)  
and o.MapType is null
and o.adid is not null

--================Below counts should Match per Media =============--
--'+ @Source +'
Select CASE WHEN media= ''R'' THEN ''Radio'' WHEN media= ''T'' THEN ''Television'' WHEN media= ''W'' THEN ''Online Display'' END as media,count(*)
From '+ @Source +'.dbo.bcrdatamst 
where media in (''T'',''W'',''R'')
Group by media
order by 1

--'+ @Destination +'
Select m.descrip as Media,adtype, count(*)
From '+ @Destination +'.dbo.Ad a
join '+ @Destination +'.dbo.MediaType m on a.adtype = m.mediatypeid
where a.LegacyAdID like ''%-%''
Group by m.descrip,adtype
order by 1

--================One-to-One mapping should exist in below(4 records only)======================--
select valuetitle,mediastream,adtype,count(1) 
 from '+ @Destination +'.dbo.pattern a with(nolock) 
 join '+ @Destination +'.dbo.[configuration] b with(nolock) ON a.mediastream=b.configurationid 
 join '+ @Destination +'.dbo.ad c with(nolock)on a.adid=c.adid
 where a.legacyadid is not null
 group by valuetitle,mediastream,adtype
 order by adtype'

IF @IsDebug=0
Exec(@SQL)
Else
Print(@SQL)

End



GO


