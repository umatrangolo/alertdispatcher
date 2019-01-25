# Alert Dispatcher

AWS Lambda fn that forwards CloudWatch alerts delivered throught SNS
events.

# Usage

You need the following:

1. The ARN of the SNS topic that will be used as a trigger of the
   lambda fn
2. An IAM role allowing the lambda fn to execute Go code
3. A Slack webhook that will be used to push message

To install the fn the first time you can use (e.g.):

```
SLACK_CH_WEBHOOK=https://hooks.slack.com/services/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 \
AWS_SNS_TOPIC_ARN=arn:aws:sns:us-east-1:195056086334:ratpack-alerts \
AWS_PROFILE=hbc-common \
AWS_IAM_ROLE=arn:aws:iam::195056086334:role/golambda-role \
AWS_REGION=us-east-1 \
ALERT_NAME=prometheus-hbc-common-dev-k8s \
CRITICAL=true \
make install
```

The above will compile/pack the Go executable to run in AWS and ship
it to the AWS Lambda execution environment configuring everything to
make it work.

ugo.matrangolo@gmail.com
Dublin, 2019
