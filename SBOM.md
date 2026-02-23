# Pinewall SBOM & Vulnerability Management

One of the benefits of running an image-based system is that we gain the ability to build an SBOM for our image, which can be run through a vulnerability checker such as [Grype](https://github.com/anchore/grype) periodically, including inside CI.

As part of the build process, Ansible invokes [Syft](https://github.com/anchore/syft/) to build an SBOM for our image in both CycloneDX and Syft formats.

We can run Grype from the main Pinewall directory, where it will pick up the default `.grype.yaml` (which excludes the `linux-kernel` package due to too many false positives), and the custom `.grype.tmpl` (which adds more columns to our output for additional context):

```sh
grype --distro "alpine:3.22" -o template -t .grype.tmpl --only-fixed sbom:images/pinewall.2025102701_sbom.syft.json
```

![Demo of the above Grype command running in an interactive terminal](grype-demo.gif)

This approach will show all vulnerabilities that have fixes available, and will include our full supply-chain - including, among other things, compiled Golang binaries which have upstream modules that need updating.

Seeing the full context of vulnerabilities in our supply-chain is useful, but not always actionable if fixes need to be deployed by upstream developers. For an approach that only shows _actionable_ vulnerabilities (i.e. ones with fixes which we could apply now via APK), we can run a command like the following:

```sh
grype --distro "alpine:3.22" -c .grype-ci.yaml --fail-on high --only-fixed sbom:images/pinewall.2025102701_sbom.syft.json
```

This version of the command will exclude Go modules from our output. It will also return a non-zero error code if any High or above severity vulnerabilities are detected in the image, making it quite useful to include in a scheduled CI pipeline run.
