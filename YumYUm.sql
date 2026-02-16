--Indexes
-- Orders
CREATE INDEX idx_orders_customer_id ON Orders(Customer_ID);

-- Order_Menu
CREATE INDEX idx_ordermenu_order_id ON Order_Menu(Order_ID);
CREATE INDEX idx_ordermenu_item_id ON Order_Menu(Item_ID);

-- Inventory
CREATE INDEX idx_inventory_supplier_id ON Inventory(Supplier_ID);

-- Delivery
CREATE INDEX idx_delivery_order_id ON Delivery(Order_ID);
CREATE INDEX idx_delivery_emp_id ON Delivery(Emp_ID);

-- Payment
CREATE INDEX idx_payment_order_id ON Payment(Order_ID);

-- Cash & Card
CREATE INDEX idx_cash_payment_id ON Cash(Payment_ID);


-- 1. CUSTOMER
CREATE TABLE Customer (
    Customer_ID        NUMBER PRIMARY KEY,
    Cus_Name           VARCHAR2(100) NOT NULL,
    Cus_Contact_Num    VARCHAR2(20),
    Cus_Loyalty        VARCHAR2(20) CHECK (Cus_Loyalty IN ('Yes', 'No'))
    CONSTRAINT uc_customer_name UNIQUE (Cus_Name)
);

-- 2. MENU ITEM
CREATE TABLE Menu_Item (
    Item_ID            NUMBER PRIMARY KEY,
    Menu_Name          VARCHAR2(100) NOT NULL,
    Menu_Description   VARCHAR2(255),
    Menu_Price         NUMBER(6,2) NOT NULL,
    Menu_Ingredients   VARCHAR2(255),
    Menu_Allergen      VARCHAR2(255)
     CONSTRAINT uc_menu_item_name UNIQUE (Menu_Name)
);

-- 3. ORDER
CREATE TABLE Orders (
    Order_ID           NUMBER PRIMARY KEY,
    Customer_ID        NUMBER NOT NULL,
    Order_Date         DATE DEFAULT SYSDATE,
    Order_Status       VARCHAR2(50),
    Order_Total_Amount NUMBER(8,2),
     CONSTRAINT fk_order_customer FOREIGN KEY (Customer_ID)
        REFERENCES Customer(Customer_ID),
    CONSTRAINT chk_order_status CHECK (Order_Status IN ('Pending', 'Completed', 'Cancelled'))
);

-- 4. ORDER_MENU (Bridge table)
CREATE TABLE Order_Menu (
    Order_ID           NUMBER,
    Item_ID            NUMBER,
    ORD_Quantity       NUMBER(3) NOT NULL,
    PRIMARY KEY (Order_ID, Item_ID),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Item_ID) REFERENCES Menu_Item(Item_ID)
    
);

-- 5. SUPPLIER
CREATE TABLE Supplier (
    Supplier_ID           NUMBER PRIMARY KEY,
    Supplier_Name         VARCHAR2(100) NOT NULL,
    Supplier_Contac_Num   VARCHAR2(20),
    Supplier_Delivery_Schedule VARCHAR2(100)
);

-- 6. INVENTORY
CREATE TABLE Inventory (
    Ingredient_ID      NUMBER PRIMARY KEY,
    Supplier_ID        NUMBER,
    Inv_Name           VARCHAR2(100),
    Inv_Quantity       NUMBER,
    Inv_Expiry_Date    DATE,
    FOREIGN KEY (Supplier_ID) REFERENCES Supplier(Supplier_ID)
);

-- 7. EMPLOYEE (Super entity)
CREATE TABLE Employee (
    Emp_ID             NUMBER PRIMARY KEY,
    Emp_Name           VARCHAR2(100) NOT NULL,
    Emp_Role           VARCHAR2(50),
    Emp_Contact        VARCHAR2(20)
);

-- 8. DRIVER (Subtype of Employee)
CREATE TABLE Driver (
    Emp_ID             NUMBER PRIMARY KEY,
    Emp_Wage           NUMBER(8,2),
    Emp_Shift_Details  VARCHAR2(100),
    FOREIGN KEY (Emp_ID) REFERENCES Employee(Emp_ID)
);

-- 9. KITCHEN STAFF (Subtype)
CREATE TABLE KitchenStaff (
    Emp_ID             NUMBER PRIMARY KEY,
    Emp_Wage           NUMBER(8,2),
    Emp_Shift_Details  VARCHAR2(100),
    FOREIGN KEY (Emp_ID) REFERENCES Employee(Emp_ID)
);

-- 10. CASHIER (Subtype)
CREATE TABLE Cashier (
    Emp_ID             NUMBER PRIMARY KEY,
    Emp_Wage           NUMBER(8,2),
    Emp_Shift_Details  VARCHAR2(100),
    FOREIGN KEY (Emp_ID) REFERENCES Employee(Emp_ID)
);

-- 11. DELIVERY (Bridge between Orders and Employee[Driver])
CREATE TABLE Delivery (
    Delivery_ID           NUMBER PRIMARY KEY,
    Order_ID              NUMBER NOT NULL,
    Emp_ID                NUMBER NOT NULL,
    Delivery_Pickup_Time  TIMESTAMP,
    Delivery_Dropoff_Time TIMESTAMP,
    Delivery_Status       VARCHAR2(50),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Emp_ID) REFERENCES Driver(Emp_ID)
);

-- 12. PAYMENT
CREATE TABLE Payment (
    Payment_ID            NUMBER PRIMARY KEY,
    Order_ID              NUMBER NOT NULL,
    Pay_Method            VARCHAR2(20) CHECK (Pay_Method IN ('Cash', 'Card')),
    Pay_Loyalty_Discount  NUMBER(5,2),
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID)
);

-- 13. CASH PAYMENT (Subtype of Payment)
CREATE TABLE Cash (
    Payment_ID            NUMBER PRIMARY KEY,
    FOREIGN KEY (Payment_ID) REFERENCES Payment(Payment_ID)
);

-- 14. CARD PAYMENT (Subtype of Payment)
CREATE TABLE Card (
    Payment_ID            NUMBER PRIMARY KEY,
    Card_Name             VARCHAR2(100),
    Card_Num              VARCHAR2(20),
    FOREIGN KEY (Payment_ID) REFERENCES Payment(Payment_ID)
);

--VIEWS
CREATE OR REPLACE VIEW Customer_Spending AS
SELECT 
    c.Customer_ID,
    c.Cus_Name,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    SUM(o.Order_Total_Amount) AS Total_Spent
FROM Customer c
LEFT JOIN Orders o ON c.Customer_ID = o.Customer_ID
GROUP BY c.Customer_ID, c.Cus_Name;

CREATE OR REPLACE VIEW Menu_Sales_Report AS
SELECT 
    m.Item_ID,
    m.Menu_Name,
    SUM(om.ORD_Quantity) AS Total_Units_Sold,
    SUM(om.ORD_Quantity * m.Menu_Price) AS Total_Revenue
FROM Menu_Item m
JOIN Order_Menu om ON m.Item_ID = om.Item_ID
GROUP BY m.Item_ID, m.Menu_Name
ORDER BY Total_Revenue DESC;

CREATE OR REPLACE VIEW Low_Inventory AS
SELECT 
    i.Ingredient_ID,
    i.Inv_Name,
    i.Inv_Quantity,
    i.Inv_Expiry_Date,
    s.Supplier_Name
FROM Inventory i
JOIN Supplier s ON i.Supplier_ID = s.Supplier_ID
WHERE i.Inv_Quantity < 10;

CREATE OR REPLACE VIEW Driver_Delivery_Log AS
SELECT 
    d.Delivery_ID,
    dr.Emp_ID,
    e.Emp_Name,
    d.Order_ID,
    d.Delivery_Pickup_Time,
    d.Delivery_Dropoff_Time,
    d.Delivery_Status
FROM Delivery d
JOIN Driver dr ON d.Emp_ID = dr.Emp_ID
JOIN Employee e ON dr.Emp_ID = e.Emp_ID;

CREATE OR REPLACE VIEW Payment_Summary AS
SELECT 
    p.Payment_ID,
    p.Order_ID,
    p.Pay_Method,
    p.Pay_Loyalty_Discount,
    o.Order_Total_Amount,
    (o.Order_Total_Amount - NVL(p.Pay_Loyalty_Discount, 0)) AS Final_Amount
FROM Payment p
JOIN Orders o ON p.Order_ID = o.Order_ID;

--Data Insertion
--Customer Table
INSERT INTO Customer VALUES (1, 'Alice Green', '0712345678', 'Yes');
INSERT INTO Customer VALUES (2, 'Bob Smith', '0723456789', 'No');
INSERT INTO Customer VALUES (3, 'Chloe Johnson', '0734567890', 'Yes');

--Menu Item
INSERT INTO Menu_Item VALUES (101, 'Cheeseburger', 'Beef patty with cheese and lettuce', 85.00, 'Beef, Cheese, Bun', 'Dairy, Gluten');
INSERT INTO Menu_Item VALUES (102, 'Vegan Wrap', 'Chickpea and avocado wrap', 70.00, 'Chickpeas, Avocado, Wrap', 'Gluten');
INSERT INTO Menu_Item VALUES (103, 'Fries', 'Crispy golden fries', 35.00, 'Potatoes, Salt', NULL);

--Orders
INSERT INTO Orders VALUES (201, 1, SYSDATE, 'Completed', 120.00);
INSERT INTO Orders VALUES (202, 2, SYSDATE - 1, 'Pending', 70.00);
INSERT INTO Orders VALUES (203, 3, SYSDATE - 2, 'Completed', 105.00);

--Order Menu
INSERT INTO Order_Menu VALUES (201, 101, 1);
INSERT INTO Order_Menu VALUES (201, 103, 1);
INSERT INTO Order_Menu VALUES (202, 102, 1);
INSERT INTO Order_Menu VALUES (203, 101, 1);
INSERT INTO Order_Menu VALUES (203, 103, 2);

--Supplier
INSERT INTO Supplier VALUES (301, 'Fresh Farms', '0601234567', 'Mon/Wed/Fri');
INSERT INTO Supplier VALUES (302, 'Vegan Delights', '0612345678', 'Tue/Thu');

--Inventory
INSERT INTO Inventory VALUES (401, 301, 'Beef Patty', 50, SYSDATE + 10);
INSERT INTO Inventory VALUES (402, 301, 'Cheese Slice', 15, SYSDATE + 5);
INSERT INTO Inventory VALUES (403, 302, 'Chickpeas', 8, SYSDATE + 3);

--Employee
INSERT INTO Employee VALUES (501, 'David Driver', 'Driver', '0741234567');
INSERT INTO Employee VALUES (502, 'Karen Cook', 'Kitchen Staff', '0752345678');
INSERT INTO Employee VALUES (503, 'Sam Cashier', 'Cashier', '0763456789');

--Driver
INSERT INTO Driver VALUES (501, 180.00, 'Morning Shift');

--Kitchen Staff
INSERT INTO KitchenStaff VALUES (502, 160.00, 'Afternoon Shift');

--Cashier
INSERT INTO Cashier VALUES (503, 150.00, 'Evening Shift');

--Delivery
INSERT INTO Delivery VALUES (601, 201, 501, SYSDATE - 0.5, SYSDATE - 0.4, 'Delivered');
INSERT INTO Delivery VALUES (602, 203, 501, SYSDATE - 1, SYSDATE - 0.9, 'Delivered');

--Payment
INSERT INTO Payment VALUES (701, 201, 'Card', 10.00);
INSERT INTO Payment VALUES (702, 202, 'Cash', NULL);
INSERT INTO Payment VALUES (703, 203, 'Card', 5.00);

--Cash
INSERT INTO Cash VALUES (702);

--Card
INSERT INTO Card VALUES (701, 'Alice Green', '1234-5678-9012-3456');
INSERT INTO Card VALUES (703, 'Chloe Johnson', '9876-5432-1098-7654');

-- General Queries 
-- 1. List all customers with loyalty membership
SELECT Cus_Name FROM Customer WHERE Cus_Loyalty = 'Yes';

-- 2. Show current menu items with prices
SELECT Menu_Name, Menu_Price FROM Menu_Item;

-- 3. Get all orders and their total amount
SELECT Order_ID, Order_Total_Amount FROM Orders;

-- 4. List drivers and their shift details
SELECT Emp_Name, Emp_Shift_Details FROM Employee E
JOIN Driver D ON E.Emp_ID = D.Emp_ID;

-- 5. Show inventory items close to expiry
SELECT Inv_Name, Inv_Expiry_Date FROM Inventory
WHERE Inv_Expiry_Date < SYSDATE + 7;

-- 6. View all delivered orders with timestamps
SELECT D.Order_ID, Delivery_Pickup_Time, Delivery_Dropoff_Time FROM Delivery D
WHERE Delivery_Status = 'Delivered';

-- 7. List employees and their roles
SELECT Emp_Name, Emp_Role FROM Employee;

-- 8. Show all payments made by card
SELECT P.Payment_ID, C.Card_Name FROM Payment P
JOIN Card C ON P.Payment_ID = C.Payment_ID;

-- 9. View orders made today
SELECT Order_ID FROM Orders WHERE Order_Date = TRUNC(SYSDATE);

-- 10. Show menu items that contain allergens
SELECT Menu_Name, Menu_Allergen FROM Menu_Item WHERE Menu_Allergen IS NOT NULL;

--Limitations on rows
-- 11. Show top 5 most expensive menu items
SELECT Menu_Name, Menu_Price FROM Menu_Item
ORDER BY Menu_Price DESC FETCH FIRST 5 ROWS ONLY;

-- 12. Show first 3 customer names
SELECT Cus_Name FROM Customer FETCH FIRST 3 ROWS ONLY;

--SORTING
-- 13. List customers in alphabetical order
SELECT Cus_Name FROM Customer ORDER BY Cus_Name ASC;

-- 14. Menu items by price ascending
SELECT Menu_Name, Menu_Price FROM Menu_Item ORDER BY Menu_Price;

-- 15. Orders by date descending
SELECT Order_ID, Order_Date FROM Orders ORDER BY Order_Date DESC;

-- 16. Inventory items by expiry
SELECT Inv_Name, Inv_Expiry_Date FROM Inventory ORDER BY Inv_Expiry_Date;

--LIKE AND OR
-- 17. Customers whose name starts with 'A'
SELECT Cus_Name FROM Customer WHERE Cus_Name LIKE 'A%';

-- 18. Menu items with 'Cheese' AND allergen
SELECT Menu_Name FROM Menu_Item
WHERE Menu_Description LIKE '%Cheese%' AND Menu_Allergen IS NOT NULL;

-- 19. Orders that are 'Pending' OR 'Preparing'
SELECT Order_ID FROM Orders
WHERE Order_Status = 'Pending' OR Order_Status = 'Preparing';


--Character Funtions
-- 20. Convert employee names to uppercase
SELECT UPPER(Emp_Name) FROM Employee;

-- 21. Show first 5 letters of customer names
SELECT SUBSTR(Cus_Name, 1, 5) FROM Customer;

--Round Trunc
-- 22. Round menu prices to whole number
SELECT Menu_Name, ROUND(Menu_Price) FROM Menu_Item;

-- 23. Truncate order total to no decimals
SELECT Order_ID, TRUNC(Order_Total_Amount) FROM Orders;

--Date Functions
-- 24. Number of days until expiry
SELECT Inv_Name, Inv_Expiry_Date - SYSDATE AS Days_Left FROM Inventory;

-- 25. Format order date
SELECT Order_ID, TO_CHAR(Order_Date, 'DD-Mon-YYYY') FROM Orders;

-- 26. Orders from last 7 days
SELECT Order_ID FROM Orders WHERE Order_Date >= SYSDATE - 7;

--Aggregate Functions
-- 27. Total number of orders
SELECT COUNT(*) FROM Orders;

-- 28. Average item price
SELECT AVG(Menu_Price) FROM Menu_Item;

-- 29. Max wage for drivers
SELECT MAX(Emp_Wage) FROM Driver;

-- 30. Min quantity in inventory
SELECT MIN(Inv_Quantity) FROM Inventory;


--Group by, Having
-- 31. Orders per customer
SELECT Customer_ID, COUNT(*) FROM Orders GROUP BY Customer_ID;

-- 32. Inventory per supplier
SELECT Supplier_ID, SUM(Inv_Quantity) FROM Inventory GROUP BY Supplier_ID;-- 42. Customers with more than 2 orders
SELECT Customer_ID, COUNT(*) AS Total_Orders
FROM Orders GROUP BY Customer_ID HAVING COUNT(*) > 2;

-- 33. Customers with more than 2 orders
SELECT Customer_ID, COUNT(*) AS Total_Orders
FROM Orders GROUP BY Customer_ID HAVING COUNT(*) > 2;


--Joins
-- 34. Customer names with their order status
SELECT C.Cus_Name, O.Order_Status
FROM Customer C JOIN Orders O ON C.Customer_ID = O.Customer_ID;

-- 35. Order items with their menu names
SELECT OM.Order_ID, MI.Menu_Name
FROM Order_Menu OM JOIN Menu_Item MI ON OM.Item_ID = MI.Item_ID;

-- 36. Orders with payment methods
SELECT O.Order_ID, P.Pay_Method
FROM Orders O JOIN Payment P ON O.Order_ID = P.Order_ID;

-- 37. Deliveries with driver names
SELECT D.Delivery_ID, E.Emp_Name
FROM Delivery D
JOIN Driver DR ON D.Emp_ID = DR.Emp_ID
JOIN Employee E ON DR.Emp_ID = E.Emp_ID;

-- 38. Inventory with supplier names
SELECT I.Inv_Name, S.Supplier_Name
FROM Inventory I JOIN Supplier S ON I.Supplier_ID = S.Supplier_ID;

--Sub-Queries
--List of Customers with a total amount more than the average order
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING SUM(order_total) > (
        SELECT AVG(order_total) FROM orders
    )
);

--List of Employees who took more orders than EMP with ID=1
SELECT employee_name
FROM employees
WHERE employee_id IN (
    SELECT employee_id
    FROM orders
    GROUP BY employee_id
    HAVING COUNT(*) > (
        SELECT COUNT(*) FROM orders WHERE employee_id = 1
    )
);
