provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Sets the region used in AWS"
}

variable "env" {
  type    = string
  default = "gjh"
}



resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "iam_policy_for_lambda" {
  name = "iam_for_lambda_main_role-${var.env}"
  role = aws_iam_role.iam_for_lambda.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeStream",
                "dynamodb:GetRecords",
                "dynamodb:GetShardIterator",
                "dyanmodb:ListStreams"
            ],
            "Resource": [
                "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "states:StartExecution"
            ],
            "Resource": [
                "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:*"
            ]
        }
    ]
}
EOF
}


resource "aws_lambda_function" "data_lambda" {
  filename         = "../GetDataLambda/src/GetDataLambda/bin/Release/netcoreapp3.1/GetDataLambda.zip"
  function_name    = "get-inventory-data-${var.env}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "GetDataLambda::GetDataLambda.Function::FunctionHandler"
  source_code_hash = filebase64sha256("../GetDataLambda/src/GetDataLambda/bin/Release/netcoreapp3.1/GetDataLambda.zip")
  runtime          = "dotnetcore3.1"
  timeout = 30

  environment {
    variables = {
      DB_ENDPOINT = "ffthh-sql-server.database.windows.net"
      DATABASE = "WideWorldImporters"
      USER = "ffthh"
      PASSWORD = "ldtime1!"
    }
  }
}

resource "aws_lambda_function" "insert_lambda" {
  filename         = "../UpdateInventoryLambda/src/UpdateInventoryLambda/bin/Release/netcoreapp3.1/UpdateInventoryLambda.zip"
  function_name    = "insert-inventory-${var.env}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "UpdateInventoryLambda::UpdateInventoryLambda.Function::FunctionHandler"
  source_code_hash = filebase64sha256("../UpdateInventoryLambda/src/UpdateInventoryLambda/bin/Release/netcoreapp3.1/UpdateInventoryLambda.zip")
  runtime          = "dotnetcore3.1"
  timeout = 30

  environment {
    variables = {
      DB_ENDPOINT = "ffthh-sql-server.database.windows.net"
      DATABASE = "WideWorldImporters"
      USER = "ffthh"
      PASSWORD = "ldtime1!"
    }
  }
}

resource "aws_lambda_function" "streamer_lambda" {
  filename         = "../PurchaseStreamLambda/src/PurchaseStreamLambda/bin/Release/netcoreapp3.1/PurchaseStreamLambda.zip"
  function_name    = "stream-purchase-${var.env}"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "PurchaseStreamLambda::PurchaseStreamLambda.Function::FunctionHandler"
  source_code_hash = filebase64sha256("../PurchaseStreamLambda/src/PurchaseStreamLambda/bin/Release/netcoreapp3.1/PurchaseStreamLambda.zip")
  runtime          = "dotnetcore3.1"
  timeout = 30

  environment {
    variables = {
      STEP_FUNCTION_ARN = aws_sfn_state_machine.sfn_state_machine.arn
    }
  }
}

resource "aws_dynamodb_table" "db" {
  name           = "PurchaseOrders-${var.env}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PurchaseId"
  stream_enabled = true
  stream_view_type = "NEW_IMAGE"

  attribute {
    name = "PurchaseId"
    type = "S"
  }

}

resource "aws_lambda_event_source_mapping" "document_table_stream" {
  event_source_arn  = aws_dynamodb_table.db.stream_arn
  function_name     = aws_lambda_function.streamer_lambda.arn
  starting_position = "LATEST"
  maximum_retry_attempts = 2
  maximum_record_age_in_seconds = 604800
  bisect_batch_on_function_error = true
}

resource "aws_iam_role" "iam_for_sfn" {
  name = "iam_for_sfn_assume_role-${var.env}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "states.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_for_sfn" {
  name = "iam_for_sfn_main_role-${var.env}"
  role = aws_iam_role.iam_for_sfn.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
            "Effect": "Allow",
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Resource": [
                "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:*"
            ]
        }
    ]
}
EOF
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "inventory-import-${var.env}"
  role_arn = aws_iam_role.iam_for_sfn.arn

  definition = <<EOF
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
              "FunctionName": "${aws_lambda_function.data_lambda.arn}",
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
                      "FunctionName": "${aws_lambda_function.insert_lambda.arn}",
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
                        "Variable": "$.PackageTypeExists",
                        "BooleanEquals": false,
                        "Next": "InsertPackageType"
                      },
                      {
                        "Variable": "$.PackageTypeExists",
                        "BooleanEquals": true,
                        "Next": "SkipPackageTypeCreation"
                      }
                    ]
                  },
                  "InsertPackageType": {
                    "Type": "Task",
                    "Resource": "arn:aws:states:::lambda:invoke",
                    "Parameters": {
                      "FunctionName": "${aws_lambda_function.insert_lambda.arn}",
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
              "FunctionName": "${aws_lambda_function.insert_lambda.arn}",
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
              "FunctionName": "${aws_lambda_function.insert_lambda.arn}",
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
EOF
}