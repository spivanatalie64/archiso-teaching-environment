# Vesper — mission

**Vesper is a Linux distribution you can rebuild from a single public repository.**

Every byte of a Vesper image is accounted for by something in git: the package
list, the pacman configuration, the boot menu, the identity documents, and the
signing key that establishes trust inside the image. Clone the repository, run
one command on an Arch Linux machine, and you get the same ISO — not a similar
one, the same one.

That is the whole ambition. Not "a nicer Arch". A system whose provenance is
inspectable end to end, where you can read the recipe and rebuild it without
asking anyone's permission.

## What this buys the reader

- **Provenance.** Nothing is fetched at build time that is not pinned. No mirror
  the profile did not choose, no host configuration leaking into the image.
- **Ownership of trust.** The key that signs the fork's packages is the same key
  that the image trusts. Nobody else can add software to a Vesper system.
- **Legibility.** A new user can read `fork/profile/profiledef.sh` and know what
  they are booting, before they boot it.

## What this does not claim

Vesper is not faster than Arch. It is not smaller. It is not more beautiful.
It is *reproducible and self-owned*, and that is a different, smaller, more
useful claim.
