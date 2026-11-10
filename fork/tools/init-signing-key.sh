#!/usr/bin/env bash
#
# Generate the signing key for the reference flavour.
#
# One key does two jobs in an archiso build:
#
#   1. It signs the root filesystem image (airootfs.sfs.sig), which is what
#      mkinitcpio-archiso's hook looks for.
#   2. Its public half is imported into the pacman keyring of the image being
#      built, so the image already trusts the key that signed its repository.
#
# The second job is the one that matters for a flavour, and it is the one that
# is not documented upstream. `mkarchiso -g <keyid>` hands the key's public
# half to pacstrap through ARCHISO_GNUPG_FD, which imports it into the new
# root filesystem's /etc/pacman.d/gnupg.
#
# Usage:
#   init-signing-key.sh [gnupg_home]
#
# The keyring home defaults to ./gnupg next to this script. It is NOT
# committed to the repository — a signing key that lives in git is a signing
# key that has been handed to everyone who cloned it.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
gnupg_home="${1:-${script_dir}/gnupg}"

if [[ -e "${gnupg_home}" ]]; then
    printf 'error: %s already exists.\n' "${gnupg_home}" >&2
    printf '       Remove it first if you really mean to start over.\n' >&2
    exit 1
fi

mkdir -m 0700 -- "${gnupg_home}"
export GNUPGHOME="${gnupg_home}"

printf 'Generating a signing key in %s\n' "${gnupg_home}"
printf 'This takes a moment. The passphrase is deliberately empty: the key is\n'
printf 'used by unattended builds, and it is a development key, not a release key.\n\n'

gpg --batch --quiet --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Name-Real: Vesper Linux
Name-Email: vesper@localhost
Expire-Date: 0
%commit
EOF

fingerprint="$(gpg --batch --with-colons --list-keys | awk -F: '/^fpr:/ {print $10; exit}')"

printf '\nDone.\n\n'
printf 'Fingerprint: %s\n\n' "${fingerprint}"
printf 'Use it like this:\n\n'
printf '    ./archiso/mkarchiso -w work -o out -g %s fork/profile\n\n' "${fingerprint}"
printf 'Or set it in the profile:\n\n'
printf '    gpg_key="%s"\n\n' "${fingerprint}"
printf 'The private key stays in %s. Do not commit it.\n' "${gnupg_home}"
