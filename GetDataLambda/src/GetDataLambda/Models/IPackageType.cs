using System;

namespace GetDataLambda.Models {
  public interface IPackageType
  {
      int ID { get; set;}
      string PackageTypeName { get; set;}
  }
}