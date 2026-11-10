#!/usr/bin/env bash
#
# Build the reference flavour.
#
# One command, the way the academy's build lab will do it, so that the
# reference implementation and the lab's pipeline exercise the same path.
#
# Usage:
#   tools/build-reference.sh [-k <keyring home>] [-w <work dir>] [-o <out dir>]
#
# Without a keyring home, the image is built unsigned. With one — created by
# fork/tools/init-signing-key.sh — the root filesystem is signed and the key
# is embedded in the initramfs so the boot can verify it.

set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "${repo_root}"

work_dir="${repo_root}/work"
out_dir="${repo_root}/out"
keyring_home=""
gpg_args=()

while getopts 'k:w:o:h' opt; do
    case "${opt}" in
        k) keyring_home="${OPTARG}" ;;
        w) work_dir="${OPTARG}" ;;
        o) out_dir="${OPTARG}" ;;
        h)
            sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            printf 'unknown option: %s\n' "${OPTARG}" >&2
            exit 1
            ;;
    esac
done

if [[ -n "${keyring_home}" ]]; then
    if [[ ! -d "${keyring_home}" ]]; then
        printf 'error: keyring home %s does not exist.\n' "${keyring_home}" >&2
        printf '       Create one with fork/tools/init-signing-key.sh\n' >&2
        exit 1
    fi
    export GNUPGHOME="${keyring_home}"

    fingerprint="$(gpg --batch --with-colons --list-keys | awk -F: '/^fpr:/ {print $10; exit}')"
    if [[ -z "${fingerprint}" ]]; then
        printf 'error: no key found in %s\n' "${keyring_home}" >&2
        exit 1
    fi
    gpg_args=(-g "${fingerprint}")
    printf 'Signing the root filesystem with %s\n\n' "${fingerprint}"
else
    printf 'Building unsigned. Pass -k <keyring home> to sign the image.\n\n'
fi

mkdir -p -- "${out_dir}"

exec ./archiso/mkarchiso \
    --work-dir "${work_dir}" \
    --out-dir "${out_dir}" \
    "${gpg_args[@]}" \
    fork/profile
