#!/bin/bash
##
##  Determine modified packages and build/upload them.
##

set -e

## Some packages should be excluded from auto builds.
EXCLUDED_PACKAGES="lldb rust texlive"

###############################################################################
##
##  Determining changes.
##
###############################################################################

set +e

REPO_DIR=$(realpath "$(dirname "$(realpath "$0")")/../../../")
cd "$REPO_DIR" || {
	echo "[!] Failed to cd into '$REPO_DIR'."
	exit 1
}

# Some environment variables are important for correct functionality
# of this script.
if [ -z "$CIRRUS_CHANGE_IN_REPO" ]; then
	echo "[!] CIRRUS_CHANGE_IN_REPO is not set."
	exit 1
fi

if [ -n "$CIRRUS_PR" ] && [ -z "$CIRRUS_BASE_SHA" ]; then
	echo "[!] CIRRUS_BASE_SHA is not set."
	exit 1
fi

# Process tag '%ci:no-build' that may be added as line to commit message.
# Will force CI to exit with status 'passed' without performing build.
if grep -qiP '^\s*%ci:no-build\s*$' <(git log --format="%B" -n 1 "$CIRRUS_CHANGE_IN_REPO"); then
	echo "[!] Exiting with status 'passed' (tag '%ci:no-build' applied)."
	exit 0
fi

# Process tag '%ci:reset-backlog' that may be added as line to commit message.
# Will force CI to build changes only for the current commit.
if grep -qiP '^\s*%ci:reset-backlog\s*$' <(git log --format="%B" -n 1 "$CIRRUS_CHANGE_IN_REPO"); then
	echo "[!] Building only last pushed commit (tag '%ci:reset-backlog' applied)."
	unset CIRRUS_LAST_GREEN_CHANGE
	unset CIRRUS_BASE_SHA
fi

if [ -z "$CIRRUS_PR" ]; then
	# Changes determined from the last commit where CI finished with status
	# 'passed' (green) and the top commit.
	if [ -z "$CIRRUS_LAST_GREEN_CHANGE" ]; then
		GIT_CHANGES="$CIRRUS_CHANGE_IN_REPO"
	else
		GIT_CHANGES="${CIRRUS_LAST_GREEN_CHANGE}..${CIRRUS_CHANGE_IN_REPO}"
	fi
	echo "[*] Changes: $GIT_CHANGES"
else
	# Changes in pull request are determined from commits between the
	# top commit of base branch and latest commit of PR's branch.
	GIT_CHANGES="${CIRRUS_BASE_SHA}..${CIRRUS_CHANGE_IN_REPO}"
	echo "[*] Pull request: https://github.com/termux/termux-packages/pull/${CIRRUS_PR}"
fi

# Determine changes from commit range.
CHANGED_FILES=$(git diff-tree --no-commit-id --name-only -r "$GIT_CHANGES" 2>/dev/null)

# Modified packages.
PACKAGE_NAMES=$(sed -nE 's@^packages/([^/]*)/build.sh@\1@p' <<< "$CHANGED_FILES")

# Docker scripts.
DOCKER_SCRIPTS=$(grep -P '^scripts/(Dockerfile|properties.sh|setup-android-sdk.sh|setup-ubuntu.sh)$' <<< "$CHANGED_FILES")
[ -n "$DOCKER_SCRIPTS" ] && DOCKER_IMAGE_UPDATE_NEEDED=true || DOCKER_IMAGE_UPDATE_NEEDED=false

unset CHANGED_FILES

## Filter deleted packages.
for pkg in $PACKAGE_NAMES; do
	if [ ! -d "${REPO_DIR}/packages/${pkg}" ]; then
		PACKAGE_NAMES=$(sed -E "s/(^|\s\s*)${pkg}(\$|\s\s*)/ /g" <<< "$PACKAGE_NAMES")
	fi
done

## Filter excluded packages.
for pkg in $EXCLUDED_PACKAGES; do
	PACKAGE_NAMES=$(sed -E "s/(^|\s\s*)${pkg}(\$|\s\s*)/ /g" <<< "$PACKAGE_NAMES")
done
unset pkg

## Remove trailing spaces.
PACKAGE_NAMES=$(sed 's/[[:blank:]]*$//' <<< "$PACKAGE_NAMES")

set -e

###############################################################################
##
##  Executing requested actions. Only one per script session.
##
###############################################################################

case "$1" in
	--update-docker)
		if $DOCKER_IMAGE_UPDATE_NEEDED; then
			if [ "$CIRRUS_BRANCH" != "master" ]; then
				echo "[!] Refusing to update docker image on non-master branch."
				exit 1
			fi

			if [ -z "$DOCKER_USERNAME" ]; then
				echo "[!] Can't update docker image without Docker Hub user name."
				exit 1
			fi

			if [ -z "$DOCKER_PASSWORD" ]; then
				echo "[!] Can't update docker image without Docker Hub password."
				exit 1
			fi

			cd "${REPO_DIR}/scripts"

			docker build --tag termux/package-builder:latest .
			docker login --username "$DOCKER_USERNAME" --password "$DOCKER_PASSWORD"
			docker push termux/package-builder:latest
		else
			echo "[*] No need to update docker image."
			exit 0
		fi
		;;
	--upload)
		if [ -n "$PACKAGE_NAMES" ]; then
			if [ "$CIRRUS_BRANCH" != "master" ]; then
				echo "[!] Refusing to upload packages on non-master branch."
				exit 1
			fi

			if [ -z "$BINTRAY_API_KEY" ]; then
				echo "[!] Can't upload packages without Bintray API key."
				exit 1
			fi

			if [ -z "$BINTRAY_GPG_PASSPHRASE" ]; then
				echo "[!] Can't upload packages without GPG passphrase."
				exit 1
			fi

			echo "[*] Uploading packages to Bintray:"
			"${REPO_DIR}/scripts/package_uploader.sh" -p "${PWD}/debs" $PACKAGE_NAMES
		else
			echo "[*] No modified packages found."
			exit 0
		fi
		;;
	*)
		if [ -n "$PACKAGE_NAMES" ]; then
			echo "[*] Building packages:" $PACKAGE_NAMES
			./build-package.sh -a "$TERMUX_ARCH" -I $PACKAGE_NAMES
		else
			echo "[*] No modified packages found."
			exit 0
		fi
		;;
esac
