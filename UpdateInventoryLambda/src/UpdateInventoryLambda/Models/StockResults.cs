using System;
using System.Text.Json.Serialization;
using Newtonsoft.Json;

namespace UpdateInventoryLambda.Models
{
  public class StockResult
  {
    public StockItem StockItem { get; set; }
    [JsonProperty]
    public bool StockItemExists { get => this.StockItem != null; }
    public Color Color { get; set; }
    [JsonProperty]
    public bool ColorExists { get => this.Color != null; }
    public PackageType PackageType { get; set; }
    [JsonProperty]
    public bool PackageTypeExists { get => this.PackageType != null; }
    public InventoryPurchase InventoryPurchase { get; set; }
  }
}