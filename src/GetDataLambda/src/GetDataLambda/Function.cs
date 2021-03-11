using System.Collections.Generic;
using System.Net;

using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using GetDataLambda.Models;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace GetDataLambda
{
    public class Function
    {

        public IStockResult FunctionHandler(InventoryPurchase input, ILambdaContext context)
        {
            IRepository repo = new Repository();
            IStockResult results = new StockResult();

            results.Color = repo.GetColor(input.ColorName);
            results.PackageType = repo.GetPackageType(input.OuterPackageName);
            results.StockItem = repo.GetStockItem(input.StockItemName);
            results.InventoryPurchase = input;

            return results;
        }


        /// <summary>
        /// A Lambda function to respond to HTTP Get methods from API Gateway
        /// </summary>
        /// <param name="request"></param>
        /// <returns>The API Gateway response.</returns>
        public APIGatewayProxyResponse Get(APIGatewayProxyRequest request, ILambdaContext context)
        {
            // TO REMOVE
            IRepository repo = new Repository();
            IStockResult results = new StockResult();

            results.Color = repo.GetColor("grey");
            results.PackageType = repo.GetPackageType("box");
            results.StockItem = repo.GetStockItem("some stock");
            results.InventoryPurchase = null;


            context.Logger.LogLine("Get Request\n");

            var response = new APIGatewayProxyResponse
            {
                StatusCode = (int)HttpStatusCode.OK,
                Body = "Hello AWS Serverless",
                Headers = new Dictionary<string, string> { { "Content-Type", "text/plain" } }
            };

            return response;
        }
    }

    public class InventoryPurchase : IInventoryPurchase {
        public string StockItemName { get; set;}
        public string ColorName { get; set;}
        public string OuterPackageName { get; set;}
        public decimal UnitPrice {get;set;}
        public decimal RecommendedRetailPrice {get;set;}
        public string MarketingComments {get;set;}
        public int PurchaseQuantity {get;set;}
    }
}
