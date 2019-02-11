# Alert Dispatcher

CloudWatch to Slack integration.

## How it works

There are plenty of examples all over the Internet but the loop is
always the same:

          +---+   +----+   +--+      +------+
          |CW |-->|SNS |-->|λ |--..->|Slack |
          +---+   +----+   +--+      +------+

On an alert triggered by a failing rule on CW an SNS topic gets
notified that then invokes a λ fn. This fn is the one that parses the
alert event and forwards it to the target Slack ch.

## Usage

The installation is fully automated: you won't need to fiddle with any
AWS console. However, we need the following to pipe everything
together:

A `Makefile` is provided that automates everything.

### Install

To install the λ fn you need to run the provided `Makefile` with the
following:

```shell
AWS_PROFILE=default\
AWS_REGION=us-east-1\
AWS_IAM_ROLE=arn:aws:iam::xxxxxxxxxxx:role/golambda-role\
SLACK_CH_WEBHOOK=https://hooks.slack.com/services/AAAAAAAA/BBBBBBBBBB/123456789abcde\
FN_NAME=my-critical-alert\
NOTIFY=true
make install
```

where:

| Key | Description |
|-----|-------------|
| SLACK_CH_WEBHOOK | [Incoming webhook](https://api.slack.com/incoming-webhooks) for you Slack ch |
| AWS_[PROFILE,REGION] | Amazon Credentials profile and region to work with |
| FN_NAME | The name of the λ fn |
| AWS_IAM_ROLE | The IAM role the λ fn has to use to execute |
| NOTIFY | If set to *true* it will notify everyone in the ch (e.g. critical alerts that have to be sorted out quickly) |

The above will compile/pack the Go executable to run in AWS and ship
it to the AWS Lambda execution environment configuring everything to
make it work straight away.

### Update

After initial installation you can update the λ code with the `update`
command using the same variables as in the *Install* section.

### Subscribe

To subscribe the λ fn to a SNS topic you can use the following and
start forwarding the alerts coming out from it to your Slack ch:

```shell
AWS_PROFILE=hbc-common\
AWS_REGION=us-east-1\
AWS_SNS_TOPIC_ARN=arn:aws:sns:us-east-1:123456564343:not-important-alerts\
FN_NAME=my-not-important-alert
make subscribe
```

where:

| Key | Description |
|-----|-------------|
| AWS_[PROFILE,REGION] | Amazon Credentials profile and region to work with |
| FN_NAME | The name of the λ fn |
| AWS_SNS_TOPIC_ARN | This is the ARN of the SNS topic that is configured as notification point of the CW alert |

This will subscribe and install all the needed permissions to make the
fn listen to the target topic and forward all the alarms.

>Make sure you have two actions on your CW alert: one to trigger the
>alert (in `ALARM` state ) and one to clear it off (when in `OK`
>state). The fn will infer what to do from the state of the SNS
>message it will get.

## Best Practices

Some thoughts that worked for me but won't necessarily work for
you. Worth mentions them here anyway.

### Notifications

From my experience you want a setup where you have two kind of alerts:
critical and non critical. For the first one you want to be
paged/notified to act quickly while the second ones could wait some
time before being addressed.

To impl this scenario you will need two SNS topics:
`my-alerts-critical` and `my-alerts` subscribed by two different λ
fns: the one subscribed to the `critical` topic will be configured
with `NOTIFY=true` to allow it to page everyone on the Slack ch.

### What to send

You def need to have two actions on your CW dashboard for any alert:
one that signals when the alert is ON (in `ALARM` state) and the other
to clear it off (when in `OK` state). Wout this second one once an
alert has been triggered there will be nothing to clear it.
