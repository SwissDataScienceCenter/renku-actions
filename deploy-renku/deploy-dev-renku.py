#!/usr/bin/env python3
#
# Usage: ./deploy_dev_renku -h
#
# Note: you can use the following environment variables to set defaults:
#
# RENKU_VALUES_FILE
# RENKU_RELEASE
# RENKU_NAMESPACE
# RENKU_ANONYMOUS_SESSIONS

import json
import os
import pprint
import tempfile
import urllib.request

from pathlib import Path
from packaging.version import Version
from subprocess import check_call

import yaml

components = ["renku-core", "renku-gateway", "renku-graph", "renku-notebooks", "renku-ui"]


class RenkuRequirement(object):
    """Class for handling custom renku requirements."""

    def __init__(self, component, version, tempdir):
        self.component = component
        self.tempdir = tempdir

        self.version_ = version
        self.is_git_ref = False
        if version.startswith("@"):
            # this is a git ref
            self.is_git_ref = True

    @property
    def ref(self):
        if self.is_git_ref:
            return self.version_.strip("@")
        return None

    @property
    def version(self):
        if self.is_git_ref:
            self.clone()
            self.chartpress(skip_build=True)
            with open(self.repo_dir / "helm-chart" / self.component / "Chart.yaml") as f:
                chart = yaml.load(f, Loader=yaml.SafeLoader)
            return chart.get("version")
        return self.version_

    @property
    def helm_repo(self):
        if self.ref:
            return f"file://{self.tempdir}/{self.repo}/helm-chart/{self.component}"
        return "https://swissdatasciencecenter.github.io/helm-charts/"

    # handle the special case of renku-python
    @property
    def repo(self):
        if self.component == "renku-core":
            return "renku-python"
        return self.component

    @property
    def repo_url(self):
        if self.component == "renku-core":
            return f"https://github.com/SwissDataScienceCenter/renku-python.git"
        return f"https://github.com/SwissDataScienceCenter/{self.component}.git"

    @property
    def repo_dir(self):
        return Path(f"{self.tempdir}/{self.repo}")

    def clone(self):
        """Clone repo and reset to ref."""
        if not self.repo_dir.exists():
            check_call(
                [
                    "git",
                    "clone",
                    self.repo_url,
                    self.repo_dir,
                ]
            )
        check_call(["git", "checkout", self.ref], cwd=self.repo_dir)

    def chartpress(self, skip_build=False):
        """Run chartpress."""
        check_call(["helm", "dep", "update", f"helm-chart/{self.component}"], cwd=self.repo_dir)
        cmd = ["chartpress", "--push"]
        if skip_build:
            cmd.append("--skip-build")
        check_call(cmd, cwd=self.repo_dir)

    def setup(self):
        """Checkout the repo and run chartpress."""
        self.clone()
        self.chartpress()


def configure_requirements(tempdir, reqs, component_versions):
    """
    Reads versions from environment variables and renders the requirements.yaml file.

    If any of the requested versions reference a git ref, the chart is rendered and
    images built and pushed to dockerhub.
    """
    for component, version in component_versions.items():
        if version:
            # form and setup the requirement
            req = RenkuRequirement(component.replace("_", "-"), version, tempdir)
            if req.ref:
                req.setup()
                # replace the requirement
            for dep in reqs["dependencies"]:
                if dep["name"] == component.replace("_", "-"):
                    dep["version"] = req.version
                    dep["repository"] = req.helm_repo
                    continue
    return reqs

def set_rp_version(values_file, extra_values, reqs):
    """Set appropriate renku-python release candidate version in values if full version isn't released yet."""
    with open(values_file) as f:
        values = yaml.load(f, Loader=yaml.SafeLoader)

    if values.get("global", {}).get("renku", {}).get("cli_version") or (extra_values and "global.renku.cli_version" in extra_values):
        # version is already set
        return

    core_version = next(dep["version"] for dep in reqs["dependencies"] if dep["name"] == "renku-core")

    # get current rp versions from pypi
    with urllib.request.urlopen("https://pypi.org/pypi/renku/json") as f:
        rp_pypi_data = json.load(f)

    # get newest version available
    rp_versions = [Version(k) for k in rp_pypi_data["releases"].keys() if k.startswith(core_version)]

    if not rp_versions:
        # fall back to using latest version
        newest_version = sorted([Version(k) for k in rp_pypi_data["releases"].keys()])[-1]
    else:
        newest_version = sorted(rp_versions)[-1]

    print(f"Setting renku cli version to {newest_version}")

    if "global" not in values:
        values["global"] = {}

    if "renku" not in values["global"]:
        values["global"]["renku"] = {}

    values["global"]["renku"]["cli_version"] = str(newest_version)

    with open(values_file, "w") as f:
        yaml.dump(values, f, default_flow_style=False)


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser()
    for component in components:
        default = os.environ.get(component.replace("-", "_"))
        parser.add_argument(
            f"--{component}",
            help=f"Version or ref for {component}",
            default=default if default else None,
        )
    parser.add_argument("--renku", help="Main chart ref", default=os.environ.get("renku"))
    parser.add_argument(
        "--values-file",
        help="Value file path",
        default=os.environ.get("RENKU_VALUES_FILE"),
    )
    parser.add_argument(
        "--namespace",
        help="Namespace for this release",
        default=os.environ.get("RENKU_NAMESPACE"),
    )
    parser.add_argument(
        "--extra-values",
        help="Set additional values (comma-separated)",
        default=os.environ.get("extra_values"),
    )
    parser.add_argument("--release", help="Release name", default=os.environ.get("RENKU_RELEASE"))

    args = parser.parse_args()
    component_versions = {a: b for a, b in vars(args).items() if a.replace("_", "-") in components}

    tempdir_ = tempfile.TemporaryDirectory()
    tempdir = Path(tempdir_.name)

    renku_dir = tempdir / "renku"
    reqs_path = renku_dir / "helm-chart/renku/requirements.yaml"

    ## 1. clone the renku repo
    renku_req = RenkuRequirement(component="renku", version=args.renku or "@master", tempdir=tempdir)
    renku_req.clone()

    with open(reqs_path) as f:
        reqs = yaml.load(f, Loader=yaml.SafeLoader)

    ## 2. set the chosen versions in the requirements.yaml file

    reqs = configure_requirements(tempdir, reqs, component_versions)

    with open(reqs_path, "w") as f:
        yaml.dump(reqs, f)

    ## 3. render the renku chart for deployment
    renku_req.chartpress()

    ## 4. set renku-python release candidate version if applicable
    set_rp_version(args.values_file, args.extra_values, reqs)


    ## 5. deploy
    values_file = args.values_file
    release = args.release
    namespace = args.namespace or release

    print(f'*** Dependencies for release "{release}" under namespace "{namespace}" ***')
    pprint.pp(reqs)

    helm_command = [
        "helm",
        "upgrade",
        "--install",
        release,
        "./renku",
        "-f",
        values_file,
        "--namespace",
        namespace,
        "--timeout",
        "20m",
        "--wait",
        "--wait-for-jobs",
    ]

    if os.getenv("TEST_ARTIFACTS_PATH"):
        helm_command += ["--set", f'tests.resultsS3.filename={os.getenv("TEST_ARTIFACTS_PATH")}']

    # pass additional values to the deployment
    if args.extra_values:
        helm_command += ["--set", args.extra_values]

    # deploy the main chart
    check_call(
        helm_command,
        cwd=renku_dir / "helm-chart",
    )

    tempdir_.cleanup()
