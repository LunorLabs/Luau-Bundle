package main

import (
	"crypto/sha256"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func isLuaFile(path string) bool {
	return strings.HasSuffix(path, ".lua") || strings.HasSuffix(path, ".luau")
}

func getFileHash(path string) (string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

func watchDirectory() {
	dir := "src"
	lastHash := make(map[string]string)
	firstRun := true
	debounceTimer := time.NewTimer(time.Second)
	debounceTimer.Stop()

	// Initial scan
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && isLuaFile(path) {
			hash, err := getFileHash(path)
			if err != nil {
				return err
			}
			lastHash[path] = hash
		}
		return nil
	})
	if err != nil {
		log.Fatal(err)
	}

	for {
		changed := false
		changedFile := ""
		currentHash := make(map[string]string)

		// Scan directory
		err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if !info.IsDir() && isLuaFile(path) {
				hash, err := getFileHash(path)
				if err != nil {
					return err
				}
				currentHash[path] = hash
				lastFileHash, exists := lastHash[path]
				if !exists || lastFileHash != hash {
					if !firstRun {
						rel, _ := filepath.Rel(dir, path)
						changedFile = rel
						changed = true
					}
				}
			}
			return nil
		})
		if err != nil {
			log.Fatal(err)
		}

		// Check for deleted files
		for path := range lastHash {
			if _, exists := currentHash[path]; !exists {
				if !firstRun {
					rel, _ := filepath.Rel(dir, path)
					changedFile = rel
					changed = true
				}
			}
		}

		if changed {
			// Reset debounce timer
			debounceTimer.Reset(300 * time.Millisecond)
		}

		select {
		case <-debounceTimer.C:
			now := time.Now()
			fmt.Printf("Updating %s [%02d:%02d:%02d]\n", 
				changedFile, 
				now.Hour(), 
				now.Minute(), 
				now.Second())
			os.Exit(0) // Signal bundler to rebuild
		default:
			// Continue watching
		}

		lastHash = currentHash
		firstRun = false
		time.Sleep(100 * time.Millisecond)
	}
}

func main() {
	watchDirectory()
}
