using System;

namespace UpdateInventoryLambda.Models
{
  public class StockItem
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