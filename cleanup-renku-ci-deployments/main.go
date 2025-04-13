package main

import (
	"context"
	"fmt"
	"log"
	"net/url"
	"regexp"

	"github.com/alecthomas/kong"
	"k8s.io/apimachinery/pkg/runtime/schema"
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

func (r *RemoveArgs) Run(ctx *CmdContext) error {
	removeReleases(ctx, r)
	return nil
}

type GitlabApplicationCleanup struct{}

func (g *GitlabApplicationCleanup) Run(ctx *CmdContext) error {
	return cleanupGitlabApps(ctx.GitlabURL, ctx.GitlabToken, ctx.DryRun)
}

type Args struct {
	Remove                   RemoveArgs               `cmd:"" aliases:"rm" help:"Remove Renku deployments"`
	GitlabApplicationCleanup GitlabApplicationCleanup `cmd:"gitlab_application_cleanup" aliases:"gac" help:"Remove unused gitlab apps."`
	Config                   `embed:""`
}

type CmdContext struct {
	ctx context.Context
	Config
}

func main() {
	var args Args
	kctx := kong.Parse(&args)
	log.Printf("Command: %+v", kctx.Command())
	log.Printf("Args: %+v", args)
	ctx := CmdContext{
		Config: args.Config,
		ctx:    context.Background(),
	}
	err := kctx.Run(&ctx)
	if err != nil {
		log.Fatalln(err)
	}
}

func removeReleases(ctx *CmdContext, args *RemoveArgs) {
	nsRegexs := []*regexp.Regexp{}
	for _, regStr := range args.NamespaceRegex {
		regex, err := regexp.CompilePOSIX(regStr)
		if err != nil {
			log.Fatal(err)
		}
		nsRegexs = append(nsRegexs, regex)
	}

	relRegexs := []*regexp.Regexp{}
	for _, regStr := range args.ReleaseRegex {
		regex, err := regexp.CompilePOSIX(regStr)
		if err != nil {
			log.Fatal(err)
		}
		relRegexs = append(relRegexs, regex)
	}

	clnt, err := k8sClient(ctx.Kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	namespaces, err := getNamespaces(ctx.ctx, clnt, nsRegexs...)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Found %d namespaces", len(namespaces))

	releases, err := getReleases(ctx.ctx, clnt, relRegexs...)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("Found %d releases", len(releases))

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

	dynClnt, err := getDynClient(ctx.Kubeconfig)
	if err != nil {
		log.Fatal(err)
	}

	asClnt := dynClnt.Resource(asGVR)
	jsClnt := dynClnt.Resource(jsGVR)
	nsClnt := clnt.CoreV1().Namespaces()
	for _, ns := range namespaces {
		log.Printf("Removing finalizers from sesions in namesapce %s", ns.GetName())
		if !ctx.DryRun {
			err := removeFinalizersAndNamespace(ctx.ctx, ns.GetName(), nsClnt, jsClnt, asClnt)
			if err != nil {
				continue
			}
		}
	}
	for _, release := range releases {
		log.Printf("Removing finalizers from sesions in release %s in namesapce %s", release.Name, release.Namespace)
		if !ctx.DryRun {
			err := removeFinalizersAndNamespace(ctx.ctx, release.Namespace, nsClnt, jsClnt, asClnt)
			if err != nil {
				continue
			}
		}
	}
	for _, release := range releases {
		log.Printf("Removing gitlab application for release %s", release.Name)
		app, err := findGitlabApplication(ctx.GitlabURL, ctx.GitlabToken, release.Name)
		if err != nil {
			log.Printf("Cannot find gitlab application for release %s because of error %s, skipping", release.Name, err.Error())
			continue
		}
		if !ctx.DryRun {
			err = removeGitlabApplication(ctx.GitlabURL, ctx.GitlabToken, app.ID)
			if err != nil {
				log.Printf("Cannot delete gitlab application for release %s because of error %s, skipping", release.Name, err.Error())
				continue
			}
		}
	}
}
