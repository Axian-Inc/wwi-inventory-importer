using System;
using System.Data;
using GetDataLambda.Models;
using Microsoft.Data.SqlClient;

namespace GetDataLambda
{
  public class Repository : IRepository
  {
    private string _connectionString {get;set;}
    public Repository() {
      string server = Environment.GetEnvironmentVariable("DB_ENDPOINT");
      string database = Environment.GetEnvironmentVariable("DATABASE");
      string username = Environment.GetEnvironmentVariable("USER");
      string pwd = Environment.GetEnvironmentVariable("PASSWORD");
      _connectionString = String.Format("Data Source={0};Initial Catalog={1};User ID={2};Password={3}",server,database,username,pwd);
    }
    public IColor GetColor(string colorName)
    {
      IColor result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"SELECT ColorID, ColorName from Warehouse.Colors where ColorName = @ColorName", Conn))
        {
          Cmd.Parameters.Add("@ColorName", SqlDbType.NVarChar);
          Cmd.Parameters["@ColorName"].Value = colorName;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          SqlDataReader rdr = Cmd.ExecuteReader();

          // Loop through the results and add to list
          while (rdr.Read())
          {
            result = new Color();
            result.ID = rdr.GetInt32(0);
            result.ColorName = rdr.GetString(1);
          }
        }
      }
      return result;
    }

    public IPackageType GetPackageType(string packageTypeName)
    {
      IPackageType result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"SELECT PackageTypeID, PackageTypeName from Warehouse.PackageTypes where PackageTypeName = @PackageTypeName", Conn))
        {
          Cmd.Parameters.Add("@PackageTypeName", SqlDbType.NVarChar);
          Cmd.Parameters["@PackageTypeName"].Value = packageTypeName;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          SqlDataReader rdr = Cmd.ExecuteReader();

          // Loop through the results and add to list
          while (rdr.Read())
          {
            result = new PackageType();
            result.ID = rdr.GetInt32(0);
            result.PackageTypeName = rdr.GetString(1);
          }
        }
      }
      return result;
    }

    public IStockItem GetStockItem(string stockItemName)
    {
      IStockItem result = null;
      using (var Conn = new SqlConnection(_connectionString))
      {
        using (var Cmd = new SqlCommand($"SELECT StockItemID, StockItemName from Warehouse.StockItems where StockItemName = @StockItemName", Conn))
        {
          Cmd.Parameters.Add("@StockItemName", SqlDbType.NVarChar);
          Cmd.Parameters["@StockItemName"].Value = stockItemName;
          // Open SQL Connection
          Conn.Open();

          // Execute SQL Command
          SqlDataReader rdr = Cmd.ExecuteReader();

          // Loop through the results and add to list
          while (rdr.Read())
          {
            result = new StockItem();
            result.ID = rdr.GetInt32(0);
            result.StockItemName = rdr.GetString(1);
          }
        }
      }
      return result;
    }
  }
}