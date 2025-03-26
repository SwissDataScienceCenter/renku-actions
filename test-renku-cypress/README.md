# Run Cypress-based acceptance tests

This is a composite action that:
- Clones the Renku repository `inputs.renku-repository` and checks out the specified referece `inputs.renku-reference` at the target path `inputs.renku-path`.
- Runs the Cypress acceptance tests target file `inputs.e2e-target` after checking the infrastructure with the `e2e-infrastructure-check` file. Mind you can change the e2e folder `e2e-folder` and the Cypress files suffix `e2e-suffix`.
- Saves the videos and images as an artifact when the tests fail.

The test user can be specified with `inputs.test-user-*` inputs. The only mandatory field is `*-password`; you can provide also `*-email`, `*-firstname`, `*-lastname` and `*-username`.

The FQDN of the Kubernetes cluster on which Renku has been deployed can be specified with `kubernetes-cluster-fqdn`. This is optional and defaults to `dev.renku.ch`.

## Running multiple tests.

Mind that you need to provide the e2e file name; the action is structured to run different tests in parallel. The easiest way to do that is by defining a matrix in the workflow file, as in the example below:

```yaml
    strategy:
      fail-fast: false
      matrix:
        tests: [publicProject, updateProjects, useSession]
```

## Example use

```yaml
jobs:
  cypress-acceptance-tests:
    strategy:
      fail-fast: false
      matrix:
        tests:
          - publicProject
          - privateProject
          - updateProjects
          - testDatasets
          - useSession
          - checkWorkflows
    steps:
      - name: Extract Renku repository reference
        run: echo "RENKU_REFERENCE=`echo '${{ needs.check-deploy.outputs.renku }}' | cut -d'@' -f2`" >> $GITHUB_ENV
      - uses: SwissDataScienceCenter/renku-actions/test-renku-cypress
        with:
          e2e-target: ${{ matrix.tests }}
          renku-reference: "${{ env.RENKU_REFERENCE }}"
          renku-release: renku-ci-ui-${{ github.event.number }}
          test-user-password: ${{ secrets.RENKU_BOT_DEV_PASSWORD }}
```
