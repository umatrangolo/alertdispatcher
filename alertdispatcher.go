package main

import (
	"context"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
)

func HandleRequest(ctx context.Context, snsEvent events.SNSEvent) error {
	log.Printf("ctx: %v, event: %v", ctx, snsEvent)
        return nil
}

func main() {
        lambda.Start(HandleRequest)
}
