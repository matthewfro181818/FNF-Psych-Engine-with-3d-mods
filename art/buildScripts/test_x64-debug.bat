@echo off
color 0a
cd ../..
echo BUILDING GAME
haxelib run lime test windows -debug -D officialBuild
echo.
echo done.
pause