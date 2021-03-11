using System;
using System.Data;
using Microsoft.Data.SqlClient;
using UpdateInventoryLambda.Models;

namespace UpdateInventoryLambda
{
  public class Repository
  {
    private string _connectionString {get;set;}
    public Repository() {
      string server = Environment.GetEnvironmentVariable("DB_ENDPOINT");
      string database = Environment.GetEnvironmentVariable("DATABASE");
      string username = Environment.GetEnvironmentVariable("USER");
      string pwd = Environment.GetEnvironmentVariable("PASSWORD");
      _connectionString = String.Format("Data Source={0};Initial Catalog={1};User ID={2};Password={3}",server,database,username,pwd);
    }

    public void UpdateInventoryQuantity(int stockItemId, int quantityOrdered) {
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"update Warehouse.StockItemHoldings set QuantityOnHand = QuantityOnHand + @NewQuantity where StockItemID = @StockItemID", Conn))
        {
          Cmd.Parameters.Add("@StockItemID", SqlDbType.Int);
          Cmd.Parameters.Add("@NewQuantity", SqlDbType.Int);
          Cmd.Parameters["@StockItemID"].Value = stockItemId;
          Cmd.Parameters["@NewQuantity"].Value = quantityOrdered;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          SqlDataReader rdr = Cmd.ExecuteReader();
        }
      }
    }

    public StockItem InsertStockItem(InventoryPurchase inventoryPurchase, int colorId, int packageId) {
      StockItem result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        // Open SQL Connection
        Conn.Open();

        // Add stock item
        using (var Cmd = new SqlCommand(@"
        insert into Warehouse.StockItems (
          StockItemName, 
          SupplierID,
          UnitPackageID,
          OuterPackageID,
          ColorId,
          LeadTimeDays,
          QuantityPerOuter,
          IsChillerStock,
          TaxRate,
          UnitPrice,
          RecommendedRetailPrice,
          TypicalWeightPerUnit,
          MarketingComments,
          LastEditedBy) 
        output INSERTED.StockItemId
        values (
          @StockItemName, 
          12,
          1,
          @OuterPackageId,
          @ColorId,
          5,
          4,
          0,
          15,
          @UnitPrice,
          @RetailPrice,
          .05,
          @MarketingComments,
          1)", Conn))
        {
          Cmd.Parameters.Add("@StockItemName", SqlDbType.NVarChar);
          Cmd.Parameters.Add("@OuterPackageId", SqlDbType.Int);
          Cmd.Parameters.Add("@ColorId", SqlDbType.Int);
          Cmd.Parameters.Add("@UnitPrice", SqlDbType.Decimal);
          Cmd.Parameters.Add("@RetailPrice", SqlDbType.Decimal);
          Cmd.Parameters.Add("@MarketingComments", SqlDbType.NVarChar);
          Cmd.Parameters["@StockItemName"].Value = inventoryPurchase.StockItemName;
          Cmd.Parameters["@OuterPackageId"].Value = packageId;
          Cmd.Parameters["@ColorId"].Value = colorId;
          Cmd.Parameters["@UnitPrice"].Value = inventoryPurchase.UnitPrice;
          Cmd.Parameters["@RetailPrice"].Value = inventoryPurchase.RecommendedRetailPrice;
          Cmd.Parameters["@MarketingComments"].Value = inventoryPurchase.MarketingComments;

          // Execute SQL Command
          Int32 id = (Int32)Cmd.ExecuteScalar();

          result = new StockItem();
          result.ID = id;
          result.StockItemName = inventoryPurchase.StockItemName;
          result.ColorID = colorId;
          result.OuterPackageID = packageId;
          result.UnitPrice = inventoryPurchase.UnitPrice;
          result.RecommendedRetailPrice = inventoryPurchase.RecommendedRetailPrice;
          result.MarketingComments = inventoryPurchase.MarketingComments;
        }
        // Add initial holdings
        using (var Cmd = new SqlCommand(@"
          insert into Warehouse.StockItemHoldings(StockItemID, QuantityOnHand, BinLocation, LastStocktakeQuantity, LastCostPrice, ReorderLevel, TargetStockLevel, LastEditedBy)
          values (@StockItemID, 0, 'L-3', 1000, 5.00, 10, 1000, 3)", Conn))
        {
            Cmd.Parameters.Add("@StockItemID", SqlDbType.Int);
            Cmd.Parameters["@StockItemID"].Value = result.ID;

            // Execute SQL Command
            Cmd.ExecuteNonQuery();
        }
        // Add to stock group
        using (var Cmd = new SqlCommand(@"
          insert into Warehouse.StockItemStockGroups(StockItemID, StockGroupID, LastEditedBy)
          values (@StockItemID, 1, 3)", Conn))
        {
            Cmd.Parameters.Add("@StockItemID", SqlDbType.Int);
            Cmd.Parameters["@StockItemID"].Value = result.ID;

            // Execute SQL Command
            Cmd.ExecuteNonQuery();
        }
        Conn.Close();
      }
      return result;
    }

    public Color InsertColor(string colorName) {
      Color result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"insert into Warehouse.Colors (ColorName, LastEditedBy) output INSERTED.ColorID values (@ColorName, 1)", Conn))
        {
          Cmd.Parameters.Add("@ColorName", SqlDbType.NVarChar);
          Cmd.Parameters["@ColorName"].Value = colorName;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          Int32 id = (Int32)Cmd.ExecuteScalar();

          result = new Color();
          result.ID = id;
          result.ColorName = colorName;
        }
      }
      return result;
    }
    public PackageType InsertPackaging(string packageTypeName) {
      PackageType result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"insert into Warehouse.PackageTypes (PackageTypeName, LastEditedBy) output INSERTED.PackageTypeID values (@PackageTypeName, 1)", Conn))
        {
          Cmd.Parameters.Add("@PackageTypeName", SqlDbType.NVarChar);
          Cmd.Parameters["@PackageTypeName"].Value = packageTypeName;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          Int32 id = (Int32)Cmd.ExecuteScalar();

          result = new PackageType();
          result.ID = id;
          result.PackageTypeName = packageTypeName;
        }
      }
      return result;
    }
  }
}