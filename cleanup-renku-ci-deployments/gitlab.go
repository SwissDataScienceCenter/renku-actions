package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"regexp"
	"strings"
)

type GitlabApplication struct {
	ID              int    `json:"id,omitempty"`
	ApplicationID   string `json:"application_id,omitempty"`
	ApplicationName string `json:"application_name,omitempty"`
	CallbackURL     string `json:"callback_url,omitempty"`
	Confidential    bool   `json:"confidential,omitempty"`
}

var GitlabApplicationNotFound error = fmt.Errorf("Cannot find the gitlab application")

func listGitlabApplications(gitlabURL *url.URL, apiToken SensitiveString) ([]GitlabApplication, error) {
	reqURL := gitlabURL.JoinPath("/api/v4/applications").String()
	req, err := http.NewRequest("GET", reqURL, nil)
	if err != nil {
		return []GitlabApplication{}, err
	}
	req.Header.Add("private-token", string(apiToken))
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return []GitlabApplication{}, err
	}
	var gitlabApps []GitlabApplication
	err = json.NewDecoder(res.Body).Decode(&gitlabApps)
	if err != nil {
		val, _ := httputil.DumpResponse(res, true)
		return []GitlabApplication{}, fmt.Errorf("could not decode response because of err %s, response is %s\n", err.Error(), string(val))
	}
	defer res.Body.Close()
	return gitlabApps, nil
}

func findGitlabApplication(gitlabURL *url.URL, apiToken SensitiveString, name string) (GitlabApplication, error) {
	gitlabApps, err := listGitlabApplications(gitlabURL, apiToken)
	if err != nil {
		return GitlabApplication{}, err
	}
	for _, app := range gitlabApps {
		if app.ApplicationName == name {
			return app, nil
		}
	}
	return GitlabApplication{}, GitlabApplicationNotFound
}

func removeGitlabApplication(gitlabURL *url.URL, apiToken SensitiveString, id int) error {
	reqURL := gitlabURL.JoinPath(fmt.Sprintf("/api/v4/applications/%d", id)).String()
	req, err := http.NewRequest("DELETE", reqURL, nil)
	req.Header.Add("private-token", string(apiToken))
	if err != nil {
		return err
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	if res.StatusCode != 204 {
		resContent, err := httputil.DumpResponse(res, true)
		if err != nil {
			return err
		}
		return fmt.Errorf("Gitlab responded with unexpected status code %d and content %s", res.StatusCode, resContent)
	}
	return nil
}

func cleanupGitlabApps(gitlabURL *url.URL, apiToken SensitiveString, dryRun bool) error {
	gitlabApps, err := listGitlabApplications(gitlabURL, apiToken)
	if err != nil {
		return err
	}
	for _, app := range gitlabApps {
		log.Printf("Checking for app %s", app.ApplicationName)
		if !(strings.Contains(app.ApplicationName, "renku-ci") || strings.Contains(app.ApplicationName, "ci-renku")) {
			log.Printf("\tapplication %s is not part of a CI deployment, skipping", app.ApplicationName)
			continue
		}
		r := regexp.MustCompile("\\s+")
		urls := r.Split(app.CallbackURL, -1)
		if len(urls) == 0 {
			log.Println("\tdid not find any callback urls, skipping")
			continue
		}
		callbackURLStr := urls[0]
		callbackURL, err := url.Parse(callbackURLStr)
		if err != nil {
			log.Printf("\terror in parsing callback url %s, %s, skipping", app.CallbackURL, err.Error())
			continue
		}
		renkuURL := *callbackURL
		renkuURL.RawFragment = ""
		renkuURL.RawPath = ""
		renkuURL.Path = ""
		renkuURL.RawQuery = ""
		tlsError := tls.CertificateVerificationError{Err: fmt.Errorf(""), UnverifiedCertificates: []*x509.Certificate{}}
		res, err := http.Get(renkuURL.String())
		if err != nil && !strings.Contains(err.Error(), tlsError.Error()) {
			log.Printf("\terror in sending request to the application base url %s, %s, skipping", renkuURL.String(), err.Error())
			continue
		}
		if res != nil && res.StatusCode < 400 {
			log.Printf("\tstatus code from calling %s is <400, will not remove gitlab client", renkuURL.String())
			continue
		}
		log.Printf("\tremoving gitlab application %s", app.ApplicationName)
		if !dryRun {
			err = removeGitlabApplication(gitlabURL, apiToken, app.ID)
			if err != nil {
				log.Printf("\tcannot remove gitlab application %s because of %s", app.ApplicationID, err.Error())
				continue
			}
		}
	}
	return nil
}
