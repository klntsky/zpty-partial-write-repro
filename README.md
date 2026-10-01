# Nonblocking zpty partial-write reproduction

`zpty -w -n` can return success while truncating input on a PTY created with `zpty -b`.

## Run

```sh
git clone https://github.com/klntsky/zpty-partial-write-repro.git
cd zpty-partial-write-repro
zsh -f repro.zsh
```

Requires Zsh, `stty`, and `sleep`. The child delays reading to create backpressure; the test counts delivered bytes and cleans up its PTY.

## Observed result

Zsh 5.9 on Linux x86_64:

```text
WRITE_STATUS=0 SENT=200000
RECEIVED=11776
REPRODUCED: successful write with truncated input
```

Byte counts may vary. Test exit codes: 0 = reproduced, 1 = not reproduced, 2 = test error.
