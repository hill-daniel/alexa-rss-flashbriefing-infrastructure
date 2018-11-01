variable region {
  default = "eu-central-1"
  description = "the aws region where we want to create the resources"
}

variable profile {
  default = "default"
  description = ""
}

variable lambdaCodeBucket {}
variable lambdaCodeFile {}
variable stage {}
variable feedUrl {}