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

module "get_data_lambda" {
  source = "./modules/lambda"
  name = "get-inventory-data-${var.env}"
  handler = "GetDataLambda::GetDataLambda.Function::FunctionHandler"
  file_location = "../src/GetDataLambda.zip"
  env_vars = {
    DB_ENDPOINT = "ffthh-sql-server.database.windows.net"
    DATABASE = "WideWorldImporters"
    USER = "ffthh"
    PASSWORD = "ldtime1!"
  }
}

module "insert_inv_lambda" {
  source = "./modules/lambda"
  name = "insert-inventory-${var.env}"
  handler = "UpdateInventoryLambda::UpdateInventoryLambda.Function::FunctionHandler"
  file_location = "../src/UpdateInventoryLambda.zip"
  env_vars = {
    DB_ENDPOINT = "ffthh-sql-server.database.windows.net"
    DATABASE = "WideWorldImporters"
    USER = "ffthh"
    PASSWORD = "ldtime1!"
  }
}

module "stream_purchase_lambda" {
  source = "./modules/lambda"
  name = "stream-purchase-${var.env}"
  handler = "PurchaseStreamLambda::PurchaseStreamLambda.Function::FunctionHandler"
  file_location = "../src/PurchaseStreamLambda.zip"
  env_vars = {
    STEP_FUNCTION_ARN = module.update_inventory_step_func.arn
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
  function_name     = module.stream_purchase_lambda.arn
  starting_position = "LATEST"
  maximum_retry_attempts = 2
  maximum_record_age_in_seconds = 604800
  bisect_batch_on_function_error = true
}


module "update_inventory_step_func" {
  source = "./modules/step_function"
  name = "inventory-import-modularized-${var.env}"
  get_data_lambda_arn = module.get_data_lambda.arn
  insert_inv_lambda_arn = module.insert_inv_lambda.arn
}