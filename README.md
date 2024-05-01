To Build:

1) Run `./scripts/init-repo.sh` (should be called outside of docker for git credentials access).
2) Run `./scripts/build-container.sh`.
3) Run `./scripts/launch-container.sh` (this will request a password for sudo access by the docker user).
4) From inside the docker container, run `./scripts/initial-build.sh`.
5) From inside the docker container, run `./scripts/compile-cheetah.sh`.

The handcomp_tests can now be built (inside the docker container) by cd'ing to src/cheetah/handcom_test, and running make.
