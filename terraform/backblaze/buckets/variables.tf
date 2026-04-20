variable "bucket_name" {
  type      = string
  sensitive = true
}

variable "bucket_type" {
  type    = string
  default = "allPrivate"
  validation {
    condition     = contains(["allPublic", "allPrivate"], var.bucket_type)
    error_message = "bucket_type must be allPublic or allPrivate."
  }
}

variable "encryption" {
  type    = bool
  default = false
}

variable "file_lock" {
  type    = bool
  default = false
}
