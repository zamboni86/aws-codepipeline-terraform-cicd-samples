#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.
data "aws_ssm_parameter" "github" {
  name = "github-token"
}

locals {
  extra_stages = var.environment == "dev" ? ["destroy"] : []
}

resource "aws_codepipeline" "terraform_pipeline" {

  name     = "${var.project_name}-pipeline"
  role_arn = var.codepipeline_role_arn
  tags     = var.tags

  artifact_store {
    location = var.s3_bucket_name
    type     = "S3"
    encryption_key {
      id   = var.kms_key_arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Download-Source"
      category         = "Source"
      owner            = "ThirdParty"
      version          = "1"
      provider         = "GitHub"
      namespace        = "SourceVariables"
      output_artifacts = ["SourceOutput"]
      run_order        = 1

      configuration = {
        Owner = "zamboni86"
        Repo                 = var.source_repo_name
        Branch           = var.source_repo_branch
        PollForSourceChanges = "true"
        OAuthToken = data.aws_ssm_parameter.github.value
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages

    content {
      name = "Stage-${stage.value["name"]}"
      action {
        category         = stage.value["category"]
        name             = "Action-${stage.value["name"]}"
        owner            = stage.value["owner"]
        provider         = stage.value["provider"]
        input_artifacts  = [stage.value["input_artifacts"]]
        output_artifacts = [stage.value["output_artifacts"]]
        version          = "1"
        run_order        = index(var.stages, stage.value) + 2

        configuration = {
          ProjectName = stage.value["provider"] == "CodeBuild" ? "${var.project_name}-${stage.value["name"]}" : null
        }
      }
    }
  }

  stage {
    name = "verify-plan"

    action {
      name             = "Approval"
      category         = "Approval"
      owner            = "AWS"
      version          = "1"
      provider         = "Manual"
      input_artifacts  = []
      output_artifacts = []
    }
  }

  stage {
    name = "terraform-apply"

    action {
      name             = "apply"
      category         = "Build"
      owner            = "AWS"
      version          = "1"
      provider         = "CodeBuild"
      run_order        = 99
      input_artifacts  = ["PlanOutput"]
      output_artifacts = []

      configuration = {
        ProjectName = "${var.project_name}-apply"
      }
    }
  }
  dynamic "stage" {
    for_each = local.extra_stages

    content {
  
      name = "terraform-destroy"

      action {
        name             = "destroy"
        category         = "Build"
        owner            = "AWS"
        version          = "1"
        provider         = "CodeBuild"
        run_order        = 100
        input_artifacts  = ["PlanOutput"]
        output_artifacts = []

        configuration = {
          ProjectName = "${var.project_name}-destroy"
        }
      }
    }
  }
}