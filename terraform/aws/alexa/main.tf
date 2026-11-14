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
  filename         = var.package_path
  source_code_hash = filebase64sha256("${var.package_path}")
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

# This handler only accepts authenticated OAuth token exchanges. It cannot
# execute smart-home directives; the command function remains skill-restricted.
resource "aws_cloudwatch_log_group" "oauth" {
  count             = nonsensitive(try(var.settings.oauth_gateway.enabled, false)) ? 1 : 0
  name              = var.settings.oauth_gateway.log_group
  retention_in_days = var.settings.oauth_gateway.log_retention
  lifecycle { prevent_destroy = true }
}

resource "aws_lambda_function" "oauth" {
  count            = nonsensitive(try(var.settings.oauth_gateway.enabled, false)) ? 1 : 0
  function_name    = var.settings.oauth_gateway.name
  role             = aws_iam_role.alexa.arn
  filename         = var.oauth_package_path
  source_code_hash = filebase64sha256(var.oauth_package_path)
  runtime          = var.settings.function.runtime
  handler          = "oauth_gateway.lambda_handler"
  architectures    = var.settings.function.architectures
  memory_size      = var.settings.oauth_gateway.memory
  timeout          = var.settings.oauth_gateway.timeout
  environment { variables = var.settings.oauth_gateway.environment }
  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.oauth[0].name
  }
  lifecycle { prevent_destroy = true }
}

resource "aws_lambda_function_url" "oauth" {
  count              = nonsensitive(try(var.settings.oauth_gateway.enabled, false)) ? 1 : 0
  function_name      = aws_lambda_function.oauth[0].function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "oauth_url" {
  count                  = nonsensitive(try(var.settings.oauth_gateway.enabled, false)) ? 1 : 0
  statement_id           = "OAuthFunctionURL"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.oauth[0].function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "oauth_url_invoke" {
  count                    = nonsensitive(try(var.settings.oauth_gateway.enabled, false)) ? 1 : 0
  statement_id             = "OAuthInvokeViaURLOnly"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.oauth[0].function_name
  principal                = "*"
  invoked_via_function_url = true
}
