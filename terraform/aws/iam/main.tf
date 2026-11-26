terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.74.0"
    }
  }
}

variable "service_roles" {
  type = map(object({
    service_name = string
    description  = string
    arn          = string
  }))
  sensitive = true
}

resource "aws_iam_service_linked_role" "service" {
  for_each = nonsensitive(toset(keys(var.service_roles)))

  aws_service_name = var.service_roles[each.key].service_name
  description      = var.service_roles[each.key].description

  lifecycle {
    prevent_destroy = true
  }
}
