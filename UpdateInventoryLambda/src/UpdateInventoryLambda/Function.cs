using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;

using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using UpdateInventoryLambda.Models;
using Newtonsoft.Json;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace UpdateInventoryLambda
{
    public class Function
    {
        /// <summary>
        /// Default constructor that Lambda will invoke.
        /// </summary>
        public StockResult FunctionHandler(Input input)
        {
            Console.WriteLine($"Input object: {JsonConvert.SerializeObject(input)}");
            StockResult result = null;
            Repository repo = new Repository();
            result = new StockResult();
            result.InventoryPurchase = input.StockResult.InventoryPurchase;
            switch(input.OperationName) {
                case "InsertColor":
                    result.Color = repo.InsertColor(input.StockResult.InventoryPurchase.ColorName);
                    break;
                case "InsertPackageType":
                    result.PackageType = repo.InsertPackaging(input.StockResult.InventoryPurchase.OuterPackageName);
                    break;
                case "InsertStockItem":
                    result.StockItem = repo.InsertStockItem(input.StockResult.InventoryPurchase, input.StockResult.Color.ID, input.StockResult.PackageType.ID);
                    break;
                case "UpdateInventoryQty":
                    repo.UpdateInventoryQuantity(input.StockResult.StockItem.ID, input.StockResult.InventoryPurchase.PurchaseQuantity);
                    break;
            }
            return result;
        }


        /// <summary>
        /// A Lambda function to respond to HTTP Get methods from API Gateway
        /// </summary>
        /// <param name="request"></param>
        /// <returns>The API Gateway response.</returns>
        public APIGatewayProxyResponse Get(APIGatewayProxyRequest request, ILambdaContext context)
        {
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

    public class Input {
        public string OperationName { get; set; }
        public StockResult StockResult { get; set; }
    }
}
