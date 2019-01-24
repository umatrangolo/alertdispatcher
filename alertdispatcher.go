package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
)

type Attachment struct {
	Text string `json:"text"`
}

type Response struct {
	Type string `json:"response_type"`
	Text string `json:"text"`
	Attachments []Attachment `json:"attachments"`
}

func mkSlackAlertFromSNSEvent(snsEvent events.SNSEvent) Response {
	attachments := []Attachment{}
	for _, r := range snsEvent.Records {
		attachments = append(attachments, Attachment{Text: r.SNS.Message})
	}

	resp := Response{
		Type: "in_channel",
		Text: "Alert!",
		Attachments: attachments,
	}

	return resp
}

func HandleRequest(ctx context.Context, snsEvent events.SNSEvent) error {
	jsonSnsEvent, err := json.MarshalIndent(snsEvent, "", "  ")
	if err != nil {
		log.Printf("error deconding SNS event: %v", err)
		return err
	}
	log.Printf("Got:\n%s", jsonSnsEvent)

	jzon, err := json.Marshal(mkSlackAlertFromSNSEvent(snsEvent))
	if err != nil {
		log.Printf("error marshalling slack response: %v", err)
		return err
	}

	resp, err := http.Post("https://hooks.slack.com/services/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", "application/json", bytes.NewReader(jzon))
	if (err != nil) {
		log.Printf("error sending alert to slack: %v", err)
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		log.Printf("wrong status code: %d", resp.StatusCode)
		return fmt.Errorf("wrong status code: %d", resp.StatusCode)
	} else {
		log.Printf("alert successfully delivered")
	}

        return nil
}

func main() {
        lambda.Start(HandleRequest)
}
