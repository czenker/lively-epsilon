#!/usr/bin/env bash
set -eux

VERSION=$(git describe HEAD || echo "dev")
BUILD_DIR="_build/lively_epsilon/"

echo "Building version ${VERSION}..."

ZIPFILE="$(pwd)/release-${VERSION}.zip"
GZFILE="$(pwd)/release-${VERSION}.tar.gz"
XZFILE="$(pwd)/release-${VERSION}.tar.xz"

rm -rf _build $ZIPFILE $GZFILE $XZFILE
mkdir -p _build/lively_epsilon

echo "$VERSION" > _build/lively_epsilon/VERSION.txt

cp -r src/ "_build/lively_epsilon/src"
cp Readme.md LICENSE init.lua "_build/lively_epsilon/"

cp -r docs/_build/ "_build/lively_epsilon/docs"

cd _build

zip -Jr $ZIPFILE *
tar -czf $GZFILE *
tar -cjf $XZFILE *
