namespace GetDataLambda.Models {
  public interface IInventoryPurchase
  {
      string StockItemName { get; set;}
      string ColorName { get; set;}
      string OuterPackageName { get; set;}
      decimal UnitPrice {get;set;}
      decimal RecommendedRetailPrice {get;set;}
      string MarketingComments {get;set;}
      int PurchaseQuantity {get;set;}
  }
}