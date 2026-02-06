output "pipeline_name" {
  description = "CodePipeline name"
  value       = module.cicd_pipeline.pipeline_name
}

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = module.cicd_pipeline.pipeline_arn
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = module.cicd_pipeline.codebuild_project_name
}
