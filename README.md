# lambda-terraform-demo

## Setup Instructions:
Clone the repo to your local file system. Next ensure that you have installed the AWS CLI and that you have installed Terraform. 
[AWS CLI Install Instructions](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
[Terraform Install Instructions](https://www.terraform.io/downloads.html)
Once you ahve installed these ensure that you have configured your AWS CLI with your key and secret key.


## Terraform Validation and Setup
Change directories into the cloned git repo and run the following command: ```terraform init```
This will install any required packages and dependancies within Terraform to run the tf file. 

Once you've done this you can validate the file syntax by running ```terraform validate```. This will come back blank if the syntax of the file is correct. Next we will run ```terraform plan``` to see what terraform will change. You should see that it will add an IAM policy, and IAM role, 2 Lambda functions, a CloudWatch cron trigger, permissions and association of the cron trigger to the Lambda functions. If this looks good go ahead and run ```terraform apply``` this will execute the resource creation. 


## Removing Terraform Resources 
To remove the stack of lambdas, cloudwatch triggers, and IAM permissions we just created we can run ```terraform destroy```. This will show you a diff of what it will remove and you will be able back out or type yes to continue. 