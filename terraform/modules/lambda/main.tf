data "aws_caller_identity" "current" {}

variable "aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Sets the region used in AWS"
}
variable "name" {
    type = string
}
variable "file_location" {
    type = string
}
variable "handler" {
    type = string
}
variable "env_vars" {
    type = map
    default = {}
}
output "arn" {
    value = aws_lambda_function.this.arn
}
resource "aws_lambda_function" "this" {
  filename         = var.file_location
  function_name    = var.name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = filebase64sha256(var.file_location)
  runtime          = "dotnetcore3.1"
  timeout = 30

  environment {
    variables = var.env_vars
  }
}

resource "aws_iam_role" "this" {
  name = "iam_for_lambda-${var.name}"

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


resource "aws_iam_role_policy" "this" {
  name = "iam_for_lambda_main_role-${var.name}"
  role = aws_iam_role.this.id
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