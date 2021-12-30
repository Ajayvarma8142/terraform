
provider "aws" {
  region = "us-east-2"
}

resource "aws_sns_topic" "topic" {
  name            = "qentelli"

}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "ajay.renati@qentelli.com"
}


module "step_function" {
  source = "terraform-aws-modules/step-functions/aws"

  name       = "HelloWorld"
  definition = <<EOF
{
  "Comment": "A Hello World example of the Amazon States Language using Pass states",
  "StartAt": "Hello",
  "States": {
    "Hello": {
      "Type": "Pass",
      "Result": "Hello",
      "Next": "World"
    },
    "World": {
      "Type": "Pass",
      "Result": "World",
      "End": true
    }
  }
}
EOF
}


module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  bus_name = "qen"

  rules = {
    status = {
      description   = "Capture all data"
      event_pattern = jsonencode({
  "source": ["aws.states"],
  "detail-type": ["Step Functions Execution Status Change"],
  "detail": {
    "status": ["SUCCEEDED", "FAILED"],
    "stateMachineArn": ["arn:aws:states:us-east-2:535199517722:stateMachine:HelloWorld", ""]
  }
})
      enabled       = true
    }
  }


   targets = {
    status = [
      {
        name            = "send-orders-to-sns"
        arn             = "arn:aws:sns:us-east-2:535199517722:qentelli"
		topic_arn       = aws_sns_topic.topic.arn
		
      }
    ]
	}
  
  
    tags = {
    Name = "qen"
  }
  }
 




