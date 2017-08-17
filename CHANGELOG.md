## 0.1.2
Huge refactor for entire build system.

* Moving most of the overall logic to the Makefile at the root of the repo.
* Made building releases other than jessie alot more flexible, just export `RELEASE=debian/<codename>` before running `make build`.
* Removed binaries from the repo, they are downloaded, verified, and packed in their own units now.
* Removed scripts and functions from the repo, into their own repo, which is downloaded and moved in the image build phase.
* Added [goss](https://github.com/aelsabbahy/goss) for building serverspec tests automatically.
* Refactored CI environment functions.
