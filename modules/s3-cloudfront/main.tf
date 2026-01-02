# Private S3 bucket for static/media files
resource "aws_s3_bucket" "static" {
  bucket = var.bucket_name

  tags = merge(var.tags, {
    Name        = "${var.project_name}-static"
    Environment = "production"  # optional - add if you use env tags
  })
}

resource "aws_s3_bucket_versioning" "static" {
  bucket = aws_s3_bucket.static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket = aws_s3_bucket.static.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control (modern replacement for OAI)
resource "aws_cloudfront_origin_access_control" "static" {
  name                              = "${var.project_name}-static-oac"
  description                       = "OAC for ${var.project_name} static bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "static" {
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.static.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.static.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} static/media files"
  default_root_object = "index.html"  # change if your entry point is different

  # IMPORTANT: Ensure your ACM cert covers ALL aliases here!
  # Current aliases: static.nevard.dev + nevard.dev
  # But your cert is likely only nevard.dev + www.nevard.dev → add static.nevard.dev to SANs in ACM module!
  aliases = ["static.${var.domain_name}", var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400      # 1 day
    max_ttl                = 31536000   # 1 year
    compress               = true
  }

  price_class = "PriceClass_100"  # Cheapest: US, Canada, Europe, Israel

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Removed depends_on = [var.acm_validation_dependency] — it likely doesn't exist
  # If cert is still Pending → wait 5-10 min after apply fails, then re-apply
  # CloudFront creation takes ~10-30 min to reach "Deployed" status anyway

  # Optional: prevents accidental delete of distribution on terraform destroy
  # retain_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-cloudfront-static"
    Environment = "production"  # optional
  })
}

# Bucket policy: Allow only CloudFront (via OAC) to read objects
data "aws_iam_policy_document" "static_bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.static.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.static_bucket_policy.json
}