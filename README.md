# My Static Website
A simple static website with CloudFront Route53 S3 Certificate Manager

I used this simple terraform module to create my own static website borsoft.ch

Nothing Special but useful.

How to use it:

* register your public dns in AWS (this automaticlly create the Route53 Zone)
* wait 1/2 hours
* create your Certificate in North Virginia region (the only one CloudFront can use it)
* clone the repo.
* mkdir static-html
* put your html files in there
* eventually modify (maybe you can need different mime_types check in the main.tf)

terraform plan and apply.

# Diagram

![schema](https://raw.githubusercontent.com/giuseppeborgese/borsoft-website/master/diagram.png)


# Example of usage

``` hcl
module "chose-you-a-name-for-your-module" {
  source = "your_directory/borsoft-website/"
  prefix = "something"
  record_name = "www"
  zone_name = "yourdomain.com"
  certificate_arn = "arn:aws:acm:us-east-1:111111111:certificate/xxxxxx-xxx-xxx-xxxx-xxxxxxx"
  s3_bucket_name = "unique_bucket_name"
}

```
