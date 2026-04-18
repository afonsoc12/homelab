variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

variable "records_file" {
  description = "Path to the SOPS-encrypted DNS records file for this zone"
  type        = string
}
