data "sops_file" "secrets" {
  source_file = "secrets.sops.yaml"
  input_type  = "yaml"
}

provider "sops" {}

provider "b2" {
  application_key_id = data.sops_file.secrets.data["application_key_id"]
  application_key    = data.sops_file.secrets.data["application_key"]
}

module "buckets" {
  source = "./buckets"
  for_each = toset([
    for k in nonsensitive(keys(data.sops_file.secrets.data)) :
    split(".", k)[1] if startswith(k, "buckets.") && endswith(k, ".name")
  ])

  bucket_name = data.sops_file.secrets.data["buckets.${each.value}.name"]
  bucket_type = "allPrivate"
  encryption  = tobool(data.sops_file.secrets.data["buckets.${each.value}.encryption"])
  file_lock   = tobool(data.sops_file.secrets.data["buckets.${each.value}.file_lock"])
}

resource "b2_application_key" "longhorn" {
  key_name     = "longhorn"
  bucket_ids   = [module.buckets["longhorn"].bucket_id]
  capabilities = ["deleteFiles", "listAllBucketNames", "listBuckets", "listFiles", "readBucketEncryption", "readBucketLogging", "readBucketNotifications", "readBucketReplications", "readBuckets", "readFiles", "shareFiles", "writeBucketEncryption", "writeBucketLogging", "writeBucketNotifications", "writeBucketReplications", "writeFiles"]
}

resource "b2_application_key" "velero" {
  key_name     = "velero"
  bucket_ids   = [module.buckets["velero"].bucket_id]
  capabilities = ["deleteFiles", "listBuckets", "listFiles", "readBucketEncryption", "readBucketLogging", "readBucketNotifications", "readBucketReplications", "readBuckets", "readFiles", "shareFiles", "writeBucketEncryption", "writeBucketLogging", "writeBucketNotifications", "writeBucketReplications", "writeFiles"]
}
