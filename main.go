package main

import (
	"encoding/json"
	"fmt"
	"github.com/prometheus/alertmanager/template"
	"log"
	"net/http"
	"os"
	"strings"

	"golang.org/x/exp/maps"
)

func WebhookHandler(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	payload := template.Data{}
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		log.Println("Parsing alertmanager JSON failed")
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	log.Printf("Received valid hook from %v\n", r.RemoteAddr)

	for _, alert := range payload.Alerts {

		log.Println(alert)

		req, err := http.NewRequest("POST", os.Getenv("NTFY_TOPIC"), strings.NewReader(alert.Annotations["description"]))
		if err != nil {
			log.Printf("Building request to %s failed: %s", req.RemoteAddr, err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		req.Header.Set("Title", fmt.Sprintf("[%s] %s", alert.Labels["instance"], alert.Labels["alertname"]))
		// req.Header.Set("Priority", "urgent") //TODO broken on ios
		req.Header.Set("Tags", strings.Join(maps.Values(alert.Labels), ","))

		req.SetBasicAuth(os.Getenv("NTFY_USER"), os.Getenv("NTFY_PASS"))

		if _, err := http.DefaultClient.Do(req); err != nil {
			log.Printf("Sending to %s failed: %s\n", req.RemoteAddr, err)
			w.WriteHeader(http.StatusBadRequest)
			return
		}

	}
	w.WriteHeader(http.StatusOK)

}

func main() {

	for _, v := range []string{"HTTP_ADDRESS", "HTTP_PORT", "NTFY_TOPIC"} {
		if len(strings.TrimSpace(os.Getenv(v))) == 0 {
			panic("Environment variable " + v + " not set!")
		}
	}

	http.HandleFunc("/", WebhookHandler)
	var listenAddr = fmt.Sprintf("%v:%v", os.Getenv("HTTP_ADDRESS"), os.Getenv("HTTP_PORT"))
	log.Printf("Listening for HTTP requests (webhooks) on %v\n", listenAddr)
	log.Fatal(http.ListenAndServe(listenAddr, nil))
}
