using System;
using GetDataLambda.Models;

namespace GetDataLambda {
  public interface IRepository
  {
      IStockItem GetStockItem(string stockItemName);
      IPackageType GetPackageType(string packageTypeName);
      IColor GetColor(string colorName);
  }
}