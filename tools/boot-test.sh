#!/usr/bin/env bash
#
# Boot-test an image headlessly and check that it comes up.
#
# This is the check the build pipeline runs before it hands an ISO to anybody.
# A learner's first build failing for infrastructure reasons they cannot see
# is the worst outcome the academy can produce, so the pipeline verifies its
# own image first.
#
# The image is booted under QEMU with the serial console as the only output.
# The reference profile puts `console=tty0 console=ttyS0,115200` on the kernel
# command line precisely so this works; without it the test would see nothing
# and pass vacuously.
#
# Usage:
#   tools/boot-test.sh <image.iso> [--bios]
#
# Exit status:
#   0  the image booted to a login prompt
#   1  it did not, or QEMU could not be started

set -euo pipefail

if [[ $# -lt 1 ]]; then
    printf 'usage: %s <image.iso> [--bios]\n' "${0##*/}" >&2
    exit 1
fi

image="$(realpath -- "$1")"
shift

boot_mode='uefi'
if [[ "${1:-}" == '--bios' ]]; then
    boot_mode='bios'
    shift
fi

if [[ ! -f "${image}" ]]; then
    printf 'error: %s does not exist\n' "${image}" >&2
    exit 1
fi

for tool in qemu-system-x86_64 timeout; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        printf 'error: %s is not installed\n' "${tool}" >&2
        exit 1
    fi
done

work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT

log="${work}/serial.log"

qemu_args=(
    -machine 'type=q35,smm=on,usb=on'
    -cpu max
    -smp 2
    -global ICH9-LPC.disable_s3=1
    -vga virtio
    -m 2048
    -drive "file=${image},format=raw,media=cdrom,readonly=on"
    -display none
    -serial stdio
    -no-reboot
)

if [[ "${boot_mode}" == 'uefi' ]]; then
    code='/usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd'
    vars='/usr/share/edk2/x64/OVMF_VARS.4m.fd'
    for f in "${code}" "${vars}"; do
        if [[ ! -f "${f}" ]]; then
            printf 'error: %s is missing. Install edk2-ovmf.\n' "${f}" >&2
            exit 1
        fi
    done
    cp -f -- "${vars}" "${work}/OVMF_VARS.4m.fd"
    qemu_args+=(
        -drive "if=pflash,format=raw,unit=0,file=${code},read-only=on"
        -drive "if=pflash,format=raw,unit=1,file=${work}/OVMF_VARS.4m.fd"
    )
fi

printf 'Boot-testing %s (%s mode)...\n' "${image##*/}" "${boot_mode}"

# The timeout is generous on purpose. The keyring initialisation alone takes
# a while, and a test that gives up early reports failures that are really
# just impatience. Override it with BOOT_TEST_TIMEOUT when testing the test.
timeout "${BOOT_TEST_TIMEOUT:-300}" qemu-system-x86_64 "${qemu_args[@]}" >"${log}" 2>&1 || true

clean() {
    sed -e 's/\x1b\[[0-9;?]*[a-zA-Z]//g' -e 's/\r//g' "${log}"
}

if ! clean | grep -q 'login:'; then
    printf 'FAIL: the image did not reach a login prompt.\n' >&2
    printf 'Last lines of the serial console:\n' >&2
    clean | tail -25 | sed 's/^/  /' >&2
    exit 1
fi

printf 'PASS: the image booted to a login prompt.\n'

# Report what the boot said about the keyring, because a missing keyring is
# invisible until someone tries to install a package.
if clean | grep -q 'Mounted Temporary /etc/pacman.d/gnupg directory'; then
    printf '      the pacman keyring was mounted.\n'
else
    printf 'WARN: the log does not mention the pacman keyring mount.\n' >&2
    printf '      pacman inside this image probably cannot install anything.\n' >&2
fi
