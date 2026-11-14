import {
  to = module.alexa.aws_iam_role.alexa
  id = local.settings.role.name
}
import {
  to = module.alexa.aws_iam_role_policy_attachment.logging
  id = "${local.settings.role.name}/${local.settings.logging_policy_arn}"
}
import {
  to = module.alexa.aws_cloudwatch_log_group.alexa
  id = local.settings.log_group.name
}
import {
  to = module.alexa.aws_lambda_function.alexa
  id = local.settings.function.name
}
import {
  to = module.alexa.aws_lambda_permission.alexa
  id = "${local.settings.function.name}/${local.settings.permission.statement_id}"
}

import {
  for_each = nonsensitive(toset(keys(local.settings.service_roles)))
  to       = module.iam.aws_iam_service_linked_role.service[each.key]
  id       = local.settings.service_roles[each.key].arn
}
