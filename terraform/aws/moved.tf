moved {
  from = aws_iam_role.alexa
  to   = module.alexa.aws_iam_role.alexa
}

moved {
  from = aws_iam_role_policy_attachment.logging
  to   = module.alexa.aws_iam_role_policy_attachment.logging
}

moved {
  from = aws_cloudwatch_log_group.alexa
  to   = module.alexa.aws_cloudwatch_log_group.alexa
}

moved {
  from = aws_lambda_function.alexa
  to   = module.alexa.aws_lambda_function.alexa
}

moved {
  from = aws_lambda_permission.alexa
  to   = module.alexa.aws_lambda_permission.alexa
}
