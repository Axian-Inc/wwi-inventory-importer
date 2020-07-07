{
  "Comment": "A Hello World example of the Amazon States Language using Pass states",
  "StartAt": "Map State",
  "States": {
    "Map State": {
      "ItemsPath": "$.PurchasedInventory",
      "Type": "Map",
      "MaxConcurrency": 0,
      "Iterator": {
        "StartAt": "GetStockInfo",
        "States": {
          "GetStockInfo": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "arn:aws:lambda:us-east-2:590316689173:function:gh-get-wwi-stock-data:$LATEST",
              "Payload.$": "$"
            },
            "ResultPath": "$",
            "OutputPath":"$.Payload",
            "Next": "StockItemExists"
          },
          "StockItemExists": {
            "Type": "Choice",
            "Choices": [
              {
                "Variable": "$.StockItemExists",
                "BooleanEquals": false,
                "Next": "AddNewStock"
              },
              {
                "Variable": "$.StockItemExists",
                "BooleanEquals": true,
                "Next": "UpdateInventoryQty"
              }
            ]
          },
          "AddNewStock": {
            "Type": "Parallel",
            "Next": "CombineResults",
            "ResultPath": "$.lambdaResults",
            "Branches": [
              {
                "StartAt": "ColorExists",
                "States": {
                  "ColorExists": {
                    "Type": "Choice",
                    "Choices": [
                      {
                        "Variable": "$.ColorExists",
                        "BooleanEquals": false,
                        "Next": "InsertColor"
                      },
                      {
                        "Variable": "$.ColorExists",
                        "BooleanEquals": true,
                        "Next": "SkipColorCreation"
                      }
                    ]
                  },
                  "InsertColor": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "arn:aws:lambda:us-east-2:590316689173:function:gh-update-stock-data:$LATEST",
                      "Payload": {
                        "OperationName": "InsertColor",
                        "StockResult.$": "$"
                      }
                    },
                    "ResultPath": "$",
                    "OutputPath":"$.Payload.Color",
                    "End": true
                  },
                  "SkipColorCreation": {
                    "Type": "Pass",
                    "OutputPath":"$.Color",
                    "End": true
                  }
                }
              },
              {
                "StartAt": "PackageTypeExists",
                "States": {
                  "PackageTypeExists": {
                    "Type": "Choice",
                    "Choices": [
                      {
                        "Variable": "$.ColorExists",
                        "BooleanEquals": false,
                        "Next": "InsertPackageType"
                      },
                      {
                        "Variable": "$.ColorExists",
                        "BooleanEquals": true,
                        "Next": "SkipPackageTypeCreation"
                      }
                    ]
                  },
                  "InsertPackageType": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "arn:aws:lambda:us-east-2:590316689173:function:gh-update-stock-data:$LATEST",
                      "Payload": {
                        "OperationName": "InsertPackageType",
                        "StockResult.$": "$"
                      }
                    },
                    "ResultPath": "$",
                    "OutputPath":"$.Payload.PackageType",
                    "End": true
                  },
                  "SkipPackageTypeCreation": {
                    "Type": "Pass",
                    "OutputPath":"$.PackageType",
                    "End": true
                  }
                }
              }
            ]
            
          },
          "CombineResults": {
            "Type": "Pass",
            "Parameters": {
              "Color.$": "$.lambdaResults[0]",
              "PackageType.$": "$.lambdaResults[1]",
              "InventoryPurchase.$": "$.InventoryPurchase"
            },
            "Next": "InsertStockItem"
          },
          "InsertStockItem": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "arn:aws:lambda:us-east-2:590316689173:function:gh-update-stock-data:$LATEST",
              "Payload": {
                "OperationName": "InsertStockItem",
                "StockResult.$": "$"
              }
            },
            "ResultPath": "$",
            "OutputPath":"$.Payload",
            "Next": "UpdateInventoryQty"
          },
          "UpdateInventoryQty": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "Parameters": {
              "FunctionName": "arn:aws:lambda:us-east-2:590316689173:function:gh-update-stock-data:$LATEST",
              "Payload": {
                "OperationName": "UpdateInventoryQty",
                "StockResult.$": "$"
              }
            },
            "End": true
          }
        }
      },
      "End": true
    }
  }
}