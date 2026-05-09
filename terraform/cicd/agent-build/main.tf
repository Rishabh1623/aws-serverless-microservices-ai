# AWS CodeBuild project for building Lambda packages
# Production-grade CI/CD for serverless applications

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-955510722779"
    key            = "cicd/agent-build/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket for build artifacts
resource "aws_s3_bucket" "build_artifacts" {
  bucket = "agent-service-build-artifacts-955510722779"
}

resource "aws_s3_bucket_versioning" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "agent-service-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

# IAM policy for CodeBuild
resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.build_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:PublishLayerVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild project
resource "aws_codebuild_project" "agent_build" {
  name          = "agent-service-build"
  description   = "Build Lambda packages with Amazon Linux compatibility"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 15

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.build_artifacts.bucket
    packaging = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/Rishabh1623/aws-serverless-microservices-ai.git"
    git_clone_depth = 1
    buildspec       = "agent-service/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/agent-service"
      stream_name = "build"
    }
  }
}

# Outputs
output "codebuild_project_name" {
  value = aws_codebuild_project.agent_build.name
}

output "artifacts_bucket" {
  value = aws_s3_bucket.build_artifacts.bucket
}

output "build_command" {
  value = "aws codebuild start-build --project-name ${aws_codebuild_project.agent_build.name}"
}
