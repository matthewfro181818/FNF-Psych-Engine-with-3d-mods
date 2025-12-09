#!/bin/sh
cd ../../
haxelib run lime build cpp -release -D officialBuild
cd ./export/release/