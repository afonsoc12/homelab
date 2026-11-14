variable "service_roles" {
  type = map(object({
    service_name = string
    description  = string
    arn          = string
  }))
  sensitive = true
}
