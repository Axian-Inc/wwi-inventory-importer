using System;

namespace GetDataLambda.Models
{
  public class PackageType : IPackageType
  {
    public int ID { get; set; }
    public string PackageTypeName { get; set; }
  }
}