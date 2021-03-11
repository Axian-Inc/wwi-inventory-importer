using System;

namespace GetDataLambda.Models
{
  public class Color : IColor
  {
    public int ID { get; set; }
    public string ColorName { get; set; }
  }
}