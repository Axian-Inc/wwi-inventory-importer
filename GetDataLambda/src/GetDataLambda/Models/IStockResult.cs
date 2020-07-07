using System;

namespace GetDataLambda.Models {
  public interface IStockResult
  {
      IStockItem StockItem { get; set;}
      bool StockItemExists { get; }
      IColor Color { get; set;}
      bool ColorExists { get; }
      IPackageType PackageType { get; set;}
      bool PackageTypeExists { get; }
      IInventoryPurchase InventoryPurchase { get; set;}
  }
}