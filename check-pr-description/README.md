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

The reference will be stored in an output variable with the same name. For example,

```
/deploy renku-ui=0.11.9 renku=master
```

will deploy the tag `0.11.9` of `renku-ui` and the tip of the `master` branch of `renku`.
### Passing in additional values

You may pass in additional ad-hoc values to the deployment by using the `extra-values` option.
For example:

```
/deploy extra-values="tests.image.ref=my-test,core.sentry.env=feature"
```

Note that you can pass in multiple values, but they must be in the same string,
separated by a comma and without whitespaces.

### Skipping tests

The `#notest` string will falsify the otherwise truthy variable named `test-enabled`,
for example

```
/deploy renku-ui=0.11.9 #notest
```

## Procedures for renku platform PRs

The process for using this action in renku PR reviews is outlined here:
https://renku.readthedocs.io/en/latest/how-to-guides/contributing/pull-requests.html
