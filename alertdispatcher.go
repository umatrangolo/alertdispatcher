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

func mkSlackAlert(text string, texts []string) Response {
	attachments := []Attachment{}
	for _, t := range texts {
		attachments = append(attachments, Attachment{Text: t})
	}

	resp := Response{
		Type: "in_channel",
		Text: text,
		Attachments: attachments,
	}

	return resp
}

func HandleRequest(ctx context.Context, snsEvent events.SNSEvent) error {
//	log.Printf("ctx: %v, event: %v", ctx, snsEvent)

	jzon, err := json.Marshal(mkSlackAlert("Test test", []string{"foo bar baz"}))
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
