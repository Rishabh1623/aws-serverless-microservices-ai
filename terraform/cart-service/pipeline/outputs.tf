output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = module.cart_service_pipeline.pipeline_name
}

output "pipeline_url" {
  description = "URL to view the pipeline in AWS Console"
  value       = module.cart_service_pipeline.pipeline_url
}

output "artifact_bucket_name" {
  description = "Name of the S3 artifact bucket"
  value       = module.cart_service_pipeline.artifact_bucket_name
}
