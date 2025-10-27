Output grype-demo.gif

Require echo

Set Shell "bash"
Set FontSize 22
Set Width 1920
Set Height 1080

Type 'grype --distro "alpine:3.22" -o template -t .grype.tmpl --only-fixed sbom:images/pinewall.2025102701_sbom.syft.json'

Sleep 500ms

Enter

Sleep 5s
