#!/bin/sh
# Copyright (C) 2017  Jonathan Neuschäfer <j.neuschaefer@gmx.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program, in the file LICENSE.GPLv2.

set -e

case "$#" in
	2)
		export PATCHES="$1"
		export GIT="$2"
		;;
	*)
		echo "Usage: $0 foo.patches/ foo-git"
		exit 1
		;;
esac

PATCHES="$(realpath "$PATCHES")"

git init "$GIT" && cd "$GIT"
for i in "$PATCHES"/*; do
	echo "$i"

	git am "$i"
done
git gc
