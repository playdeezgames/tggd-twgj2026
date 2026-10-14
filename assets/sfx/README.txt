Sound effects for Grandma Drives.

Generated with jsfxr (https://sfxr.me), the browser port of Dr Petter's sfxr, using its preset
generators (click, tone, hitHurt, pickupCoin, explosion, jump, powerUp) with a fixed random seed,
then made deliberately worse: low sample rates, vibrato, phaser, stutter and wrong-note
arpeggios. web/index.html also detunes each effect by a random amount every time it plays.
Files are in the order of the Sound enum in src/game/game.odin:

  putt, honk, brake, obey, wrong, timeout, loud_mute, arrive

The radio hymn is synthesised live by web/index.html and is not a file.
