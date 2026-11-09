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
