help:
	@echo $(DIRTY)
	@echo   "Available targets:"
	@echo   "\thelp\t- Prints this help"
	@echo 	"\tinstall\t- Builds, zips and installs the λ fn"
	@echo	"\tupdate\t- Updates the λ fn"

build:
	@echo ">> Building λ fn"
	GOOS=linux go build alertdispatcher.go

zip:
	@echo ">> Packing λ fn"
	mv ./alertdispatcher ./alertdispatcher-$(ALERT_NAME)
	zip alertdispatcher-$(ALERT_NAME).zip ./alertdispatcher-$(ALERT_NAME)

cleanup:
	@echo ">> Cleaning up"
	rm alertdispatcher-$(ALERT_NAME).zip
	rm ./alertdispatcher-$(ALERT_NAME)

aws-install-fn:
	aws --profile=$(AWS_PROFILE) lambda create-function --region $(AWS_REGION) --function-name alertdispatcher-$(ALERT_NAME) --memory 128 --role $(AWS_IAM_ROLE) --runtime go1.x --zip-file fileb://./alertdispatcher-$(ALERT_NAME).zip --handler alertdispatcher-$(ALERT_NAME) --environment "Variables={WEBHOOK=$(SLACK_CH_WEBHOOK),CRITICAL=$(CRITICAL)}"

aws-update-fn:
	aws --profile=$(AWS_PROFILE) lambda update-function-code --region $(AWS_REGION) --function-name $(ALERT_NAME) --zip-file fileb://./alertdispatcher.zip

aws-subscribe-sns:
	@echo ">> Subscribing λ function to SNS topic"
	aws --profile=$(AWS_PROFILE) sns subscribe --topic-arn $(AWS_SNS_TOPIC_ARN) --protocol lambda --notification-endpoint $(shell aws --profile=hbc-common lambda get-function --function-name alertdispatcher-$(ALERT_NAME) --query Configuration.FunctionArn | sed 's/"//g')

aws-lambda-invoke-sns:
	@echo ">> Allowing SNS to invoke λ function"
	aws --profile=$(AWS_PROFILE) lambda add-permission --function-name alertdispatcher-$(ALERT_NAME) --statement-id alertdispatcher-$(ALERT_NAME)-invoke-stmt --action "lambda:InvokeFunction" --principal sns.amazonaws.com --source-arn $(AWS_SNS_TOPIC_ARN)

install: build zip aws-install-fn cleanup aws-subscribe-sns aws-lambda-invoke-sns
	@echo ">> λ function created"

update: build zip aws-update-fn cleanup
	@echo ">> λ function updated"
