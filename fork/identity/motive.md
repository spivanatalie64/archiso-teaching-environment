# Vesper — motive

Why Vesper exists at all, given that Arch Linux already exists and does most of
this well.

## The motive

**The last mile of a distribution is trust, and nobody teaches it.**

Building a custom Arch ISO is a solved exercise. There are a hundred tutorials
that will get you a rebranded medium with your wallpaper on it. What none of
them cover is the step where you add a package *you* built, signed with a key
*you* generated, to a repository *you* host — and make an image that trusts it.

That step is the actual boundary between "custom ISO" and "distribution". It
is also the step where most people give up, because it is genuinely awkward: two
different pacman configurations (the one that builds the image, and the one
inside the image), a keyring that has to be populated at exactly the right
moment, and a signature policy that has to be decided rather than inherited.

So this repository exists to teach that step, and to teach it with something
real underneath it.

## The audience

Arch users who want their own ISO — not to run a distribution, but to
understand what they are actually doing when they build one.

There is a second audience, the people who intend to run a distribution, and
they get the same material with the depth turned up: lessons 04 through 07
cover the repository, the trust boundary, publishing, and the long, unglamorous
work of keeping a fork alive against upstream churn.

## Why the fork is fictional

Every lesson in this repository runs against **Vesper**, a distribution that
does not exist and is not meant to. It is fictional in the way a worked example
in a textbook is fictional: it has exactly the properties the lesson needs and
none of the baggage of a real project. No infrastructure, no accounts, no keys
that matter. A student forks Vesper without asking anyone's permission.

## Why the rice is the hook

Nobody reads a packaging tutorial for the packaging. People read it because they
want their own system, with their own name on it, looking like theirs.

So Vesper carries a rice — a theme, a boot menu, a wallpaper — that exists to be
replaced. The reader is meant to arrive with their own identity and find every
place it needs to go. The rice is the reason they are reading. The trust
boundary is the reason the repository is worth their time.
