# ============================================================
# S3 - Loki 로그 저장소
# ============================================================
resource "aws_s3_bucket" "loki" {
  bucket = "${var.project_name}-loki-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project   = var.project_name
    Component = "monitoring"
  }
}

resource "aws_s3_bucket_versioning" "loki" {
  bucket = aws_s3_bucket.loki.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}
    expiration {
      days = 30
    }
  }
}

# ============================================================
# S3 - Tempo 트레이스 저장소
# ============================================================
resource "aws_s3_bucket" "tempo" {
  bucket = "${var.project_name}-tempo-traces-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project   = var.project_name
    Component = "monitoring"
  }
}

resource "aws_s3_bucket_versioning" "tempo" {
  bucket = aws_s3_bucket.tempo.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tempo" {
  bucket = aws_s3_bucket.tempo.id

  rule {
    id     = "expire-old-traces"
    status = "Enabled"
    filter {}
    expiration {
      days = 7
    }
  }
}

# ============================================================
# IRSA - Loki가 S3에 읽기/쓰기할 권한
# ============================================================
resource "aws_iam_role" "loki" {
  name = "${var.project_name}-loki-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:monitoring:loki"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_policy" "loki_s3" {
  name = "${var.project_name}-loki-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.loki.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.loki.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "loki_s3" {
  role       = aws_iam_role.loki.name
  policy_arn = aws_iam_policy.loki_s3.arn
}

# ============================================================
# IRSA - Tempo가 S3에 읽기/쓰기할 권한
# ============================================================
resource "aws_iam_role" "tempo" {
  name = "${var.project_name}-tempo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:monitoring:tempo"
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = { Project = var.project_name }
}

resource "aws_iam_policy" "tempo_s3" {
  name = "${var.project_name}-tempo-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.tempo.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.tempo.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tempo_s3" {
  role       = aws_iam_role.tempo.name
  policy_arn = aws_iam_policy.tempo_s3.arn
}
