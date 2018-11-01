# AWS infrastructure 

Uses [Terraform](https://www.terraform.io/) to create AWS infrastructure for an Alexa Flash Briefing Skill.
Code for the Lambda function can be found at [GitHub](https://www.github.com/hill-daniel//alexa-rss-flashbriefing) 
Take a look at the blog post (sorry german only): [RSS Feed mit Alexa Flash Briefing ausliefern](https://blog.codecentric.de/2018/11/rss-feed-mit-alexa-flash-briefing-ausliefern).

Will create the following: 
* IAM role and policies for the execution of the lambda function and the API Gateway
* The lambda function
* API Gateway
 
## Usage
* Adapt backend-config (see first command under usage) to your s3 key and bucket to store terraform state.
* Provide credentials file in your ~/.aws folder and supply the profile name (default is default...) in variables.tf.
* Change dev.tfvars file according to your needs.
* Use in command line in terraform folder:

### Usage (e.g. for dev)
```bash
terraform init -backend-config "key=states/dev/terraform.tfstate" -backend-config "bucket=cc-dh-terraform" -reconfigure
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

## Destroy
```bash
terraform init
terraform destroy -var-file="dev.tfvars"
```