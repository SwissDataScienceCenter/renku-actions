package main

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"regexp"

	"github.com/alecthomas/kong"
	// metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	// "k8s.io/utils/ptr"
)

type SensitiveString string

func (s SensitiveString) String() string {
	return fmt.Sprintf("<redacted sensitive string of length %d>", len(s))
}

func (s SensitiveString) Format(w fmt.State, v rune) {
	_, err := w.Write([]byte(s.String()))
	if err != nil {
		panic(err)
	}
}

type Config struct {
	Kubeconfig  string          `type:"existingfile" help:"Path to the kubeconfig file" default:"~/.kube/config"`
	GitlabURL   *url.URL        `help:"Gitlab url" default:"http://gitlab.dev.renku.ch"`
	GitlabToken SensitiveString `help:"Gitlab token" env:"GITLAB_TOKEN"`
	DryRun      bool            `help:"Just log but do not actually execute anything"`
}

type RemoveArgs struct {
	ReleaseRegex   []string `default:"^.+-ci-.+|^ci-.+" help:"Golang regex for selecting releases"`
	NamespaceRegex []string `default:"^.+-ci-.+|^ci-.+" help:"Golang regex for selecting the namespaces"`
}

type Args struct {
	Config `embed:""`
	Remove RemoveArgs `cmd:"" aliases:"rm" default:"withargs"`
}

func main() {
	var args Args
	kctx := kong.Parse(&args)
	log.Printf("Command: %+v", kctx.Command())
	log.Printf("Args: %+v", args)
	ctx := context.Background()

	nsRegexs := []*regexp.Regexp{}
	for _, regStr := range args.Remove.NamespaceRegex {
		regex, err := regexp.CompilePOSIX(regStr)
		if err != nil {
			log.Fatal(err)
		}
		nsRegexs = append(nsRegexs, regex)
	}

	relRegexs := []*regexp.Regexp{}
	for _, regStr := range args.Remove.ReleaseRegex {
		regex, err := regexp.CompilePOSIX(regStr)
		if err != nil {
			log.Fatal(err)
		}
		relRegexs = append(relRegexs, regex)
	}

	clnt, err := k8sClient(args.Kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	namespaces, err := getNamespaces(ctx, clnt, nsRegexs...)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Found %d namespaces", len(namespaces))

	releases, err := getReleases(ctx, clnt, relRegexs...)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Found %d releases", len(releases))

	// To cleanup patch sessions to remove finalizer
	// Patch jupyter servers to remove their finalizers
	// Remove the namespace
	asGVR := schema.GroupVersionResource{
		Group:    "amalthea.dev",
		Version:  "v1alpha1",
		Resource: "amaltheasessions",
	}
	jsGVR := schema.GroupVersionResource{
		Group:    "amalthea.dev",
		Version:  "v1alpha1",
		Resource: "jupyterservers",
	}

	dynClnt, err := getDynClient(args.Kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	asClnt := dynClnt.Resource(asGVR)
	jsClnt := dynClnt.Resource(jsGVR)
	// nsClnt := clnt.CoreV1().Namespaces()
	// delOptions := metav1.DeleteOptions{
	// 	GracePeriodSeconds: ptr.To(int64(0)),
	// 	PropagationPolicy:  ptr.To(metav1.DeletePropagationForeground),
	// }
	for _, ns := range namespaces {
		log.Printf("Removing finalizers from sesions in namesapce %s", ns.GetName())
		err = removeFinalizers(ctx, jsClnt.Namespace(ns.GetName()))
		err = removeFinalizers(ctx, asClnt.Namespace(ns.GetName()))
		// err = nsClnt.Delete(ctx, ns.GetName(), delOptions)
	}
	for _, release := range releases {
		log.Printf("Removing finalizers from sesions in release %s in namesapce %s", release.Name, release.Namespace)
		err = removeFinalizers(ctx, jsClnt.Namespace(release.Namespace))
		err = removeFinalizers(ctx, asClnt.Namespace(release.Namespace))
		// err = nsClnt.Delete(ctx, release.Namespace, delOptions)
	}
}
