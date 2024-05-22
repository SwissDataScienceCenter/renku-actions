# Check PR description

This action looks for a specific string in the target PR description and an
optional command following it.

## Usage

The command is made by multiple sections separated by a space, and it terminates
with the end of the line. The action is triggered by using `/deploy` at the beginning
of a line in the PR description.

### Specifying component versions

A renku component name followed by `=<ref>`, where `<ref>` is any valid
reference like a tag or a branch name (E.G. `renku-ui=0.11.9` or
`renku-notebooks=debug-with-vscode-k8s`).

The supported components are:
- `renku`
- `renku-core`
- `renku-gateway`
- `renku-graph`
- `renku-notebooks`
- `renku-ui` (that includes the `renku-ui-server` component, since the version is
  aligned between the 2 components)
- `renku-data-services`
- `renku-search`

The reference will be stored in an output variable with the same name. For example,

```
/deploy renku-ui=0.11.9 renku=master
```

will deploy the tag `0.11.9` of `renku-ui` and the tip of the `master` branch of `renku`.

### Passing in additional values

You may pass in additional ad-hoc values to the deployment by using the `extra-values` option.
For example:

```
/deploy extra-values=tests.image.tag=my-test,core.sentry.env=feature
```

Note that you can pass in multiple values, but they must be in the same string,
separated by a comma and without whitespaces. Check out [the helm docs](https://helm.sh/docs/intro/using_helm/#the-format-and-limitations-of---set)
for information on how to provide more complex values - such as an entire array - through
the `extra-values` option.

### Skipping tests

The `#notest` string will falsify the otherwise truthy variable named `test-enabled`,
skipping all the acceptance tests.

```
/deploy renku-ui=0.11.9 #notest
```

## Procedures for renku platform PRs

The process for using this action in renku PR reviews is outlined here:
https://renku.readthedocs.io/en/latest/how-to-guides/contributing/pull-requests.html
