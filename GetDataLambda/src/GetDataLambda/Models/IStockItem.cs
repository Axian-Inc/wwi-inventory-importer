using System;

namespace GetDataLambda.Models {
  public interface IStockItem
  {
      int ID { get; set;}
      string StockItemName { get; set;}
      int ColorID { get; set;}
      int OuterPackageID { get; set;}
      decimal UnitPrice {get;set;}
      decimal RecommendedRetailPrice {get;set;}
      string MarketingComments {get;set;}
  }
}