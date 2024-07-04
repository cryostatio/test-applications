# test-applications

Container images for sample applications used in testing Cryostat. Each subdirectory represents a separate container image.

# building

Each subdirectory is expected to contain a `build.bash` file which can be invoked with no arguments to produce a container image.

The `build.bash` in this repository root will iterate over all the container image directories and build each.
