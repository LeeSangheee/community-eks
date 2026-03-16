# ECR 레포지토리: Tomcat WAS 이미지
resource "aws_ecr_repository" "tomcat" {
  name                 = "com-tomcat"
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = {
    Project   = var.project_name
    Component = "was"
  }
}

# ECR 레포지토리: Nginx 웹 이미지
resource "aws_ecr_repository" "nginx" {
  name                 = "com-nginx"
  image_tag_mutability = var.ecr_image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }

  tags = {
    Project   = var.project_name
    Component = "web"
  }
}

# ECR Lifecycle Policy: 이미지 30개 초과 시 오래된 것 자동 삭제
resource "aws_ecr_lifecycle_policy" "tomcat" {
  repository = aws_ecr_repository.tomcat.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최근 30개 이미지만 보관"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "nginx" {
  repository = aws_ecr_repository.nginx.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "최근 30개 이미지만 보관"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# IAM Policy: Kubernetes 노드에서 ECR 이미지 Pull 권한
resource "aws_iam_policy" "ecr_pull" {
  name        = "${var.project_name}-ecr-pull-policy"
  description = "K8s 노드에서 ECR 이미지 Pull 권한"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}
