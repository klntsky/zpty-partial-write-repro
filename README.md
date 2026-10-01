# Nonblocking zpty partial-write reproduction

Standalone demonstration that `zpty -w -n` can return success while delivering only a prefix of a string to a PTY created with `zpty -b`.

## Run

Requires Zsh with `zsh/zpty`, `zsh/zselect`, and `zsh/system`, plus `stty` and `sleep`. No network access or third-party packages are used by the test.

```sh
git clone https://github.com/klntsky/zpty-partial-write-repro.git
cd zpty-partial-write-repro
zsh -f repro.zsh
```

The test creates a temporary child PTY and cleans it up on exit. It does not change the invoking terminal's settings.

## Observed result

Tested with `zsh 5.9 (x86_64-ubuntu-linux-gnu)` on Linux:

```text
WRITE_STATUS=0 SENT=200000
RECEIVED=11776
REPRODUCED: successful write with truncated input
```

The exact received byte count is platform- and scheduling-dependent. Exit status 0 means the partial-write behavior was reproduced; 1 means it was not; 2 indicates test setup or reporting failure.

## Method

The child disables terminal echo and canonical input processing, announces readiness, and delays reading for half a second. The parent sends 200,000 ASCII characters in one nonblocking `zpty -w -n` call. The child then counts received bytes until a 0.3-second read timeout.

This deliberately creates backpressure. Partial nonblocking writes are expected at the system-call level; the question is whether the shell API should silently discard the remainder while returning success and exposing no byte count.

## Upstream context

- [Zsh 5.9 implementation](https://github.com/zsh-users/zsh/blob/zsh-5.9/Src/Modules/zpty.c#L714): `ptywritestr()` returns `!all` on a would-block error, so any positive byte count yields success.
- [November 2000 commit introducing this behavior](https://github.com/zsh-users/zsh/commit/dbc0aebcd44a028ed5c5c392fa2b354a1b562955).
- [Zsh manual](https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fzpty-Module): warns about incomplete copying for the stdin form, but does not clearly explain successful partial writes for string arguments.

This repository demonstrates the behavior, not a claim that upstream has classified it as a bug.
