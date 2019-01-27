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
	mv ./alertdispatcher ./alertdispatcher-$(SLACK_CH_NAME)
	zip alertdispatcher-$(SLACK_CH_NAME).zip ./alertdispatcher-$(SLACK_CH_NAME)

cleanup:
	@echo ">> Cleaning up"
	rm alertdispatcher-$(SLACK_CH_NAME).zip
	rm ./alertdispatcher-$(SLACK_CH_NAME)

aws-install-fn:
ifeq ($(CRITICAL), true)
	aws 	--profile=$(AWS_PROFILE) lambda create-function \
		--region $(AWS_REGION) \
		--function-name alertdispatcher-$(SLACK_CH_NAME)-critical \
		--memory 128 \
		 --role $(AWS_IAM_ROLE) \
		 --runtime go1.x \
		 --zip-file fileb://./alertdispatcher-$(SLACK_CH_NAME).zip \
		 --handler alertdispatcher-$(SLACK_CH_NAME)-critical \
		 --environment "Variables={SLACK_CH=$(SLACK_CH_NAME),WEBHOOK=$(SLACK_CH_WEBHOOK),CRITICAL=true}"
else
	aws	--profile=$(AWS_PROFILE) lambda create-function \
		--region $(AWS_REGION) \
		--function-name alertdispatcher-$(SLACK_CH_NAME)-warning \
		--memory 128 \
		--role $(AWS_IAM_ROLE) \
		--runtime go1.x \
		--zip-file fileb://./alertdispatcher-$(SLACK_CH_NAME).zip \
		--handler alertdispatcher-$(SLACK_CH_NAME)-warning \
		--environment "Variables={SLACK_CH=$(SLACK_CH_NAME),WEBHOOK=$(SLACK_CH_WEBHOOK),CRITICAL=false}"
endif

aws-update-fn:
	aws 	--profile=$(AWS_PROFILE) lambda update-function-code \
		--region $(AWS_REGION) \
		--function-name alertdispatcher-$(SLACK_CH_NAME) \
		--zip-file fileb://./alertdispatcher-$(SLACK_CH_NAME).zip

aws-subscribe-sns:
	@echo 	">> Subscribing to $(AWS_SNS_TOPIC_ARN) with $(level) level"
ifeq ($(CRITICAL), true)
	aws 	--profile=$(AWS_PROFILE) sns subscribe \
		--topic-arn $(AWS_SNS_TOPIC_ARN) \
		--protocol lambda \
		--notification-endpoint \
			$(shell aws 	--profile=$(AWS_PROFILE) lambda get-function \
					--function-name alertdispatcher-$(SLACK_CH_NAME)-critical \
					--query Configuration.FunctionArn | sed 's/"//g')
else
	aws 	--profile=$(AWS_PROFILE) sns subscribe \
		--topic-arn $(AWS_SNS_TOPIC_ARN) \
		--protocol lambda \
		--notification-endpoint \
			$(shell aws 	--profile=$(AWS_PROFILE) lambda get-function \
					--function-name alertdispatcher-$(SLACK_CH_NAME)-warning \
					--query Configuration.FunctionArn | sed 's/"//g')
endif

aws-test-integration:
	aws 	--profile=$(AWS_PROFILE) sns publish \
		--topic-arn $(AWS_SNS_TOPIC_ARN) \
		--message "{\"AlarmName\":\"alertdispatcher-test-alert\",\"AlarmDescription\":\"Alertdisparcher has been installed\",\"NewStateValue\":\"INSTALLED\"}"
	@echo ">> Sending test alert. You should see a message in your Slack ch now"

aws-lambda-invoke-sns:
	@echo ">> Allowing SNS to invoke λ function"
ifeq ($(CRITICAL), true)
	aws 	--profile=$(AWS_PROFILE) lambda add-permission \
		--function-name alertdispatcher-$(SLACK_CH_NAME)-critical \
		--statement-id alertdispatcher-$(SLACK_CH_NAME)-invoke-stmt \
		--action "lambda:InvokeFunction" \
		--principal sns.amazonaws.com \
		--source-arn $(AWS_SNS_TOPIC_ARN)
else
	aws 	--profile=$(AWS_PROFILE) lambda add-permission \
		--function-name alertdispatcher-$(SLACK_CH_NAME)-warning \
		--statement-id alertdispatcher-$(SLACK_CH_NAME)-invoke-stmt \
		--action "lambda:InvokeFunction" \
		--principal sns.amazonaws.com \
		--source-arn $(AWS_SNS_TOPIC_ARN)
endif

install: build zip aws-install-fn cleanup
	@echo ">> λ function created"

update: build zip aws-update-fn cleanup
	@echo ">> λ function updated"

subscribe: aws-subscribe-sns aws-lambda-invoke-sns aws-test-integration
