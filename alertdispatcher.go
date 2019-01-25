package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-lambda-go/events"
)

type Attachment struct {
	Title string `json:"title"`
	Fallback string `json:"fallback"`
	Color string `json:"color"`
	Text string `json:"text"`
}

type Response struct {
	Attachments []Attachment `json:"attachments"`
}

type CloudWatchAlarm struct {
	Name string `json:"AlarmName"`
	Description string `json:"AlarmDescription"`
	State string `json:"NewStateValue"`
}

func mkSlackAlertFromSNSEvent(snsEvent events.SNSEvent) (*Response, error) {
	var mkAttachment = func(cwMessage string) (*Attachment, error) {
		critical := os.Getenv("CRITICAL")
		cwAlarm := CloudWatchAlarm{}
		raw := json.RawMessage(cwMessage)
		err := json.Unmarshal([]byte(raw), &cwAlarm)
		if err != nil {
			return nil, fmt.Errorf("errror while unmarshalling cw message: %v", err)
		}

		message := ""
		if strings.ToUpper(critical) == "TRUE" {
			message = fmt.Sprintf("<!here> %s: %s", cwAlarm.State, cwAlarm.Name)
		} else {
			message = fmt.Sprintf("%s: %s", cwAlarm.State, cwAlarm.Name)
		}

		if cwAlarm.State == "ALARM" {
			return &Attachment{
				Fallback: fmt.Sprintf("FIRING: %s", cwAlarm.Name),
				Title: message,
				Color: "#FF0000", // red
				Text: cwAlarm.Description,
			}, nil
		} else if cwAlarm.State == "OK" {
			return &Attachment{
				Fallback: fmt.Sprintf("RESOLVED: %s", cwAlarm.Name),
				Title: message,
				Color: "#008000", // green
				Text: cwAlarm.Description,
			}, nil
		} else {
			return nil, fmt.Errorf("unknown alarm state")
		}
	}

	attachments := []Attachment{}
	errors:= []error{}
	for _, r := range snsEvent.Records {
		attachment, err := mkAttachment(r.SNS.Message)
		if err != nil {
			errors = append(errors, err)
		} else {
			attachments = append(attachments, *attachment)
		}
	}

	if len(errors) != 0 {
		for _, err := range errors {
			log.Printf("error: %v", err)
		}
		return nil, fmt.Errorf("error whhile preparing Slack message")
	}

	resp := Response{
		Attachments: attachments,
	}

	return &resp, nil
}

func HandleRequest(ctx context.Context, snsEvent events.SNSEvent) error {
	webhook := os.Getenv("WEBHOOK")
	jsonSnsEvent, err := json.MarshalIndent(snsEvent, "", "\t")
	if err != nil {
		log.Printf("error deconding SNS event: %v", err)
		return err
	}
	log.Printf("Got:\n%s", jsonSnsEvent)

	slackAlert, err := mkSlackAlertFromSNSEvent(snsEvent)
	if err != nil {
		log.Printf("error preparing Slack message: %v", err)
		return err
	}

	jzon, err := json.Marshal(slackAlert)
	if err != nil {
		log.Printf("error marshalling slack response: %v", err)
		return err
	}

	resp, err := http.Post(webhook, "application/json", bytes.NewReader(jzon))
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
	if _, ok := os.LookupEnv("WEBHOOK"); !ok {
		log.Fatal("Unable to get slack webhook frem env (WEBHOOK)")
	}

        lambda.Start(HandleRequest)
}
