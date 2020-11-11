---
title: "Idea about decentralized naming system"
date: 2020-11-11
---

Genesis
-------

I was investigating PeerTube vs LBRY as YouTube alternative, and I came to a
mixed conclusion:

- LBRY seems more popular in the content creators I follow
- With PeerTube you own the data you publish
- With LBRY, a simple PC with the app left open is enough to publish content for
  non tech people
- With PeerTube you can be censored from the Fediverse as it happened already
  with [Gab](http://gab.com). I also heard that some PeerTube instances were
  enforcing a COVID19 policy, how long before this policy is enforced in
  PeerTube peering?
- With LBRY, there is no censorship possible, but you cannot take down illegal
  content
- LBRY can only work because of a blockchain where you need to spend LBC tokens
  for every action (except looking at the content). You need coin to create a
  channel, create a content, publish a comment. For the moment LBRY Inc is
  liberally giving out credits, but how can it work long term?

LBRY makes use of its coin to claim a name. For content publishing, it uses a
BitTorrent-like protocol. The blockchain serves as a database for all the
available content, and content is indexed by name which requires LBC to
register.

Thus, I'm thinking at solutions to avoid this blockchain, and because the issue
is with name claiming, I'm thinking about a generic solution to that problem.
That could also help with DNS.

Also, LBRY name claiming is quite ingenious. Instead of spending a fixed amount
of coins to register a name, you block an amount of coins, and you can get back
your coins when you decide to unregister the name you claimed. If a name is
popular, someone else can bid a higher amount on the same name and there is a
system that takes into account the duration you had the name in possession that
may eventually award the name to the highest bidder. It's a better scheme than
first come first served.

Solutions
---------

- Blockchains is great to build consensus, but there is no need to have coins on
top of them. Merkle-trees can be constructed with arbitrary data in it and there
is no need to reuse the Bitcoin code and logic that much.

- Proof of Work is mostly there to avoid Sybil attack. However there exists the
Duniter project that aims at creating a free money system that has a web of
trust ensuring that for each registered account, there is a unique human behind.
Reusing this, we can ensure that participants in a blockchain are unique humans.

Naming system
-------------

- A blockchain database where each block can contain:

    - A name registration, associated with any kind of data (limited in length).
      It could be an IP address, a Torrent(-like) hash or anything really. A
      public key and duration will be associated with each registration.

    - a name revocation that can happen automatically (by forging nodes) when a
      name expires or manually (with a signed revocation document)

    - a forger key signed by a human member

    - a forger key revocation

- Blocks also contain reference to a previous block, universal time, block
  count, hash, forger identification and signature

- Blockchain forgers that are freely providing the service.

    - A forger has a unique key pair, each block is signed by the forger key
    - The public key must be signed by a Duniter/Ğ1 active member
    - The key expires when the above signature expires, when the Duniter/Ğ1
      member expires or when a revocation document is published

- Forgers are sharing pending operations that must be included in the next block

- Deterministic algorithm decides who should forge the next block among the
  active forgers. If a block is not forged, the next forger decided by the
  algorithm should forge the block in a next timeslot.

  This might be the most difficult and a proof of work might help not having two
  blocks created concurrently.

- Anyone can submit to any forger a pending operation

### Resolve name squatting

A name bidding system can be added on top of that where some Ğ1 money is left on
a Ğ1 non member account. The name is valid as long as this account keeps its
money. If it is withdrawn, the name is no longer valid. Someone else could place
a bid with a higher amount on another account to claim the name.

### Future-proof

Blocks older than a year can be forgotten if every operation on the blockchain
has an expiration duration of a year. Forger public keys will need to be signed
again and name registered again. If you forging node is offline for more than a
year, it makes sense to resynchronize the full blockchain.

### Sharing operations before making a block and sharing new blocks

A flood algorithm might be needed. Bloom filters can come in handy.

### Resolve forks

Either:

- A deterministic algorithm decides which forger wins, the operations from the
  diverging blocks operations are put back in the pending operations

- A deterministic merge block is generated and published (not signed by a
  forger, the merge block should be generated identically across all forgers)

