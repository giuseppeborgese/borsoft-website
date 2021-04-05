variable "prefix" {
  description = ""
}

variable "record_name" {
  description = "something like privates3"
}

variable "zone_name" {
  description = "something like borsoft.ch the zone id will be estracted and the record will be composed with that name"
}

variable "certificate_arn" {
  description = "aws certificate arn"
}

variable "s3_bucket_name" {
  description = "s3 bucket name"
}
