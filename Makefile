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
	zip alertdispatcher.zip ./alertdispatcher

cleanup:
	@echo ">> Cleaning up"
	rm alertdispatcher.zip
	rm alertdispatcher

aws-install-fn:
	aws --profile=$(AWS_PROFILE) lambda create-function --region $(AWS_REGION) --function-name alertdispatcher --memory 128 --role $(AWS_IAM_ROLE) --runtime go1.x --zip-file fileb://./alertdispatcher.zip --handler alertdispatcher

aws-update-fn:
	aws --profile=$(AWS_PROFILE) lambda update-function-code --region $(AWS_REGION) --function-name alertdispatcher --zip-file fileb://./alertdispatcher.zip

install: build zip aws-install-fn cleanup
	@echo ">> λ function craeated"

update: build zip aws-update-fn cleanup
	@echo ">> λ function updated"
