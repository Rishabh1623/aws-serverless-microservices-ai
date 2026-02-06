output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = aws_s3_bucket.artifacts.id
}

output "build_project_name" {
  description = "Name of the CodeBuild build project"
  value       = aws_codebuild_project.build.name
}

output "test_project_name" {
  description = "Name of the CodeBuild test project"
  value       = aws_codebuild_project.test.name
}

output "notification_topic_arn" {
  description = "ARN of the SNS notification topic"
  value       = aws_sns_topic.pipeline_notifications.arn
}

output "pipeline_url" {
  description = "URL to view the pipeline in AWS Console"
  value       = "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.pipeline.name}/view?region=${var.aws_region}"
}
