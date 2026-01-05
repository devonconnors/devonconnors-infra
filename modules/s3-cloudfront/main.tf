# Private S3 bucket for private media (user-uploaded originals)
resource "aws_s3_bucket" "private" {
  bucket = "${var.project_name}-private-storage"

  lifecycle {
    ignore_changes = [bucket]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-private-media"
    Environment = "production"  # optional - add if you use env tags
  })
}

resource "aws_s3_bucket_versioning" "private" {
  bucket = aws_s3_bucket.private.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "private" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy for private: Allow app role full access (read/write for Django/Celery)
data "aws_iam_policy_document" "private_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [var.app_role_arn]
    }

    actions   = ["s3:*"]
    resources = ["${aws_s3_bucket.private.arn}", "${aws_s3_bucket.private.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "private" {
  bucket = aws_s3_bucket.private.id
  policy = data.aws_iam_policy_document.private_bucket_policy.json
}

# Public S3 bucket for static/public media (processed/resized images served via CDN)
resource "aws_s3_bucket" "public" {
  bucket = "${var.project_name}-public-storage"

  lifecycle {
    ignore_changes = [bucket]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-public-static-media"
    Environment = "production"  # optional - add if you use env tags
  })
}

resource "aws_s3_bucket_versioning" "public" {
  bucket = aws_s3_bucket.public.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public" {
  bucket = aws_s3_bucket.public.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control (modern replacement for OAI) - for public bucket only
resource "aws_cloudfront_origin_access_control" "public" {
  name                              = "${var.project_name}-public-oac"
  description                       = "OAC for ${var.project_name} public bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution - for public bucket only
resource "aws_cloudfront_distribution" "public" {
  origin {
    domain_name              = aws_s3_bucket.public.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.public.bucket}"
    origin_access_control_id = aws_cloudfront_origin_access_control.public.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} public static/media files"
  default_root_object = "index.html"  # change if your entry point is different

  # IMPORTANT: Ensure your ACM cert covers ALL aliases here!
  # e.g., add static.devonconnors.co.uk to SANs in ACM module!
  aliases = ["static.${var.domain_name}", var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.public.bucket}"

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

  # If cert is still Pending → wait 5-10 min after apply fails, then re-apply
  # CloudFront creation takes ~10-30 min to reach "Deployed" status anyway

  # Optional: prevents accidental delete of distribution on terraform destroy
  # retain_on_delete = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-cloudfront-public"
    Environment = "production"  # optional
  })
}

# Bucket policy for public: Allow CloudFront to read + app role to read/write (for resized uploads)
data "aws_iam_policy_document" "public_bucket_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.public.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.public.arn]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = [var.app_role_arn]
    }

    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject", "s3:PutObjectAcl"]  # Adjust as needed for your app
    resources = ["${aws_s3_bucket.public.arn}", "${aws_s3_bucket.public.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.public.id
  policy = data.aws_iam_policy_document.public_bucket_policy.json
}