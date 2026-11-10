#!/usr/bin/env bash
#
# Verify that the upstream tree has not been modified.
#
# This repository carries an unmodified copy of upstream archiso, and that is
# the whole reason it can be used to teach from: a reader who reads
# archiso/mkarchiso is reading upstream's code, and a reader who hits a bug
# can go and file it against the real thing.
#
# The check therefore has to catch two things:
#
#   1. a tracked file under an upstream path was modified
#   2. a new file was added under an upstream path
#
# Both are invisible in a casual `git status` if the upstream tree is large,
# and both break the promise this repository makes.
#
# README.rst is the one deliberate exception. It is the repository's front
# door, so it carries a notice about what this repository is, above the
# upstream text. The upstream text itself must still be there, byte for byte,
# below the notice — so instead of requiring the file to be untouched, the
# check requires the upstream version to still be contained in it.
#
# Usage:
#   check-upstream-pristine.sh [base_ref]
#
# base_ref defaults to master, the branch this repository forked from.

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "${repo_root}"

base_ref="${1:-master}"

# The paths that belong to upstream archiso and must not be touched.
upstream_paths=(
    archiso
    configs
    docs
    man
    scripts
    Makefile
    .gitlab-ci.yml
)

if ! git rev-parse --verify --quiet "${base_ref}" >/dev/null; then
    printf 'error: base ref %s does not exist in this repository.\n' "${base_ref}" >&2
    exit 1
fi

status=0

# 1. Files changed or added relative to the base ref.
changed="$(git diff --name-only "${base_ref}"..HEAD -- "${upstream_paths[@]}" || true)"
if [[ -n "${changed}" ]]; then
    printf 'FAIL: upstream paths differ from %s:\n' "${base_ref}" >&2
    printf '%s\n' "${changed}" | sed 's/^/  /' >&2
    status=1
fi

# 2. Uncommitted changes under the upstream paths.
dirty="$(git status --porcelain -- "${upstream_paths[@]}" || true)"
if [[ -n "${dirty}" ]]; then
    printf 'FAIL: uncommitted changes under upstream paths:\n' >&2
    printf '%s\n' "${dirty}" | sed 's/^/  /' >&2
    status=1
fi

# 3. Untracked files under the upstream paths, which neither check above sees.
untracked="$(git ls-files --others --exclude-standard -- "${upstream_paths[@]}" || true)"
if [[ -n "${untracked}" ]]; then
    printf 'FAIL: untracked files under upstream paths:\n' >&2
    printf '%s\n' "${untracked}" | sed 's/^/  /' >&2
    status=1
fi

# 4. The upstream README must survive intact below the repository's notice.
#    The upstream text starts at the first line that is exactly "=======",
#    which is the top of the upstream title block.
upstream_readme="$(mktemp)"
current_upstream="$(mktemp)"
trap 'rm -f -- "${upstream_readme}" "${current_upstream}"' EXIT

git show "${base_ref}:README.rst" >"${upstream_readme}"
sed -n '/^=======$/,$p' README.rst >"${current_upstream}"

if ! diff -u "${upstream_readme}" "${current_upstream}" >/dev/null 2>&1; then
    printf 'FAIL: the upstream README text was modified or removed\n' >&2
    diff -u "${upstream_readme}" "${current_upstream}" | head -20 | sed 's/^/  /' >&2
    status=1
fi

if (( status == 0 )); then
    printf 'PASS: the upstream tree is unmodified (base ref: %s).\n' "${base_ref}"
else
    printf '\nThe upstream tree is the substrate the academy teaches from.\n' >&2
    printf 'Keep new material in a new top-level directory instead.\n' >&2
fi

exit "${status}"
