package main

import (
	"context"
	"time"

	"encoding/json"
	"log"
	"regexp"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	typedcorev1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/utils/ptr"
)

func k8sClient(kubeconfig string) (*kubernetes.Clientset, error) {
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		return nil, err
	}
	clientset, err := kubernetes.NewForConfig(config)
	return clientset, err
}

func getNamespaces(ctx context.Context, clnt *kubernetes.Clientset, minAge time.Duration, regexs ...*regexp.Regexp) ([]v1.Namespace, error) {
	namespaces, err := clnt.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	output := []v1.Namespace{}
	if len(regexs) == 0 {
		return namespaces.Items, nil
	}
	now := time.Now()
	for _, ns := range namespaces.Items {
		for _, regex := range regexs {
			age := now.Sub(ns.GetCreationTimestamp().Time)
			oldEnough := age > minAge || minAge == 0
			if !regex.MatchString(ns.Name) {
				continue
			}
			if !oldEnough {
				continue
			}
			log.Printf("Namespace %s MATCHED regex %s and is old enough %v", ns.Name, regex, age)
			output = append(output, ns)
		}
	}
	return output, nil
}

type NamespacedNameSet map[types.NamespacedName]struct{}

func (n NamespacedNameSet) Values() []types.NamespacedName {
	output := []types.NamespacedName{}
	for k, _ := range n {
		output = append(output, k)
	}
	return output
}

func getReleases(ctx context.Context, clnt *kubernetes.Clientset, minAge time.Duration, regexs ...*regexp.Regexp) ([]types.NamespacedName, error) {
	namespaces, err := getNamespaces(ctx, clnt, minAge)
	if err != nil {
		return nil, err
	}
	output := NamespacedNameSet(map[types.NamespacedName]struct{}{})
	now := time.Now()
	for _, ns := range namespaces {
		releases, err := clnt.CoreV1().Secrets(ns.GetName()).List(ctx, metav1.ListOptions{FieldSelector: "type=helm.sh/release.v1"})
		if err != nil {
			return nil, err
		}
		for _, release := range releases.Items {
			name := release.GetLabels()["name"]
			nsn := types.NamespacedName{Namespace: ns.GetName(), Name: name}
			age := now.Sub(release.GetCreationTimestamp().Time)
			oldEnough := age > minAge || minAge == 0
			if _, found := output[nsn]; found {
				continue
			}
			if len(regexs) == 0 && oldEnough {
				output[nsn] = struct{}{}
				continue
			}
			for _, regex := range regexs {
				if len(name) > 0 && !regex.MatchString(name) {
					continue
				}
				if !oldEnough {
					continue
				}
				log.Printf("Release %s MATCHED regex %s and is old enough %v", name, regex, age)
				output[nsn] = struct{}{}
			}
		}
	}
	return output.Values(), nil
}

func getDynClient(kubeconfig string) (*dynamic.DynamicClient, error) {
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		return nil, err
	}
	dynClient, err := dynamic.NewForConfig(config)
	return dynClient, err
}

func removeFinalizers(ctx context.Context, clnt dynamic.ResourceInterface) error {
	// List the CRD objects in a specific namespace (or use "" for all namespaces)
	objects, err := clnt.List(ctx, metav1.ListOptions{})
	if err != nil {
		return err
	}

	patch, err := json.Marshal([]map[string]string{
		{"op": "remove", "path": "/metadata/finalizers"},
	})
	if err != nil {
		return err
	}
	for _, obj := range objects.Items {
		log.Printf("patching %s in namespace %s of kind %s", obj.GetName(), obj.GetNamespace(), obj.GetKind())
		_, err := clnt.Patch(ctx, obj.GetName(), types.JSONPatchType, patch, metav1.PatchOptions{})
		if err != nil {
			return err
		}
	}
	return nil
}

func removeFinalizersAndNamespace(
	ctx context.Context,
	namespace string,
	nsClnt typedcorev1.NamespaceInterface,
	jsClnt dynamic.NamespaceableResourceInterface,
	asClnt dynamic.NamespaceableResourceInterface,
) error {
	delOptions := metav1.DeleteOptions{
		GracePeriodSeconds: ptr.To(int64(0)),
		PropagationPolicy:  ptr.To(metav1.DeletePropagationForeground),
	}
	err := removeFinalizers(ctx, jsClnt.Namespace(namespace))
	if err != nil {
		log.Printf("Cannot remove JypyterServer finalizers because of error %s, skipping", err.Error())
		return err
	}
	err = removeFinalizers(ctx, asClnt.Namespace(namespace))
	if err != nil {
		log.Printf("Cannot remove AmaltheaSession finalizers because of error %s, skipping", err.Error())
		return err
	}
	err = asClnt.Delete(ctx, namespace, delOptions)
	if err != nil {
		log.Printf("Cannot remove AmaltheaSession finalizers because of error %s, skipping", err.Error())
		return err
	}
	return nil
}
