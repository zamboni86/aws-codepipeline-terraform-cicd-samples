project_name       = "tf-project"
environment        = "dev"
source_repo_name   = "terraform-eks-example"
source_repo_branch = "main"
create_new_repo    = false
repo_approvers_arn = "arn:aws:iam::719386486510:user/zanoni.contreras" #Update ARN (IAM Role/User/Group) of Approval Members
create_new_role    = true
#codepipeline_iam_role_name = <Role name> - Use this to specify the role name to be used by codepipeline if the create_new_role flag is set to false.
stage_input = [
  { name = "validate", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "ValidateOutput" },
  { name = "plan", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "ValidateOutput", output_artifacts = "PlanOutput" }
]
build_projects = ["validate", "apply", "plan"]
