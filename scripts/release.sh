#!/bin/zsh
# Builds an ad-hoc signed universal release and zips it.
# Usage: scripts/release.sh            -> build/release/FxxkScroll-<version>.zip
#        scripts/release.sh --publish  -> also creates the GitHub release
set -euo pipefail
cd "$(dirname "$0")/.."

xcodegen generate --quiet
version=$(sed -n 's/.*MARKETING_VERSION: "\(.*\)"/\1/p' project.yml | head -1)
out=build/release
rm -rf "$out"

# Ad-hoc signing on purpose: no Apple Developer account, and a personal
# signing certificate would put its owner's details into the binary.
xcodebuild -project FxxkScroll.xcodeproj -scheme FxxkScroll -configuration Release \
  -derivedDataPath build/release-dd -destination 'generic/platform=macOS' \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= \
  build -quiet

mkdir -p "$out"
cp -R build/release-dd/Build/Products/Release/FxxkScroll.app "$out/"
codesign --verify --deep --strict "$out/FxxkScroll.app"
zip="$out/FxxkScroll-$version.zip"
ditto -c -k --keepParent "$out/FxxkScroll.app" "$zip"
shasum -a 256 "$zip"

if [[ "${1:-}" == "--publish" ]]; then
  gh release create "v$version" "$zip" --title "FxxkScroll $version" --notes-file docs/release-notes.md
fi
