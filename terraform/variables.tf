variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 이름 prefix)"
  type        = string
  default     = "community"
}

# ---- ECR ----

variable "ecr_image_tag_mutability" {
  description = "ECR 이미지 태그 변경 가능 여부"
  type        = string
  default     = "MUTABLE"
}

variable "ecr_scan_on_push" {
  description = "푸시 시 이미지 취약점 스캔 활성화"
  type        = bool
  default     = true
}

# ---- VPC ----

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

# ---- EKS ----

variable "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "community-eks"
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes 버전"
  type        = string
  default     = "1.30"
}

variable "node_instance_type" {
  description = "EKS 노드 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "노드 그룹 기본 수"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "노드 그룹 최소 수"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "노드 그룹 최대 수"
  type        = number
  default     = 4
}

# ---- GitHub Actions ----

variable "github_repo" {
  description = "GitHub Actions OIDC 허용 레포 (형식: owner/repo)"
  type        = string
  default     = "LeeSangheee/community-eks"
}
