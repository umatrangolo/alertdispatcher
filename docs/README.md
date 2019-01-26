# Alert Dispatcher

CloudWatch to Slack integration.

## How it works

There are plenty of examples all over the Internet but the loop is
always the same:

          +---+   +----+   +--+      +------+
          |CW |---|SNS |---|λ |--..--|Slack |
          +---+   +----+   +--+      +------+

On an alert triggered by a failing rule on CW an SNS topic gets
notified that then invokes a λ fn. This fn is the one that parsed the
alert event and forwards it to the target Slack ch.

## Usage

The installation is fully automated: you won't need to fiddle with any
AWS console. However, we need the following to pipe everything
together:

| What | Description |
|------|-------------|
| *SNS Topic ARN* | This is the ARN of the SNS topic that is configured as notification point in the CW alert configuration |
| *IAM Role* | An IAM role with a policy that will allow our SNS topic to invoke our λ fn |
| *Slack Ch Webhook* | You need to create an [incoming webhook](https://api.slack.com/incoming-webhooks) to allow the λ fn to push messages in the ch |

A `Makefile` is provided that automates everything. For example,
assuming we have all the above we can install the function with:

```shell
SLACK_CH_WEBHOOK=https://hooks.slack.com/services/xxxxx/yyyyyyy/zzzzzzzzzzzzzzzzzz \
AWS_SNS_TOPIC_ARN=arn:aws:sns:us-east-1:aaaaaaaaaaaa:foo-alerts \
AWS_PROFILE=default \
AWS_IAM_ROLE=arn:aws:iam::xxxxxxxxxxxxx:role/golambda-role \
AWS_REGION=us-east-1 \
ALERT_NAME=prometheus-hbc-common-dev-k8s \
CRITICAL=true \
make install
```

The above will compile/pack the Go executable to run in AWS and ship
it to the AWS Lambda execution environment configuring everything to
make it work straight away.

Once installed the fn can be updated using the same command just
invoking the `update` target.

### Slack notification

By default the dispatcher will try to be as discrete as possible by
not trying to notify people in the ch. However, for critical alerts is
best to bring to attention what just happened to most of the
people. The lambda fn can be configured to notify everyone in the ch
using the *@here* Slack cmd; this will pop up a notification to people
in the ch.

To properly configure the level of needed notification the parameter
`CRITICAL` is used; putting it to `true` will make the the dispatcher
to notify everyone. The default behavior is to just push the alert in
the ch wout any notification.

ugo.matrangolo@gmail.com
Dublin, 2019
