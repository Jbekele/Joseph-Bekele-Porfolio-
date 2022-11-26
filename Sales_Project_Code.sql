--Inspecting Data
SELECT*
FROM dbo.sales_data_sample 

--Checking Unique Values
Select distinct status from [dbo].[sales_data_sample] --PLOT
Select distinct year_id from [dbo].[sales_data_sample]
Select distinct productline from [dbo].[sales_data_sample] --PLOT
Select distinct country from [dbo].[sales_data_sample] -- PLOT 
Select distinct dealsize from [dbo].[sales_data_sample] --PLOT 
Select distinct territory from [dbo].[sales_data_sample] --PlOT 

Select distinct month_id from [dbo].[sales_data_sample]
WHERE year_id = 2003

--Analysis 
--Grouping Sales by ProductLine 
Select Productline, SUM(sales) Revenue 
FROM [dbo].[sales_data_sample]
Group by PRODUCTLINE 
ORDER by 2 DESC 

Select year_id, SUM(sales) Revenue 
FROM [dbo].[sales_data_sample]
Group by year_id   
ORDER by 2 DESC 

Select dealsize, SUM(sales) Revenue 
FROM [dbo].[sales_data_sample]
Group by dealsize  
ORDER by 2 DESC

--Best Month each year (sales) Earned?

 Select MONTH_Id, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency 
FROM [dbo].[sales_data_sample]
Where Year_id = 2004
Group by MONTH_ID  
ORDER by 2 DESC

--November = Best Month (Sales)

Select MONTH_Id, PRODUCTLINE, SUM(sales) Revenue, COUNT(ORDERNUMBER) Frequency 
FROM [dbo].[sales_data_sample]
Where Year_id = 2004 AND Month_id = 11 
Group by MONTH_ID , PRODUCTLINE  
ORDER by 3 DESC

--BEST CUSTOMER (RFM)
 
 DROP TABLE IF EXISTS #rfm
 ;with rfm as 
 (
        SELECT
            CUSTOMERNAME,
            SUM(SALES) MonetaryValue,
            Avg(SALES) AvgMonetaryValue,
            COUNT(ORDERNUMBER) Frequency,
            MAX(ORDERDATE) last_order_date,
            (SELECT max(orderdate) FROM [dbo].[sales_data_sample]) Max_Order_Date,
            DATEDIFF(DD, max(Orderdate), (SELECT max(orderdate) from [dbo].[sales_data_sample])) Recency
        from [dbo].[sales_data_sample]
        GROUP BY CUSTOMERNAME
 ),
 rfm_calc as 
 (
     SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency desc) rfm_recency,
        NTILE(4) OVER (ORDER BY frequency) rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
    FRom rfm r       
 )
 SELECT
    c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
    cast (rfm_recency as varchar) +  CAST (rfm_frequency as varchar) + CAST (rfm_monetary as varchar) rfm_cell_string 
into #rfm
from rfm_calc c 
 
Select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
case 
	when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
	when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
	when rfm_cell_string in (311, 411, 331) then 'new customers'
	when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
    when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
	when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm 

--What Products are most sold together?
--Select * FRom [dbo].[sales_data_sample] Where ORDERNUMBER = 10411
    
   select distinct ordernumber, stuff(
    
    (SELECT ',' + productcode 
    From [dbo].[sales_data_sample] p 
    Where ordernumber in 
    (

    Select Ordernumber
    FRom(
        SELECT ORDERNUMBER, count(*) rn 
        from [dbo].[sales_data_sample]
        where STATUS = 'Shipped' 
        GROUP by ORDERNUMBER 
    )m
    WHERE rn = 2
    )
    AND p.ordernumber = s.ordernumber
    for xml path (''))
    
    ,1,1, '') ProductCodes 
FROM [dbo].[sales_data_sample] s
ORDER by 2 desc 
