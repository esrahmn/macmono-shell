#!/bin/bash
state="${XDG_RUNTIME_DIR:-$HOME/.cache}/macmono-record"
dir="$HOME/Videos/Recordings"

proc_start_time() {
    local stat rest
    local -a fields
    IFS= read -r stat < "/proc/$1/stat" || return 1
    rest=${stat##*) }
    [[ "$rest" != "$stat" ]] || return 1
    read -r -a fields <<< "$rest"
    [[ ${#fields[@]} -ge 20 ]] || return 1
    printf '%s\n' "${fields[19]}"
}

pid_is_running() {
    local comm stat rest process_state
    [[ -r "/proc/$1/comm" ]] || return 1
    IFS= read -r comm < "/proc/$1/comm" || return 1
    [[ "$comm" == "wf-recorder" ]] || return 1
    IFS= read -r stat < "/proc/$1/stat" || return 1
    rest=${stat##*) }
    [[ "$rest" != "$stat" ]] || return 1
    process_state=${rest%% *}
    [[ "$process_state" != "Z" && "$process_state" != "X" ]]
}

record_pid() {
    local pid expected_start actual_start
    local -a record_state
    [[ -r "$state" ]] || return 1
    mapfile -t record_state < "$state" || return 1
    pid="${record_state[0]:-}"
    expected_start="${record_state[2]:-}"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    pid_is_running "$pid" || return 1
    if [[ -n "$expected_start" ]]; then
        actual_start=$(proc_start_time "$pid") || return 1
        [[ "$actual_start" == "$expected_start" ]] || return 1
    fi
    printf '%s\n' "$pid"
}

stop_recorder_pid() {
    local pid="$1"
    kill -INT "$pid" 2>/dev/null || true
    for _ in $(seq 1 50); do pid_is_running "$pid" || return 0; sleep 0.1; done
    kill -TERM "$pid" 2>/dev/null || true
    for _ in $(seq 1 20); do pid_is_running "$pid" || return 0; sleep 0.1; done
    return 1
}

start_recorder() {
    local codec="$1" delay="$2" state_tmp start_time
    wf-recorder "${geo[@]}" "${aud[@]}" -c "$codec" -f "$file" >/dev/null 2>&1 &
    recording_pid=$!
    sleep "$delay"
    if pid_is_running "$recording_pid"; then
        start_time=$(proc_start_time "$recording_pid") || {
            stop_recorder_pid "$recording_pid" || true
            return 2
        }
        state_tmp=$(mktemp "${state}.XXXXXX") || {
            stop_recorder_pid "$recording_pid" || true
            return 2
        }
        if ! printf '%s\n%s\n%s\n' "$recording_pid" "$file" "$start_time" > "$state_tmp" || ! mv -f -- "$state_tmp" "$state"; then
            rm -f -- "$state_tmp"
            stop_recorder_pid "$recording_pid" || true
            return 2
        fi
        return 0
    fi
    wait "$recording_pid" 2>/dev/null || true
    rm -f -- "$file"
    return 1
}

notify_shell() {
    local method="$1"
    local config="${qsConfig:-macmono}"

    for _ in 1 2 3 4 5; do
        if qs -c "$config" ipc call control "$method" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done

    logger -t macmono-record "Could not notify Quickshell: control $method"
    return 1
}

cancel_start() {
    notify_shell recordingCancelled
    notify-send -a "Screen Recording" "$1" "$2"
    exit 0
}

case "$1" in
status)
    if pid=$(record_pid); then
        file=$(sed -n '2p' "$state")
        printf '1 %s\n' "$file"
    else
        echo 0
    fi
    ;;
stop)
    pid=$(record_pid) || { rm -f -- "$state"; exit 0; }
    file=$(sed -n '2p' "$state")
    if ! stop_recorder_pid "$pid"; then
        notify-send -a "Screen Recording" -u critical "Could not stop recording" "wf-recorder is still running (PID $pid)."
        exit 1
    fi
    rm -f -- "$state"
    if [ -s "$file" ]; then
        (
            act=$(notify-send -a "Screen Recording" -t 20000 \
                  -A default="Open folder" -A open="Open folder" -A play="Play" \
                  "Recording saved" "$(basename "$file")")
            dir=$(dirname "$file")
            case "$act" in
                open|default) xdg-open "$dir" >/dev/null 2>&1 || dolphin "$dir" >/dev/null 2>&1 & ;;
                play) xdg-open "$file" >/dev/null 2>&1 & ;;
            esac
        ) </dev/null >/dev/null 2>&1 &
        disown 2>/dev/null
    else
        notify-send -a "Screen Recording" -u critical "Recording failed" "Nothing was saved."
    fi
    ;;
start)
    if pid=$(record_pid); then
        notify_shell recordingStarted
        exit 0
    fi
    if pidof wf-recorder >/dev/null 2>&1; then
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "wf-recorder is already running" "Stop the other recording before starting one from macmono."
        exit 1
    fi
    mode="${2:-full}"; audio="${3:-none}"
    if [[ "$mode" != "full" && "$mode" != "area" ]] || [[ "$audio" != "none" && "$audio" != "system" && "$audio" != "mic" ]]; then
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "Invalid recording options"
        exit 1
    fi
    command -v wf-recorder >/dev/null || {
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "wf-recorder is not installed" "sudo pacman -S wf-recorder"
        exit 1
    }
    mkdir -p "$dir" || {
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "Could not create recordings directory" "$dir"
        exit 1
    }
    file="$dir/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    mkdir -p "$(dirname "$state")" || {
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "Could not create recording state directory"
        exit 1
    }

    geo=()
    if [ "$mode" = area ]; then
        command -v slurp >/dev/null 2>&1 || {
            notify-send -a "Screen Recording" -u critical "Area selection unavailable" "slurp is not installed."
            notify_shell recordingCancelled
            exit 1
        }
        g=$(slurp 2>/dev/null) || {
            cancel_start "Recording cancelled" "Area selection was cancelled."
        }
        [ -n "$g" ] || {
            cancel_start "Recording cancelled" "No area was selected."
        }
        geo=(--geometry "$g")
    else
        out=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)
        [ -n "$out" ] && geo=(-o "$out")
    fi

    aud=()
    case "$audio" in
        system) aud=("--audio=$(pactl get-default-sink).monitor") ;;
        mic)    aud=("--audio=$(pactl get-default-source)") ;;
    esac

    started() {
        notify_shell recordingStarted
        notify-send -a "Screen Recording" -t 2500 -h int:transient:1 "Recording started" "Click the timer in the bar to stop"
        exit 0
    }
    if [ -e /dev/dri/renderD128 ]; then
        if start_recorder h264_vaapi 1.2; then
            started
        else
            start_result=$?
            if [ "$start_result" -ne 1 ]; then
                notify_shell recordingCancelled
                notify-send -a "Screen Recording" -u critical "Could not save recording state"
                exit 1
            fi
        fi
    fi
    if ! start_recorder libx264 0.8; then
        notify_shell recordingCancelled
        notify-send -a "Screen Recording" -u critical "Recording failed to start"
        exit 1
    fi
    started
    ;;
esac
