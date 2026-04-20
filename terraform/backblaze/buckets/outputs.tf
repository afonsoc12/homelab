output "bucket_id" {
  value = b2_bucket.this.bucket_id
}

output "bucket_name" {
  value     = b2_bucket.this.bucket_name
  sensitive = true
}
