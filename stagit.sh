#!/bin/sh -e

renice -n 17 $$

mkdir -p /var/www/git/
cd /var/www/git/

for d in /git/*.git/; do (
	name=$(basename "$d")
	name=${name%.git}
	mkdir -p "$name"
	cd "$name"
	stagit -l 50 "$d"
	stagit-gopher -b /git/"$name" -l 50 "$d"
) done

stagit-index /git/*.git/ > index.html
stagit-gopher-index -b /git /git/*.git/ > index.gph

