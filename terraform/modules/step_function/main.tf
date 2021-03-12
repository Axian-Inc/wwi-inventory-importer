data "aws_caller_identity" "current" {}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Sets the region used in AWS"
}
variable "name" {
    type = string
}
variable "insert_inv_lambda_arn" {
    type = string
}
variable "get_data_lambda_arn" {
    type = string
}

output "arn" {
    value = aws_sfn_state_machine.this.arn
}

resource "aws_iam_role" "this" {
  name = "iam_for_sfn_assume_role-${var.name}"

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

resource "aws_iam_role_policy" "this" {
  name = "iam_for_sfn_main_role-${var.name}"
  role = aws_iam_role.this.id
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

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.this.arn

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
              "FunctionName": "${var.get_data_lambda_arn}",
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
                      "FunctionName": "${var.insert_inv_lambda_arn}",
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
                      "FunctionName": "${var.insert_inv_lambda_arn}",
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
              "FunctionName": "${var.insert_inv_lambda_arn}",
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
              "FunctionName": "${var.insert_inv_lambda_arn}",
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