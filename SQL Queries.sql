/****** Orders by year  ******/
select year(orderdate) OrderYear
	  ,count([orderID]) TotalOrders
from [Datasets].[dbo].[nw_orders]
group by year(orderDate)

/****** Total Sales by year  ******/
select year(orderdate) Orderyear
		,sum((unitprice-(unitprice*discount))*quantity) TotalSales
FROM [Datasets].[dbo].[nw_order_details]
JOIN [Datasets].[dbo].[nw_orders] on nw_orders.orderID = nw_order_details.orderID
	group by year(orderdate)

/****** Total Sales and order count by month, year  ******/
SELECT 
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS YearMonth,
	    Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales,
		count(distinct orde.orderid) OrderCount
FROM [Datasets].[dbo].[nw_order_details] orde
JOIN [Datasets].[dbo].[nw_orders] ord ON ord.orderID = orde.orderID
JOIN [Datasets].[dbo].nw_employees emp on emp.employeeID = ord.employeeID
GROUP BY YEAR(ord.orderdate), MONTH(ord.orderdate)
order by 1,2

/****** Total Sales and order count, Total Sales%  by employee and month, year  ******/
With SalesbyEmp 
as(
SELECT 
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS YearMonth,
		emp.Employeename,
       Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales,
		count(distinct orde.orderid) OrderCount
FROM [Datasets].[dbo].[nw_order_details] orde
    JOIN [Datasets].[dbo].[nw_orders] ord ON ord.orderID = orde.orderID
	JOIN [Datasets].[dbo].nw_employees emp on emp.employeeID = ord.employeeID
	GROUP BY YEAR(ord.orderdate), MONTH(ord.orderdate),emp.employeename
	
),
TotalSales
as (
SELECT 
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS YearMonth,
		Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales,
		count(distinct orde.orderid) OrderCount
FROM [Datasets].[dbo].[nw_order_details] orde
    JOIN [Datasets].[dbo].[nw_orders] ord ON ord.orderID = orde.orderID
	JOIN [Datasets].[dbo].nw_employees emp on emp.employeeID = ord.employeeID
	GROUP BY YEAR(ord.orderdate), MONTH(ord.orderdate)
	
)
select	SalesbyEmp.YearMonth YearMonth, SalesbyEmp.employeeName, SalesbyEmp.TotalSales EmplSales, 
		SalesbyEmp.OrderCount EmplOrders, 
		TotalSales.TotalSales TotalSales,
		Round((SalesbyEmp.TotalSales/TotalSales.TotalSales)*100,2) 'TotalSales%'
from SalesbyEmp
JOIN TotalSales on SalesbyEmp.YearMonth = TotalSales.YearMonth

/****** Top 3 Employees by Sales  ******/
WITH SalesbyEmp AS (
    SELECT 
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS YearMonth,
        emp.employeename,
        Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales
    FROM [Datasets].[dbo].[nw_order_details] orde
    JOIN [Datasets].[dbo].[nw_orders] ord ON ord.orderID = orde.orderID
    JOIN [Datasets].[dbo].nw_employees emp ON emp.employeeID = ord.employeeID
    GROUP BY YEAR(ord.orderdate), MONTH(ord.orderdate), emp.employeename
),
RankedSales AS (
    SELECT
        YearMonth,
        employeename,
        TotalSales,
        RANK() OVER (PARTITION BY YearMonth ORDER BY TotalSales DESC) AS SalesRank
    FROM SalesbyEmp
)
SELECT
    YearMonth,
    employeename,
    Round(TotalSales,2) TotalSales
FROM RankedSales
WHERE SalesRank <= 3
ORDER BY YearMonth, SalesRank;


/****** Sales by Countries  ******/
select year(orderdate) Orderyear,
	   country,
	   Round(sum((unitprice-(unitprice*discount))*quantity),2) TotalSales
from [Datasets].[dbo].nw_customers cust
JOIN [Datasets].[dbo].[nw_orders] ord on cust.customerID = ord.customerID
JOIN [Datasets].[dbo].[nw_order_details] orde on ord.orderID = orde.orderID
group by country,year(orderdate) 
order by 1,2


/****** Average days to ship  ******/
select year(orderdate) OrderYear,
       AVG(cast((DATEDIFF(DAY,orderdate,shippeddate)) as decimal(10,2))) AvgDays
from [Datasets].[dbo].[nw_orders]
where shippedDate <>'1899-12-30 00:00:00.000' 
group by year(orderdate) 

/****** Average shipping cost  ******/
select DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS YearMonth,
       Round(avg(freight),2) Avgcost
from [Datasets].[dbo].[nw_orders] ord

group by YEAR(ord.orderdate), MONTH(ord.orderdate)

/****** Average shipping cost by shipping company  ******/
SELECT distinct DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1) YearMonth
	  ,shp.CompanyName
	  ,avg(distinct freight) Avgshipcost
      FROM [Datasets].[dbo].[nw_orders] ord
JOIN [Datasets].[dbo].[nw_order_details] orde on orde.orderID =ord.orderID
JOIN nw_shippers shp on shp.shipperID = ord.shipperID
group by DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1)  ,shp.companyName

/****** Total sales, order count and shipping cost by shipping company  ******/
SELECT DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1) AS YearMonth,
    CompanyName,
    SUM(DISTINCT [freight]) AS TotalShippingCost,
    COUNT(DISTINCT ord.orderid) AS OrderCount,
    SUM([freight]) / COUNT(ord.orderid) AS AverageShippingCost,
    SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity) AS TotalSales
FROM [Datasets].[dbo].[nw_orders] ord
JOIN nw_shippers ON nw_shippers.shipperID = ord.shipperID
JOIN [Datasets].[dbo].[nw_order_details] orde ON orde.orderID = ord.orderID
GROUP BY DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1), companyName

/****** Customers by year  ******/
select year(orderdate) OrderYear
	  ,count(distinct[customerID]) TotalCustomers
from [Datasets].[dbo].[nw_orders]
group by year(orderDate)

/****** Customers Total Sales, Order Count by MonthYear  ******/
select distinct DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) MonthYear
	  ,cust.CompanyName	 
	  ,count(distinct ord.orderID) OrderCount
	  , Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales
from [Datasets].[dbo].[nw_orders] ord
JOIN [Datasets].[dbo].[nw_order_details] orde ON ord.orderID = orde.orderID
JOIN [Datasets].[dbo].nw_customers cust on cust.customerID = ord.customerID
group by DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1),cust.companyName

/****** Top 3 Customers by Sales  ******/
WITH CustomerSales AS (
    SELECT
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS MonthYear,
        cust.CompanyName,
        SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity) AS TotalSales,
        RANK() OVER (PARTITION BY DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) ORDER BY SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity) DESC) AS SalesRank
    FROM [Datasets].[dbo].[nw_orders] ord
    JOIN [Datasets].[dbo].[nw_order_details] orde ON ord.orderID = orde.orderID
    JOIN [Datasets].[dbo].nw_customers cust ON cust.customerID = ord.customerID
    GROUP BY DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1), cust.companyName
)
SELECT MonthYear, companyName, TotalSales
FROM CustomerSales
WHERE SalesRank <= 3

/****** Product Total Sales, Order Count by MonthYear  ******/
select distinct DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) MonthYear
	  ,prod.ProductName	 
	  ,count(distinct ord.orderID) OrderCount
	  , Round(SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity),2) AS TotalSales
from [Datasets].[dbo].[nw_orders] ord
JOIN [Datasets].[dbo].[nw_order_details] orde ON ord.orderID = orde.orderID
JOIN [Datasets].[dbo].nw_products prod on prod.productID = orde.productID
group by DATEFROMPARTS(YEAR(orderdate), MONTH(orderdate), 1),prod.productName

/****** Top 3 Products by Sales  ******/
WITH ProductSales AS (
    SELECT
        DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) AS MonthYear,
        prod.productName,
        SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity) AS TotalSales,
        RANK() OVER (PARTITION BY DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1) ORDER BY SUM((orde.unitprice - (orde.unitprice * orde.discount)) * orde.quantity) DESC) AS SalesRank
    FROM [Datasets].[dbo].[nw_orders] ord
    JOIN [Datasets].[dbo].[nw_order_details] orde ON ord.orderID = orde.orderID
    JOIN [Datasets].[dbo].nw_products prod on prod.productID = orde.productID
    GROUP BY DATEFROMPARTS(YEAR(ord.orderdate), MONTH(ord.orderdate), 1), prod.productName
)
SELECT MonthYear, productName, TotalSales
FROM ProductSales
WHERE SalesRank <= 3




