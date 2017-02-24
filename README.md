# gitweb-scraper

A tool to download patches from gitweb, and a second tool to rebuild a git
repository from them.

# Installation

1. Install [ObjFW](https://heap.zone/objfw/), and if you want TLS support,
   [ObjOpenSSL](https://heap.zone/git/?p=objopenssl.git)
2. Run `make`
3. Copy `gitweb-scraper` and `rebuild.sh` where you want to have them

# Usage

1. `gitweb-scraper http://example.com foo.git`
2. `rebuild.sh foo.patches foo-git`

# Problems

- Rebuilding repositories with non-linear history won't work well
- Commit hashes are not preserved: At least the _Commit_ and _CommitDate_
  properties of the rebuilt commits will be different.
