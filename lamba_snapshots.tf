#Sets provider to AWS and default region to us-west-2, expects you have AWS CLI installed and configured with keys
provider "aws" {
  region     = "us-west-2"
}

#Creates IAM Policy 
resource "aws_iam_role_policy" "lambda_ebs_snapshot_policy" {
  name = "lambda_ebs_snapshot_policy"
  role = "${aws_iam_role.lambda_ebs_snapshot.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:CreateTags*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Stmt1446328514000",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:ModifySnapshotAttribute",
                "ec2:ResetSnapshotAttribute",
                "ec2:DeleteSnapshot"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
#Creates role and attaches policy
resource "aws_iam_role" "lambda_ebs_snapshot" {
  name = "lambda_ebs_snapshot"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

#Creates daily cron CloudWatch Event Rule
resource "aws_cloudwatch_event_rule" "every_day" {
    name = "every_day"
    description = "Fires every day"
    schedule_expression = "rate(1 day)"
}

#Creates EBS Auto Snapshot Lambda Job
resource "aws_lambda_function" "ebs_autosnapshot" {
  filename         = "ebs_autosnapshot.zip"
  function_name    = "ebs_autosnapshot"
  role             = "${aws_iam_role.lambda_ebs_snapshot.arn}"
  handler          = "ebs_autosnapshot.lambda_handler"
  source_code_hash = "${base64sha256(file("ebs_autosnapshot.zip"))}"
  runtime          = "python2.7"
  memory_size      = "512"
  timeout          = "300"
}

#Creates EBS Snapshot Rotation Lambda Job
resource "aws_lambda_function" "ebs_manage_snapshot" {
  filename         = "ebs_manage_snapshot.zip"
  function_name    = "ebs_manage_snapshot"
  role             = "${aws_iam_role.lambda_ebs_snapshot.arn}"
  handler          = "ebs_manage_snapshot.lambda_handler"
  source_code_hash = "${base64sha256(file("ebs_manage_snapshot.zip"))}"
  runtime          = "python2.7"
  memory_size      = "512"
  timeout          = "300"
}

#Sets permission to call EBS Auto Snapshot from Cloud Watch Event
resource "aws_lambda_permission" "allow_cloudwatch_to_call_ebs_autosnapshot" {
    statement_id = "AllowExecutionFromCloudWatch-call_ebs_autosnapshot"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ebs_autosnapshot.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_day.arn}"
}

#Sets permission to call EBS Snaphot Rotation from Cloud Watch Event
resource "aws_lambda_permission" "allow_cloudwatch_to_call_ebs_manage_snapshot" {
    statement_id = "AllowExecutionFromCloudWatch-call_ebs_manage_snapshot"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.ebs_manage_snapshot.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_day.arn}"
}

#Target CW Event to Lambda 
resource "aws_cloudwatch_event_target" "ebs_autosnapshot_every_day" {
    rule = "${aws_cloudwatch_event_rule.every_day.name}"
    target_id = "ebs_autosnapshot"
    arn = "${aws_lambda_function.ebs_autosnapshot.arn}"
}

#Target CW Event to Lambda 
resource "aws_cloudwatch_event_target" "ebs_manage_snapshot_every_day" {
    rule = "${aws_cloudwatch_event_rule.every_day.name}"
    target_id = "ebs_manage_snapshot"
    arn = "${aws_lambda_function.ebs_manage_snapshot.arn}"
}