using System;

namespace GetDataLambda.Models
{
  public class StockItem : IStockItem
  {
    public int ID { get; set; }
    public string StockItemName { get; set; }
    public int ColorID { get; set; }
    public int OuterPackageID { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal RecommendedRetailPrice { get; set; }
    public string MarketingComments { get; set; }
  }
}