#!/bin/bash
# Export the web build and refresh the artifact files. Then publish hollowmere.html with files ["game.pck.wasm"].
S=/tmp/claude-0/-home-claude/9fd3ebd8-6124-5fea-acc2-46b3e0a9118c/scratchpad; cd $S/MagicVillage
B=$(date +%Y%m%d-%H%M); sed -i "s/build [0-9]*-[0-9]*  ·/build $B  ·/" ui/hud.gd
rm -rf $S/web; mkdir -p $S/web; $S/dl/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --export-release "Web" $S/web/index.html 2>&1 | grep SCRIPT
cp $S/web/index.pck $S/art2/game.pck.wasm; sed -i "s/const BUILD = '[^']*'/const BUILD = '$B'/" $S/art2/hollowmere.html; echo "build $B ready"
