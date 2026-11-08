resource "b2_bucket" "this" {
  bucket_name = var.bucket_name
  bucket_type = var.bucket_type

  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 30
  }

  # B2 requires encryption for new uploads and no longer accepts "none".
  default_server_side_encryption {
    mode      = "SSE-B2"
    algorithm = "AES256"
  }

  file_lock_configuration {
    is_file_lock_enabled = var.file_lock
  }

  lifecycle {
    prevent_destroy = true
  }
}
