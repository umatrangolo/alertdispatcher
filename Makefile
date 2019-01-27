ifeq ($(CRITICAL), true)
	LEVEL 	= critical
else
	LEVEL 	= warning
endif

CRITICAL 	?= false
LAMBDA_NAME 	= alertdispatcher-$(SLACK_CH_NAME)-$(LEVEL)

help:
	@echo $(DIRTY)
	@echo   "Available targets:"
	@echo   "\thelp\t- Prints this help"
	@echo 	"\tinstall\t- Builds, zips and installs the λ fn"
	@echo	"\tupdate\t- Updates the λ fn"
	@echo	"\tsubscribe\t- Subscribes the λ fn to a target topic"

build:
	@echo ">> Building λ fn"
	GOOS=linux go build alertdispatcher.go

zip:
	@echo ">> Packing λ fn"
	mv ./alertdispatcher ./$(LAMBDA_NAME)
	zip $(LAMBDA_NAME).zip ./$(LAMBDA_NAME)

cleanup:
	@echo ">> Cleaning up"
	rm $(LAMBDA_NAME).zip
	rm ./$(LAMBDA_NAME)

aws-install-fn:
	aws 	--profile=$(AWS_PROFILE) lambda create-function \
		--region $(AWS_REGION) \
		--function-name $(LAMBDA_NAME) \
		--memory 128 \
		--role $(AWS_IAM_ROLE) \
		--runtime go1.x \
		--zip-file fileb://./$(LAMBDA_NAME).zip \
		--handler $(LAMBDA_NAME) \
		--environment "Variables={SLACK_CH=$(SLACK_CH_NAME),WEBHOOK=$(SLACK_CH_WEBHOOK),CRITICAL=$(CRITICAL)}"

aws-update-fn:
	aws 	--profile=$(AWS_PROFILE) lambda update-function-code \
		--region $(AWS_REGION) \
		--function-name $(LAMBDA_NAME) \
		--zip-file fileb://./$(LAMBDA_NAME).zip

aws-subscribe-sns:
	@echo 	">> Subscribing to $(AWS_SNS_TOPIC_ARN) with $(level) level"
	aws 	--profile=$(AWS_PROFILE) sns subscribe \
		--topic-arn $(AWS_SNS_TOPIC_ARN) \
		--protocol lambda \
		--notification-endpoint \
			$(shell aws 	--profile=$(AWS_PROFILE) lambda get-function \
					--function-name $(LAMBDA_NAME) \
					--query Configuration.FunctionArn | sed 's/"//g')

aws-test-integration:
	aws 	--profile=$(AWS_PROFILE) sns publish \
		--topic-arn $(AWS_SNS_TOPIC_ARN) \
		--message "{\"AlarmName\":\"alertdispatcher-test-alert\",\"AlarmDescription\":\"Alertdisparcher has been installed\",\"NewStateValue\":\"INSTALLED\"}"
	@echo ">> Sending test alert. You should see a message in your Slack ch now"

aws-lambda-invoke-sns:
	@echo ">> Allowing SNS to invoke λ function"
	aws 	--profile=$(AWS_PROFILE) lambda add-permission \
		--function-name $(LAMBDA_NAME) \
		--statement-id $(LAMBDA_NAME)-invoke-stmt \
		--action "lambda:InvokeFunction" \
		--principal sns.amazonaws.com \
		--source-arn $(AWS_SNS_TOPIC_ARN)

install: build zip aws-install-fn cleanup
	@echo ">> λ function created"

update: build zip aws-update-fn cleanup
	@echo ">> λ function updated"

subscribe: aws-subscribe-sns aws-lambda-invoke-sns aws-test-integration
	@echo ">> λ function subscribed to topic"
