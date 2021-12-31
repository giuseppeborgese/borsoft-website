provider "aws" {
    region = "us-east-1"
    alias = "virginia"
}

resource "aws_s3_bucket" "website" {
  provider = aws.virginia
  bucket = var.s3_bucket_name

  server_side_encryption_configuration {
     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm     = "AES256"
       }
     }
   }
}

locals {
  upload_directory = "${path.module}/static-html/"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "web" {
  provider = aws.virginia
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

#mime type list https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
variable "mime_types" {
  default = {
    xml   = "text/html"
    htm   = "text/html"
    html  = "text/html"
    css   = "text/css"
    ttf   = "font/ttf"
    js    = "application/javascript"
    map   = "application/javascript"
    json  = "application/json"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
    png   = "image/png"
    gif   = "image/gif"
    txt   = "text/plain"
    pdf   = "application/pdf"
  }
}

resource "aws_s3_bucket_object" "website_files" {
  provider = aws.virginia
  for_each      = fileset(local.upload_directory, "**/*.*")
  bucket        = aws_s3_bucket.website.bucket
  key           = replace(each.value, local.upload_directory, "")
  source        = "${local.upload_directory}${each.value}"
  etag          = filemd5("${local.upload_directory}${each.value}")
  content_type  = lookup(var.mime_types, split(".", each.value)[length(split(".", each.value)) - 1])
}


################# CloudFront ######

data "aws_route53_zone" "selected" {
  name         = var.zone_name
}


resource "aws_route53_record" "web" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.record_name
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.cloudfront.domain_name
    zone_id = aws_cloudfront_distribution.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

locals {
  origin_id_name = "mys3"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "to protect s3 ${var.prefix}"
}


resource "aws_cloudfront_distribution" "cloudfront" {
  provider = aws.virginia
  comment         = "this is a cloudfront distribution in front of an s3 bucket"
  enabled         = true
  is_ipv6_enabled = true

#  logging_config {
#    bucket          = "logs-for-account-963812274078-siemens-cloud.s3.amazonaws.com"
#    include_cookies = false
#    prefix          = "log/Charon/cloudfront"
#  }

  tags = {
    Name        = "${var.prefix}-website"
  }

  aliases             = ["${var.record_name}.${var.zone_name}"]
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.origin_id_name

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2019"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.origin_id_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

}
