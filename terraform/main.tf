provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

terraform {
  backend "s3" {
    region = "eu-central-1"
  }
}

module "lambda" {
  source = "./modules/lambda"
  lambdaCodeBucket = "${var.lambdaCodeBucket}"
  lambdaCodeFile = "${var.lambdaCodeFile}"
  stage = "${var.stage}"
  feedUrl = "${var.feedUrl}"
}
