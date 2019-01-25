# Alert Dispatcher

CloudWatch to SNS integration.

# Usage

You need the following:

1. The ARN of the SNS topic used by your CloudWatch alarm for
   notifications.
2. An IAM role allowing the lambda fn to execute Go code
3. A Slack webhook that will be used to push message on your ch

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
make it work straight away.

The value of the `CRITICAL` variable will instruct the dispatcher to
notify everyone in the ch (e.g. @here in the Slack message). The
default behavior is to set this value to *false*.

ugo.matrangolo@gmail.com
Dublin, 2019
