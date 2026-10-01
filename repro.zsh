#!/usr/bin/env zsh
# Run with: zsh -f repro.zsh
emulate -LR zsh
zmodload zsh/zpty || exit 2
zmodload zsh/zselect || exit 2

trap 'zpty -d probe 2>/dev/null' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Disable echo and canonical input processing before accepting the payload.
# Delay reading so the parent encounters a full PTY input buffer.
child='stty raw -echo; zmodload zsh/system; zmodload zsh/zselect; print READY; zselect -t 50; total=0; while sysread -t 0.3 -s 65536 chunk; do (( total += ${#chunk} )); done; print -r -- "RECEIVED=$total"; sleep 1'
zpty -b probe "$child" || exit 2

ready=0
for i in {1..200}; do
  if zpty -r probe output && [[ $output == *READY* ]]; then
    ready=1
    break
  fi
  zselect -t 1
done
if (( !ready )); then
  print -u2 'ERROR: child did not become ready'
  exit 2
fi

payload=${(l:200000::x:)}
zpty -w -n probe "$payload"
write_status=$?
print "WRITE_STATUS=$write_status SENT=${#payload}"

received=''
for i in {1..300}; do
  if zpty -r probe output; then
    received+=$output
    if [[ $received == *RECEIVED=*$'\n'* ]]; then
      break
    fi
  fi
  zselect -t 1
done
if [[ $received =~ 'RECEIVED=([0-9]+)' ]]; then
  count=$match[1]
  print "RECEIVED=$count"
else
  print -u2 'ERROR: child did not report a byte count'
  exit 2
fi

if (( write_status == 0 && count < ${#payload} )); then
  print 'REPRODUCED: successful write with truncated input'
  exit 0
fi
print 'NOT REPRODUCED: see counts above'
exit 1
