resource "aws_iam_role" "alexa" {
  name                 = local.settings.role.name
  description          = local.settings.role.description
  path                 = local.settings.role.path
  assume_role_policy   = jsonencode(local.settings.role.trust)
  max_session_duration = local.settings.role.max_session_duration
  tags                 = local.settings.role.tags
  lifecycle { prevent_destroy = true }
}
resource "aws_iam_role_policy_attachment" "logging" {
  role       = aws_iam_role.alexa.name
  policy_arn = local.settings.logging_policy_arn
}
resource "aws_cloudwatch_log_group" "alexa" {
  name              = local.settings.log_group.name
  retention_in_days = local.settings.log_group.retention
  tags              = local.settings.log_group.tags
  lifecycle { prevent_destroy = true }
}
resource "aws_lambda_function" "alexa" {
  filename         = local.package_path
  source_code_hash = filebase64sha256("${local.package_path}")
  function_name    = local.settings.function.name
  role             = aws_iam_role.alexa.arn
  runtime          = local.settings.function.runtime
  handler          = local.settings.function.handler
  architectures    = local.settings.function.architectures
  memory_size      = local.settings.function.memory
  timeout          = local.settings.function.timeout
  description      = local.settings.function.description
  tags             = local.settings.function.tags
  environment { variables = local.settings.function.environment }
  ephemeral_storage { size = local.settings.function.ephemeral_storage }
  tracing_config { mode = local.settings.function.tracing }
  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.alexa.name
  }
  lifecycle { prevent_destroy = true }
}
resource "aws_lambda_permission" "alexa" {
  statement_id       = local.settings.permission.statement_id
  action             = "lambda:InvokeFunction"
  function_name      = aws_lambda_function.alexa.function_name
  principal          = "alexa-connectedhome.amazon.com"
  event_source_token = local.settings.permission.skill_id
}

# This handler only accepts authenticated OAuth token exchanges. It cannot
# execute smart-home directives; the command function remains skill-restricted.
resource "aws_cloudwatch_log_group" "oauth" {
  count             = nonsensitive(try(local.settings.oauth_gateway.enabled, false)) ? 1 : 0
  name              = local.settings.oauth_gateway.log_group
  retention_in_days = local.settings.oauth_gateway.log_retention
  lifecycle { prevent_destroy = true }
}

resource "aws_lambda_function" "oauth" {
  count            = nonsensitive(try(local.settings.oauth_gateway.enabled, false)) ? 1 : 0
  function_name    = local.settings.oauth_gateway.name
  role             = aws_iam_role.alexa.arn
  filename         = local.oauth_package_path
  source_code_hash = filebase64sha256(local.oauth_package_path)
  runtime          = local.settings.function.runtime
  handler          = "oauth_gateway.lambda_handler"
  architectures    = local.settings.function.architectures
  memory_size      = local.settings.oauth_gateway.memory
  timeout          = local.settings.oauth_gateway.timeout
  environment { variables = local.settings.oauth_gateway.environment }
  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.oauth[0].name
  }
  lifecycle { prevent_destroy = true }
}

resource "aws_lambda_function_url" "oauth" {
  count              = nonsensitive(try(local.settings.oauth_gateway.enabled, false)) ? 1 : 0
  function_name      = aws_lambda_function.oauth[0].function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "oauth_url" {
  count                  = nonsensitive(try(local.settings.oauth_gateway.enabled, false)) ? 1 : 0
  statement_id           = "OAuthFunctionURL"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.oauth[0].function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "oauth_url_invoke" {
  count                    = nonsensitive(try(local.settings.oauth_gateway.enabled, false)) ? 1 : 0
  statement_id             = "OAuthInvokeViaURLOnly"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.oauth[0].function_name
  principal                = "*"
  invoked_via_function_url = true
}
