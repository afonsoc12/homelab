resource "aws_iam_service_linked_role" "service" {
  for_each = nonsensitive(toset(keys(var.service_roles)))

  aws_service_name = var.service_roles[each.key].service_name
  description      = var.service_roles[each.key].description

  lifecycle {
    prevent_destroy = true
  }
}
