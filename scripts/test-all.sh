#!/bin/bash
# Runs every check of the app: the translations (scripts/gen-i18n.py --check), the glance's texts
# (scripts/check-glance-strings.py), then the unit tests, in one test build run in the Connect IQ simulator.
# Prints one line per step and exits 0 only when every step passes.
#
# Usage:  DEVELOPER_KEY=/path/to/developer_key.der scripts/test-all.sh
#
# Environment:
#   DEVELOPER_KEY  key that signs the test build (required; any developer key works for tests)
#   CIQ_SDK        Connect IQ SDK folder (default: the SDK chosen in the SDK Manager, else the one that
#                  holds the monkeyc on the PATH)
#   TEST_OUT       folder for the build and its logs (default: bin/test)
#   TEST_TIMEOUT   seconds a run may take before it counts as hung (default: 300)
#
# Needs a running simulator (connectiq &), Java 17 or later on the PATH, perl and python3.
#
# The translations' check fails when a language leaves a text out or adds a placeholder, or when the files
# scripts/gen-i18n.py generates are stale: the compiler cannot tell, since the texts are JSON data. The
# glance's check comes next: a slip there crashes the glance on the watch only. A build warning
# fails the tests. A run talks to the simulator through MonkeyDoDeux, which this script starts in its own
# process group: a run that hangs is stopped at the timeout together with everything it started, so it
# leaves no client connected to the simulator, and is tried once more. A run's result counts only when its
# output names this suite ("suite=oraciones", logged by source/I18nTests.mc).
set -u
cd "$(dirname "$0")/.." || exit 2

DEVICE=instinct2
OUT="${TEST_OUT:-bin/test}"
TIMEOUT="${TEST_TIMEOUT:-300}"
SDK_CONFIG="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"

if [ -z "${DEVELOPER_KEY:-}" ] || [ ! -f "$DEVELOPER_KEY" ]; then
    echo "Set DEVELOPER_KEY to a developer key file (.der)." >&2
    exit 2
fi

SDK="${CIQ_SDK:-}"
if [ -z "$SDK" ] && [ -f "$SDK_CONFIG" ]; then
    SDK="$(head -n 1 "$SDK_CONFIG")"
fi
if [ -z "$SDK" ] && command -v monkeyc > /dev/null; then
    SDK="$(dirname "$(dirname "$(command -v monkeyc)")")"
fi
SDK="${SDK%/}"
if [ ! -x "$SDK/bin/monkeyc" ]; then
    echo "Connect IQ SDK not found: set CIQ_SDK to its folder." >&2
    exit 2
fi

mkdir -p "$OUT"

python3 scripts/gen-i18n.py --check || exit 1
python3 scripts/check-glance-strings.py || exit 1

# Runs a test build in the simulator, its output in a log. MonkeyDoDeux is what the SDK's monkeydo script
# starts; running it directly, in a new process group, lets the timeout stop it and every process it
# started. Exit status 124 means the run hung.
run_suite() {
    local prg="$1" log="$2"
    perl -e '
        my $timeout = shift;
        my $pid = fork();
        die "fork: $!\n" unless defined $pid;
        if ($pid == 0) {
            setpgrp(0, 0);
            exec @ARGV or die "exec: $!\n";
        }
        $SIG{ALRM} = sub { kill "TERM", -$pid; sleep 1; kill "KILL", -$pid; exit 124; };
        alarm $timeout;
        waitpid($pid, 0);
        my $status = $? >> 8;
        alarm 0;
        kill "TERM", -$pid;
        exit $status;
    ' "$TIMEOUT" java -classpath "$SDK/bin/monkeybrains.jar" com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux \
        -f "$prg" -d "$DEVICE" -s "$SDK/bin/shell" -t > "$log" 2>&1
}

# The suite's result line, "PASSED (passed=N, failed=0, errors=0)" or "FAILED (...)", when the log holds
# this suite's own output; nothing otherwise. (monkeydo -t exits 1 even when every test passes, so the exit
# status says nothing.)
suite_result() {
    local log="$1"
    grep -Eq "suite=oraciones( |\$)" "$log" || return 0
    grep -E '^(PASSED|FAILED) \(passed=' "$log" | tail -n 1
}

prg="$OUT/OracionesTest.prg"
build_log="$OUT/OracionesTest.build.log"
run_log="$OUT/OracionesTest.log"
if ! "$SDK/bin/monkeyc" -f monkey.jungle -d "$DEVICE" -o "$prg" -y "$DEVELOPER_KEY" -w -t > "$build_log" 2>&1; then
    echo "Tests FAILED (build): $build_log"
    exit 1
fi
warnings="$(grep -c 'WARNING' "$build_log")"
if [ "$warnings" -gt 0 ]; then
    echo "Tests FAILED ($warnings build warnings): $build_log"
    exit 1
fi
result=""
for attempt in 1 2; do
    run_suite "$prg" "$run_log"
    result="$(suite_result "$run_log")"
    [ -n "$result" ] && break
done
if [ -z "$result" ]; then
    echo "Tests FAILED (no result from the simulator after 2 runs): $run_log"
    exit 1
fi
if [ "${result%% *}" = "PASSED" ]; then
    echo "Tests $result"
    exit 0
fi
echo "Tests $result: $run_log"
exit 1
