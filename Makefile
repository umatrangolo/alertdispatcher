help:
	@echo $(DIRTY)
	@echo   "Available targets:"
	@echo   "\thelp                 - Prints this help"

build:
	GOOS=linux go build alertdispatcher.go

zip:
	zip alertmanager.zip ./alertdispatcher.go

aws-create-fn:
	aws --profile=$(AWS_PROFILE) lambda create-function --region $(AWS_REGION) --function-name alertdispatcher --memory 128 --role $(AWS_IAM_ROLE) --runtime go1.x --zip-file fileb://./alertdispatcher.zip --handler alertdispatcher

aws-update-fn:
	aws --profile=$(AWS_PROFILE) lambda update-function-code --region $(AWS_REGION) --function-name alertdispatcher --zip-file fileb://./alertdispatcher.zip
