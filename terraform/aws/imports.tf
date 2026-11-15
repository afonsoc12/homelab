import {
  to = aws_iam_role.alexa
  id = local.settings.role.name
}
import {
  to = aws_iam_role_policy_attachment.logging
  id = "${local.settings.role.name}/${local.settings.logging_policy_arn}"
}
import {
  to = aws_cloudwatch_log_group.alexa
  id = local.settings.log_group.name
}
import {
  to = aws_lambda_function.alexa
  id = local.settings.function.name
}
import {
  to = aws_lambda_permission.alexa
  id = "${local.settings.function.name}/${local.settings.permission.statement_id}"
}

import {
  for_each = nonsensitive(toset(keys(local.settings.service_roles)))
  to       = module.iam.aws_iam_service_linked_role.service[each.key]
  id       = local.settings.service_roles[each.key].arn
}

import {
  to = restapi_object.home_assistant_manifest
  id = local.paths.home_assistant_manifest
}
import {
  to = restapi_object.home_assistant_linking
  id = local.paths.home_assistant_linking
}
import {
  to = restapi_object.music_assistant_manifest
  id = local.paths.music_assistant_manifest
}
