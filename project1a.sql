-- testing database

select *
from customer
limit 5;

select *
from product
limit 5; 

select *
from transaction
limit 5;

-- drop view and rename
Drop view productcategoryperformance, producttypeperformance, profitabilityimpact, salespotential, vw_deviceperformance;
Drop view customersegment;
--  Analysis of effect  of 15% on a profit magin of a business
 
-- Profitability Impact on Monthly Basis

create view Profitability_Impact as
select 
date_format(t.transactiontimestamp, '%Y-%m') as MonthlySales,
count(*) as TotalTransaction,
avg(((p.UnitPrice - t.Discount) - p.costprice)*t.quantity) as AvgTransactionMargin,
sum(((p.UnitPrice - t.Discount) - p.costprice)*t.quantity) as TotalTransactionMargin
from transaction t
join product p
on t.ProductPurchased = p.ProductID
where date_format(t.transactiontimestamp, '%Y-%m') in ('2024-11','2024-12','2025-01')
group by date_format(t.transactiontimestamp, '%Y-%m')
order by MonthlySales;

-- January has the lowest total transaction but with the hihest profit margin thi willhave been influenced by product.alter

-- Prodcut Category performance

create view Product_Type_Performance as
select 
date_format(t.transactiontimestamp, '%Y-%m') as MonthlySales,
p.Category as ProductType,
count(*) as TotalTransaction,
avg(((p.UnitPrice -t.Discount)-p.costprice)*t.quantity) as AvgTransactionMargin,
sum(((p.UnitPrice -t.Discount)-p.costprice)*t.quantity) as TotalTransactionMargin
from transaction t
join product p
on t.ProductPurchased = p.ProductID
where date_format(t.transactiontimestamp, '%Y-%m') in ('2024-11','2024-12','2025-01')
group by MonthlySales, ProductType
order by MonthlySales, ProductType;

-- sales Cannibalization Potential

create view Sales_Potential as
with CustomerActivity as 
(
select 
c.CustomerID,
c.Name,
date_format(t.transactiontimestamp, '%Y-%m') as MonthlySales,
count(t.TransactionID) as TotalTransaction
from transaction t
Join customer c
on t.CustomerID = c.CustomerID
where date_format(t.transactiontimestamp, '%Y-%m') in ('2024-11','2024-12','2025-01')
group by c.CustomerID, c.Name, MonthlySales
)
select 
ca.customerID, ca.name,
max(case when ca.MonthlySales in ("2024-11","2024-12") then ca.TotalTransaction else 0 end) as Prev_Transaction,
max(case when ca.MonthlySales = "2025-01" then ca.TotalTransaction else 0 end) as Jan_Transaction
from CustomerActivity as ca
group by ca.customerid, ca.name
order by Jan_Transaction desc;

-- customer segment Analysis

create view Customer_Segment as
select 
date_format(t.transactiontimestamp, '%Y-%m') as MonthlySales,
case when c.DateOfRegistration < date_format(t.transactiontimestamp, '%Y-%m') then "Returning Customner" else "New Customer" end as CustomerType,
count(distinct c.customerid) as NumberOfCustomer, 
count(t.TransactionID) as TotalTransaction,
sum(t.quantity) as TotalUnitsSold
from transaction t
Join customer c
on t.CustomerID = c.CustomerID
where date_format(t.transactiontimestamp, '%Y-%m') in ('2024-11','2024-12','2025-01')
group by MonthlySales, CustomerType
order by MonthlySales, CustomerType;

-- Product Category Performance(performance by product category, including total transactions,total units sold, and total revenue)

CREATE VIEW Product_Category_Performance AS 
SELECT  
p.Category, 
COUNT(t.TransactionID) AS TotalTransactions, 
SUM(t.Quantity) AS TotalUnitsSold, 
SUM((p.UnitPrice - t.Discount) * t.Quantity) AS TotalRevenue 
FROM Transaction t 
JOIN Product p ON t.ProductPurchased = p.ProductID 
GROUP BY p.Category;

-- Regional Sales Analysis( performance by region, including total transactions, units sold, and revenue.)
CREATE VIEW Regional_Sales AS 
SELECT  
t.Region, 
COUNT(t.TransactionID) AS TotalTransactions, 
SUM(t.Quantity) AS TotalUnitsSold, 
SUM((p.UnitPrice - t.Discount) * t.Quantity) AS TotalRevenue 
FROM Transaction t 
JOIN Product p ON t.ProductPurchased = p.ProductID 
GROUP BY t.Region;

 -- Abandoned Carts & Conversion Rate
 CREATE VIEW Abandoned_Carts AS 
SELECT  
COUNT(*) AS TotalCarts, 
SUM(CASE WHEN t.Abandoned = 'Yes' THEN 1 ELSE 0 END) AS AbandonedCarts, 
(SUM(CASE WHEN t.Abandoned = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS AbandonedRate 
FROM Transaction t 
WHERE t.CartStartTimestamp IS NOT NULL;

-- Device/Channel Performance
CREATE VIEW Device_Performance AS 
SELECT  
t.DeviceUsed, 
COUNT(t.TransactionID) AS TotalTransactions, 
SUM(t.Quantity) AS TotalUnitsSold 
FROM Transaction t 
GROUP BY t.DeviceUsed;

-- Delivery Performance

CREATE VIEW Delivery_Performance AS 
SELECT  
DeliveryStatus, 
COUNT(TransactionID) AS TotalDeliveries 
FROM Transaction 
GROUP BY DeliveryStatus;

-- Repeat Purchases (Customer Lifetime Value Proxy)

CREATE VIEW Repeat_Purchases AS 
SELECT  
c.CustomerID, 
c.Name, 
COUNT(t.TransactionID) AS TransactionCount 
FROM Customer c 
JOIN Transaction t ON c.CustomerID = t.CustomerID 
GROUP BY c.CustomerID, c.Name 
HAVING COUNT(t.TransactionID) > 1;