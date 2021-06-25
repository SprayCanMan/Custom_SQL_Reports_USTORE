USE [uStore]
GO
/****** Object:  StoredProcedure [dbo].[Report_ListOrderItems_withProperties6]    Script Date: 6/25/2021 2:54:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Report_ListOrderItems_withProperties6]
	(
		@MallID int,
		@ActiveUserID int,
		@StoreID int = NULL,
		@StartDate datetime = NULL,
		@EndDate datetime = NULL
	)
AS
DECLARE @CultureID int
SET @CultureID = dbo.fn_StoreSetupCulture(@StoreID)
SELECT
	OrderProduct.OrderProductID AS 'Item ID',
	Orders.EncryptedOrderId AS 'Order ID',
	Product_Culture.Name AS 'Product Name',
	CASE 
		WHEN DOC.DocTypeID in (6,7)
		THEN 'True'
		ELSE 'False'
	END AS 'Includes URL',
	OrderProduct.PurlPortName AS 'Port Name',
	Users.FirstName + ' ' + Users.LastName AS 'Customer Name',
	Orders.OrderAmount AS 'Subtotal Order Price',
	Orders.BillAmount AS 'Total Order Price',
	Orders.Bill_Add1, Orders.Bill_Add2,
	Orders.Bill_AddressReference,
	Orders.Bill_City,
	Orders.Bill_Company,
	Orders.Bill_Email,
	Orders.Bill_Fax,
	Orders.Bill_Name,
	Orders.Bill_Phone,
	Orders.Bill_Zip,
	Bill_StateName.Name AS 'Bill State Name',
	Bill_CountryName.Name AS 'Bill Country Name',
	Product_Culture.ProductID,
	ISNULL(CAST(DeliveryItem.QuantityPerRecipient AS nvarchar(50))
		+ ' '
		+ dbo.fn_GetProductUnitName(DeliveryItem.QuantityPerRecipient, OrderProduct.ProductUnitID, @CultureID),
		'-')
		AS 'Quantity Per Recipient',
	OrderProduct.NumRecipients,
	CASE
		WHEN DeliveryItem.QuantityPerRecipient IS NULL
		THEN CAST(OrderProduct.TotalQuantity AS nvarchar(50)) + ' ' + dbo.fn_GetProductUnitName(OrderProduct.TotalQuantity, OrderProduct.ProductUnitID, @CultureID)
		ELSE CAST(OrderProduct.NumRecipients * DeliveryItem.QuantityPerRecipient AS nvarchar(50)) + ' ' + dbo.fn_GetProductUnitName(OrderProduct.NumRecipients * DeliveryItem.QuantityPerRecipient, OrderProduct.ProductUnitID, @CultureID)
	END AS 'Total Quantity',
	OrderProduct.TotalQuantity,
	OrderProduct.PricePerRecipient,
	OrderProduct.ProductPriceSubtotal,
	OrderProduct.ShippingPriceSubtotal,
	OrderProduct.TotalPrice AS 'Total Item Price',
	OrderProduct.DateAdded,
	Orders.DateOrderCreated,
	DeliveryMethod.Name AS 'Delivery Method',
	DPS.Name AS 'Delivery Service',
	OrderProduct.RecipientListPrice,
	OrderProduct.ApprovalRejectNotes,
	OrderProduct.Cost AS 'Item Cost',
	OrderProduct.TaxAmount AS 'Item Tax Amount',
	DeliveryTentative.DeliveryTentativeID,
	DeliveryItem.DeliveryItemID,
	DeliveryTentative.Ship_Add1,
	DeliveryTentative.Ship_Add2,
	DeliveryTentative.Ship_AddressReference,
	DeliveryTentative.Ship_City,
	DeliveryTentative.Ship_Company,
	DeliveryTentative.Ship_Fax,
	DeliveryTentative.Ship_Name,
	DeliveryTentative.Ship_Phone,
	Ship_StateName.Name AS 'Ship State Name',
	Ship_CountryName.Name AS 'Ship Country Name',
	DeliveryTentative.Ship_Zip,
	Orders.OrderId,
	OPDV.DialValue,
	D.VisibleToCustomer

FROM OrderProduct
	JOIN Orders ON Orders.OrderID = OrderProduct.OrderID
	JOIN Product_Culture ON OrderProduct.ProductID = Product_Culture.ProductID
		AND Product_Culture.CultureID = @CultureID
	JOIN DOC ON Doc.ProductID = OrderProduct.ProductID
	JOIN DeliveryItem ON DeliveryItem.OrderProductID = OrderProduct.OrderProductID
	JOIN DeliveryTentative ON DeliveryTentative.DeliveryTentativeID = DeliveryItem.DeliveryTentativeID
	JOIN DeliveryMethod ON DeliveryMethod.DeliveryMethodId = OrderProduct.DeliveryMethodId
	JOIN DeliveryProviderService DPS ON DPS.DeliveryProviderServiceID = DeliveryTentative.DeliveryServiceId
	JOIN Users ON Users.UserID = Orders.UserID
	JOIN fn_UserStores(@ActiveUserId, 12) US ON Orders.StoreId = US.StoreID
	LEFT OUTER JOIN Province_Culture AS Bill_StateName ON Bill_StateName.ProvinceId = Orders.Bill_State
		AND Bill_StateName.CultureId = @CultureID
	LEFT OUTER JOIN Province_Culture AS Ship_StateName ON Ship_StateName.ProvinceId = DeliveryTentative.Ship_State
		AND Ship_StateName.CultureId = @CultureID
	LEFT OUTER JOIN Country_Culture AS Bill_CountryName ON Bill_CountryName.CountryId = Orders.Bill_Country
		AND Bill_CountryName.CultureID = @CultureID
	LEFT OUTER JOIN Country_Culture AS Ship_CountryName ON Ship_CountryName.CountryId = DeliveryTentative.Ship_Country
		AND Ship_CountryName.CultureID = @CultureID
	INNER JOIN OrderProductDialValue AS OPDV ON OrderProduct.OrderProductID = OPDV.OrderProductID 
	INNER JOIN Dial AS D ON OPDV.DialID = D.DialID
WHERE
	Orders.StatusID = 1
	AND Orders.IsCart = 0
	AND Orders.IsSaveForLater = 0
	AND OrderProduct.IsDraft = 0
	AND OrderProduct.StatusID = 1
	AND OrderProduct.ParentOrderProductID IS NULL
	AND (Orders.StoreID=@StoreID OR (ISNULL(@StoreID, -1) <= 0))
	AND (@StartDate <= Orders.DisplayOrderDate OR @StartDate IS NULL OR @StartDate ='')
	AND (DATEADD(day, 1, @EndDate) >= Orders.DateOrderCreated OR @EndDate IS NULL OR @EndDate = '')
	AND (D.IsProperty = 1)
