namespace PurchaseStreamLambda {
      public class PurchaseOrder
    {
        public PurchaseOrder(){}
        public string PurchaseId {get;set;}
        public string StockItemName { get; set;}
        public string ColorName { get; set;}
        public string OuterPackageName { get; set;}
        public decimal UnitPrice {get;set;}
        public decimal RecommendedRetailPrice {get;set;}
        public string MarketingComments {get;set;}
        public int PurchaseQuantity {get;set;}
    }
}