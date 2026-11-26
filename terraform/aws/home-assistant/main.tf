terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "6.74.0" }
    archive = { source = "hashicorp/archive", version = "= 2.8.1" }
  }
}
variable "settings" {
  type      = any
  sensitive = true
}
data "archive_file" "package" {
  type             = "zip"
  source_dir       = "${path.module}/src"
  output_path      = "${path.root}/.build/function.zip"
  output_file_mode = "0644"
}
resource "aws_iam_role" "alexa" {
  name                 = var.settings.role.name
  description          = var.settings.role.description
  path                 = var.settings.role.path
  assume_role_policy   = jsonencode(var.settings.role.trust)
  max_session_duration = var.settings.role.max_session_duration
  tags                 = var.settings.role.tags
  lifecycle { prevent_destroy = true }
}
resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.alexa.name
  policy_arn = var.settings.logging_policy_arn
}
resource "aws_cloudwatch_log_group" "alexa" {
  name              = var.settings.log_group.name
  retention_in_days = var.settings.log_group.retention
  tags              = var.settings.log_group.tags
  lifecycle { prevent_destroy = true }
}
resource "aws_lambda_function" "alexa" {
  filename         = data.archive_file.package.output_path
  source_code_hash = data.archive_file.package.output_base64sha256
  function_name    = var.settings.function.name
  role             = aws_iam_role.alexa.arn
  runtime          = var.settings.function.runtime
  handler          = var.settings.function.handler
  architectures    = var.settings.function.architectures
  memory_size      = var.settings.function.memory
  timeout          = var.settings.function.timeout
  description      = var.settings.function.description
  tags             = var.settings.function.tags
  environment { variables = var.settings.function.environment }
  ephemeral_storage { size = var.settings.function.ephemeral_storage }
  tracing_config { mode = var.settings.function.tracing }
  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.alexa.name
  }
  lifecycle { prevent_destroy = true }
}
resource "aws_lambda_permission" "alexa" {
  statement_id       = var.settings.permission.statement_id
  action             = "lambda:InvokeFunction"
  function_name      = aws_lambda_function.alexa.function_name
  principal          = "alexa-connectedhome.amazon.com"
  event_source_token = var.settings.permission.skill_id
}
