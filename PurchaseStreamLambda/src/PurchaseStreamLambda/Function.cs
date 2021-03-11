using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.Lambda.Core;
using Amazon.DynamoDBv2;
using Amazon.StepFunctions;
using Amazon.StepFunctions.Model;
using System.Text.Json;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace PurchaseStreamLambda
{
    public class Function
    {
        
        /// <summary>
        /// A simple function that takes a string and does a ToUpper
        /// </summary>
        /// <param name="input"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        public async Task FunctionHandler(DynamoDBEvent dynamoEvent, ILambdaContext context)
        {
            var client = new AmazonStepFunctionsClient();
            var sfnArn = Environment.GetEnvironmentVariable("STEP_FUNCTION_ARN");
            LambdaLogger.Log($"Processing {dynamoEvent.Records.Count()}");
            LambdaLogger.Log($"ARN {sfnArn}");
            IList<DynamoDBEvent.DynamodbStreamRecord> r =  dynamoEvent.Records;
            foreach(DynamoDBEvent.DynamodbStreamRecord record in dynamoEvent.Records) {
                if(record.EventName == OperationType.INSERT) {
                    var incoming = record.Dynamodb.NewImage.ToDynamoEntity<PurchaseOrder>();
                    LambdaLogger.Log($"ID {incoming.PurchaseId}");
                    LambdaLogger.Log($"Color {incoming.ColorName}");
                    var request = new StartExecutionRequest() {
                        Input = JsonSerializer.Serialize(new {
                            PurchasedInventory = new object[] {incoming}
                        }),
                        Name = Guid.NewGuid().ToString(),
                        StateMachineArn = sfnArn,
                    };

                    var resp = await client.StartExecutionAsync(request);
                    if(resp.HttpStatusCode != System.Net.HttpStatusCode.OK) {
                        throw new Exception($"Failed with code {resp.HttpStatusCode}: {JsonSerializer.Serialize(resp.ResponseMetadata)}");
                    }
                    
                }
            }
        }
    }
    
}
