using System;
using System.Text.Json.Serialization;
using Newtonsoft.Json;

namespace GetDataLambda.Models
{
  public class StockResult : IStockResult
  {
    public IStockItem StockItem { get; set; }
    [JsonProperty]
    public bool StockItemExists { get => this.StockItem != null; }
    public IColor Color { get; set; }
    [JsonProperty]
    public bool ColorExists { get => this.Color != null; }
    public IPackageType PackageType { get; set; }
    [JsonProperty]
    public bool PackageTypeExists { get => this.PackageType != null; }
    public IInventoryPurchase InventoryPurchase { get; set; }
  }
}