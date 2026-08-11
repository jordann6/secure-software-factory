package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprintln(w, "ok")
	})

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		secretPath := "/vault/secrets/config"
		data, err := os.ReadFile(secretPath)
		if err != nil {
			fmt.Fprintf(w, "secret not mounted: %v\n", err)
			return
		}
		// Print that the secret is present without leaking its value
		fmt.Fprintf(w, "secret mounted: yes (%d bytes)\n", len(data))
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
