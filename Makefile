.PHONY: build test app install package clean

build:
	swift build

test:
	swift test

app:
	./scripts/build_app.sh

install:
	./scripts/install_app.sh

package:
	./scripts/package_release.sh

clean:
	swift package clean
