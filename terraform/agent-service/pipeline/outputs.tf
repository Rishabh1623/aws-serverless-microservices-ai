output "pipeline_name" {
  description = "CodePipeline name"
  value       = module.cicd_pipeline.pipeline_name
}

output "pipeline_url" {
  description = "CodePipeline console URL"
  value       = module.cicd_pipeline.pipeline_url
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = module.cicd_pipeline.codebuild_project_name
}
