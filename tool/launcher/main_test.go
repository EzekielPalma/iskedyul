package main

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestServeCompiledWebFiles(t *testing.T) {
	directory := t.TempDir()
	for name, data := range map[string]string{"index.html": "<title>iSkedyul</title>", "main.dart.js": "console.log('app')", "runtime.wasm": "wasm"} {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(data), 0600); err != nil {
			t.Fatal(err)
		}
	}
	handler := webHandler(directory)
	for _, path := range []string{"/", "/main.dart.js", "/runtime.wasm"} {
		response := httptest.NewRecorder()
		handler.ServeHTTP(response, httptest.NewRequest(http.MethodGet, path, nil))
		if response.Code != 200 || response.Body.Len() == 0 {
			t.Fatalf("%s: missing web content", path)
		}
		if response.Header().Get("Cache-Control") != "no-cache" {
			t.Fatal("expected fresh app assets")
		}
		if path == "/runtime.wasm" && !strings.HasPrefix(response.Header().Get("Content-Type"), "application/wasm") {
			t.Fatal("incorrect WASM content type")
		}
	}
	missing := httptest.NewRecorder()
	handler.ServeHTTP(missing, httptest.NewRequest(http.MethodGet, "/missing.js", nil))
	if missing.Code != 404 {
		t.Fatal("missing assets must return 404")
	}
}
