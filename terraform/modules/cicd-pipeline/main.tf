terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket for Artifacts
resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.service_name}-artifacts-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  rule {
    id     = "delete-old-artifacts"
    status = "Enabled"
    
    expiration {
      days = 30
    }
  }
}

# S3 Bucket for Build Cache
resource "aws_s3_bucket" "build_cache" {
  bucket = "${var.service_name}-build-cache-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket_lifecycle_configuration" "build_cache" {
  bucket = aws_s3_bucket.build_cache.id
  
  rule {
    id     = "delete-old-cache"
    status = "Enabled"
    
    expiration {
      days = 7
    }
  }
}

# SNS Topic for Notifications
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.service_name}-pipeline-notifications"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = var.approval_email
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/${var.service_name}-build"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "test" {
  name              = "/aws/codebuild/${var.service_name}-test"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "integration_test" {
  name              = "/aws/codebuild/${var.service_name}-integration-test"
  retention_in_days = 7
}

# CodeBuild Projects
resource "aws_codebuild_project" "build" {
  name          = "${var.service_name}-build"
  description   = "Build project for ${var.service_name}"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    
    environment_variable {
      name  = "ARTIFACT_BUCKET"
      value = aws_s3_bucket.artifacts.id
    }
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path
  }
  
  cache {
    type     = "S3"
    location = "${aws_s3_bucket.build_cache.id}/build-cache"
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.build.name
    }
  }
}

resource "aws_codebuild_project" "test" {
  name          = "${var.service_name}-test"
  description   = "Test project for ${var.service_name}"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = var.testspec_path
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.test.name
    }
  }
}

resource "aws_codebuild_project" "integration_test" {
  name          = "${var.service_name}-integration-test"
  description   = "Integration test project for ${var.service_name}"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    
    environment_variable {
      name  = "ENVIRONMENT"
      value = "dev"
    }
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = var.integration_testspec_path
  }
  
  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.integration_test.name
    }
  }
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "${var.service_name}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  
  artifact_store {
    location = aws_s3_bucket.artifacts.id
    type     = "S3"
  }
  
  stage {
    name = "Source"
    
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      
      configuration = {
        Owner                = var.github_owner
        Repo                 = var.github_repo
        Branch               = var.github_branch
        OAuthToken           = var.github_token
        PollForSourceChanges = false
      }
    }
  }
  
  stage {
    name = "Build"
    
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
  
  stage {
    name = "Test"
    
    action {
      name            = "UnitTest"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      
      configuration = {
        ProjectName = aws_codebuild_project.test.name
      }
    }
  }
  
  stage {
    name = "DeployDev"
    
    action {
      name            = "TerraformPlan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      
      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan_dev.name
      }
    }
    
    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      run_order       = 2
      
      configuration = {
        ProjectName = aws_codebuild_project.terraform_apply_dev.name
      }
    }
  }
  
  stage {
    name = "IntegrationTest"
    
    action {
      name            = "IntegrationTest"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      
      configuration = {
        ProjectName = aws_codebuild_project.integration_test.name
      }
    }
  }
  
  stage {
    name = "ApprovalForProd"
    
    action {
      name     = "ManualApproval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      
      configuration = {
        NotificationArn = aws_sns_topic.pipeline_notifications.arn
        CustomData      = "Please review dev deployment and approve for production"
      }
    }
  }
  
  stage {
    name = "DeployProd"
    
    action {
      name            = "TerraformPlan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      
      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan_prod.name
      }
    }
    
    action {
      name            = "TerraformApply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      run_order       = 2
      
      configuration = {
        ProjectName = aws_codebuild_project.terraform_apply_prod.name
      }
    }
  }
}

# Terraform Plan/Apply Projects for Dev
resource "aws_codebuild_project" "terraform_plan_dev" {
  name          = "${var.service_name}-terraform-plan-dev"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "terraform/buildspecs/terraform-plan-dev.yml"
  }
}

resource "aws_codebuild_project" "terraform_apply_dev" {
  name          = "${var.service_name}-terraform-apply-dev"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "terraform/buildspecs/terraform-apply-dev.yml"
  }
}

# Terraform Plan/Apply Projects for Prod
resource "aws_codebuild_project" "terraform_plan_prod" {
  name          = "${var.service_name}-terraform-plan-prod"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "terraform/buildspecs/terraform-plan-prod.yml"
  }
}

resource "aws_codebuild_project" "terraform_apply_prod" {
  name          = "${var.service_name}-terraform-apply-prod"
  service_role  = aws_iam_role.codebuild.arn
  
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  
  source {
    type      = "CODEPIPELINE"
    buildspec = "terraform/buildspecs/terraform-apply-prod.yml"
  }
}

# GitHub Webhook
resource "aws_codepipeline_webhook" "github" {
  name            = "${var.service_name}-webhook"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.pipeline.name
  
  authentication_configuration {
    secret_token = var.github_token
  }
  
  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

# Data sources
data "aws_caller_identity" "current" {}

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild" {
  name = "${var.service_name}-codebuild-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

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
          "s3:PutObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/*",
          "${aws_s3_bucket.build_cache.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          aws_s3_bucket.build_cache.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${var.service_name}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*",
          "lambda:*",
          "apigateway:*",
          "dynamodb:*",
          "iam:*",
          "cloudwatch:*",
          "xray:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "${var.service_name}-codepipeline-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  role = aws_iam_role.codepipeline.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}
