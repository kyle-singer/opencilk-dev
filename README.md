To Build:

1) Run `./scripts/init-repo.sh` (should be called outside of docker for git credentials access).
2) Run `./scripts/build-container.sh`.
3) Run `./scripts/launch-container.sh` (this will request a password for sudo access by the docker user).
4) From inside the docker container (which starts in the scripts dir), run `./initial-build.sh`.
5) From inside the docker container, run `./compile-cheetah.sh`.

The OpenCilk compiler binaries should now be contained in build/opencilk/bin, and 2 versions of the runtime
in build/cheetah/<version>. The handcompiled tests for the 2 versions of the runtime are contianed in
directories within build/handcomp_test.
