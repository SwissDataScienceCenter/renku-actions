# Run Cypress-based acceptance tests

This is a composite action that:
- Clones the Renku repository `inputs.renku-repository` and checks out the specified referece `inputs.renku-reference` at the target path `inputs.renku-path`.
- Runs the Cypress acceptance tests target file `inputs.e2e-target` after checking the infrastructure with the `e2e-infrastructure-check` file. Mind you can change the e2e folder `e2e-folder` and the Cypress files suffix `e2e-suffix`.
- Saves the videos and images as an artifact when the tests fail.

The test user can be specified with `inputs.test-user-*` inputs. The only mandatory field is `*-password`; you can provide also `*-email`, `*-firstname`, `*-lastname` and `*-username`.

## Running multiple tests.

Mind that you need to provide the e2e file name; the action is structured to run different tests in parallel. The easiest way to do that is by defining a matrix in the workflow file, as in the example below:

```yaml
    strategy:
      fail-fast: false
      max-parallel: 1
      matrix:
        tests: [publicProject, updateProjects, useSession]
```

## Example use

```yaml
jobs:
  cypress-acceptance-tests:
    strategy:
      fail-fast: false
      max-parallel: 1
      matrix:
        tests: [publicProject, updateProjects, useSession]
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

# Interaction with Selenium-based acceptance tests

This action **does not** tear down the deployment, but the `test-renku` action to run the Selenium-based tests does, and some care needs to be taken when running the Cypress tests without running the Selenium tests.

Specifically, it is necessary to persist the deployment using the `#persist` flag.

```
/deploy #persist
```

Mind that not using the `#persist` flag will result in the deployment being torn down after the Selenium tests; this _should_ work when both tests run in parallel since Selenium tests are generally slower, but this is not guarantend.

Also, re-running only Cypress tests would not work since the deployment will not be available anymore.

