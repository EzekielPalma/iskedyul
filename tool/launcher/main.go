// A small static server for the compiled Flutter Web app.
// Go is only needed to build this launcher in the cloud.
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"
)

func webHandler(directory string) http.Handler {
	files := http.FileServer(http.Dir(directory))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-cache")
		files.ServeHTTP(w, r)
	})
}

func main() {
	port := flag.Int("port", 8080, "Local port (use the same port to keep the same saved planner)")
	noBrowser := flag.Bool("no-browser", false, "Do not open a browser automatically")
	flag.Parse()
	executable, err := os.Executable()
	if err != nil {
		log.Fatal(err)
	}
	directory := filepath.Join(filepath.Dir(executable), "web")
	if _, err := os.Stat(filepath.Join(directory, "index.html")); err != nil {
		log.Fatal("The web folder is missing. Extract the entire download before starting iSkedyul.")
	}
	listener, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", *port))
	if err != nil {
		log.Fatal("Cannot start iSkedyul. Close another local server using this port, then try again. ", err)
	}
	url := fmt.Sprintf("http://127.0.0.1:%d", *port)
	fmt.Println("iSkedyul is running at", url)
	fmt.Println("Keep this window open while using the app. Press Ctrl+C to stop.")
	if !*noBrowser {
		var command *exec.Cmd
		switch runtime.GOOS {
		case "windows":
			command = exec.Command("rundll32", "url.dll,FileProtocolHandler", url)
		case "darwin":
			command = exec.Command("open", url)
		default:
			command = exec.Command("xdg-open", url)
		}
		if err := command.Start(); err != nil {
			fmt.Println("Open the address above in your browser.")
		} else {
			go func() { _ = command.Wait() }()
		}
	}
	server := &http.Server{Handler: webHandler(directory), ReadHeaderTimeout: 5 * time.Second}
	log.Fatal(server.Serve(listener))
}
