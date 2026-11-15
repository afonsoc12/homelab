moved {
  from = module.alexa.aws_iam_role.alexa
  to   = aws_iam_role.alexa
}

moved {
  from = module.alexa.aws_iam_role_policy_attachment.logging
  to   = aws_iam_role_policy_attachment.logging
}

moved {
  from = module.alexa.aws_cloudwatch_log_group.alexa
  to   = aws_cloudwatch_log_group.alexa
}

moved {
  from = module.alexa.aws_lambda_function.alexa
  to   = aws_lambda_function.alexa
}

moved {
  from = module.alexa.aws_lambda_permission.alexa
  to   = aws_lambda_permission.alexa
}
