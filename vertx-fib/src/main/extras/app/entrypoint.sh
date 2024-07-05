#!/usr/bin/env bash

set -x
set -e

if [ -z "$HTTP_PORT" ]; then
    HTTP_PORT=8080
fi

if [ -z "$JMX_PORT" ]; then
    JMX_PORT=9093
fi

if [ -n "$START_DELAY" ]; then
    echo "Delaying start by $START_DELAY seconds..."
    sleep "$START_DELAY"
    echo "Continuing."
fi

FLAGS=(
    "-XX:+CrashOnOutOfMemoryError"
    "-Dcom.sun.management.jmxremote.autodiscovery=${USE_JDP:-true}"
    "-Dcom.sun.management.jmxremote.port=$JMX_PORT"
    "-Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT"
)

if [ -z "$HOSTNAME" ]; then
    FLAGS+=("-Djava.rmi.server.hostname=$HOSTNAME")
fi

if [ -n "$USE_SSL" ]; then
    FLAGS+=("-Dcom.sun.management.jmxremote.ssl=true")
    FLAGS+=("-Dcom.sun.management.jmxremote.registry.ssl=true")
    FLAGS+=("-Djavax.net.ssl.keyStore=/app/resources/keystore")
    FLAGS+=("-Djavax.net.ssl.keyStorePassword=vertx-fib-demo")
else
    FLAGS+=("-Dcom.sun.management.jmxremote.ssl=false")
    FLAGS+=("-Dcom.sun.management.jmxremote.registry.ssl=false")
fi

if [ -n "$USE_AUTH" ]; then
    d="$(mktemp -d)"
    cp /app/resources/jmxremote.password.in "${d}/jmxremote.password"
    chmod 400 "${d}/jmxremote.password"
    cp /app/resources/jmxremote.access.in "${d}/jmxremote.access"
    chmod 400 "${d}/jmxremote.access"
    FLAGS+=("-Dcom.sun.management.jmxremote.authenticate=true")
    FLAGS+=("-Dcom.sun.management.jmxremote.password.file=${d}/jmxremote.password")
    FLAGS+=("-Dcom.sun.management.jmxremote.access.file=${d}/jmxremote.access")
else
    FLAGS+=("-Dcom.sun.management.jmxremote.authenticate=false")
fi

if [ -n "$CLIENT_AUTH" ]; then
    FLAGS+=("-Dcom.sun.management.jmxremote.ssl.need.client.auth=true")
    FLAGS+=("-Djavax.net.ssl.trustStore=/truststore/truststore.p12")
    FLAGS+=("-Djavax.net.ssl.trustStorePassword=$KEYSTORE_PASS")
else
    FLAGS+=("-Dcom.sun.management.jmxremote.ssl.need.client.auth=false")
fi

exec java \
    "${FLAGS[@]}" \
    "$@" \
    -cp /app/resources:/app/classes:/app/libs/* \
    es.andrewazor.demo.Main \
    "$@"
