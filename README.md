# test-applications

Container images for sample applications used in testing Cryostat. Each subdirectory represents a separate container image.

# building

Each subdirectory is expected to contain a `build.bash` file which can be invoked with no arguments to produce a container image.

The `build.bash` in this repository root will iterate over all the container image directories and build each.

# Scorecard applications

`scorecard` and `scorecard-agent` build the same minimal Java HTTP application for
[Cryostat Operator Scorecard tests](https://github.com/cryostatio/cryostat-operator).
It listens on port 8080 with a `/health` readiness endpoint and no remote JMX
listener. The two images are:

| Build script | Image | Agent |
| --- | --- | --- |
| `scorecard/build.bash` | `quay.io/redhat-java-monitoring/cryostat-operator-scorecard-app` | Absent; the Operator must inject it |
| `scorecard-agent/build.bash` | `quay.io/redhat-java-monitoring/cryostat-operator-scorecard-agent-app` | JAR at `/opt/cryostat/cryostat-agent-shaded.jar`; the test supplies JVM options, connection settings, and TLS |

The bundled variant reuses the source and Containerfile in `scorecard`. Its JAR
comes from `AGENT_INIT_IMG` (default
`quay.io/cryostat/cryostat-agent-init:latest`), the same artifact used for Operator
injection. CI sets `CRYOSTAT_AGENT_VERSION`, which selects the matching init-image
tag (lowercased to match the published tags). `AGENT_INIT_IMG` overrides the
complete init-image reference.

Both scripts use Podman, build AMD64 and ARM64 images by default, and only publish
when `PUSH_MANIFEST=true`. They follow the existing CI interface: `APP_REGISTRY`,
`APP_NAMESPACE`, `APP_NAME`, `BUILD_TAG`, `TAGS`, and `ARCHS`. `APP_VERSION`
overrides `BUILD_TAG`; `APP_IMAGE` overrides the complete tagged image reference.
PR CI builds AMD64 without publishing; the publishing workflow automatically
discovers both scripts and publishes version, date, and `latest` tags under
`redhat-java-monitoring`.

Build locally without publishing:

```sh
ARCHS=amd64 APP_IMAGE=localhost/scorecard-app:test bash scorecard/build.bash
ARCHS=amd64 APP_IMAGE=localhost/scorecard-agent-app:test bash scorecard-agent/build.bash
```

From a Cryostat Operator checkout, build these images and serve them through its
local Kind registry without publishing to Quay:

```sh
SCORECARD_APPLICATIONS_DIR=/path/to/test-applications \
OPERATOR_IMG=quay.io/cryostat/cryostat-operator:latest \
CORE_IMG=quay.io/cryostat/cryostat:latest \
SCORECARD_TEST_SELECTION=cryostat-agent,cryostat-agent-autoconfig \
make test-scorecard-local-kind
```
