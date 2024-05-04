terraform {
  backend "s3" {
    bucket = "zanoni-terraform"
    key    = "dev/aws-codepipeline/terraform.tfstate"
    region = "us-east-1"
  }
}