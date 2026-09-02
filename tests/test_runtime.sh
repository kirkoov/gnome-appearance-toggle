#!/usr/bin/env bash

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$TESTS_DIR/helpers.sh"

SCHEMA="org.gnome.desktop.interface"
KEY="color-scheme"

test_toggle_now() {
	local test_name="Toggle now"
	local before
	local after

	before="$(gsettings get "$SCHEMA" "$KEY")"

	printf 'Current appearance: %s\n' "$before"
	printf 'Use Appearance Toggle -> Toggle now, then press Enter here... '
	read -r

	after="$(gsettings get "$SCHEMA" "$KEY")"

	printf 'New appearance: %s\n' "$after"

	if [[ "$before" == "$after" ]]; then
		fail "$test_name"
		return
	fi

	pass "$test_name"
}

main() {
	local failures=0
	local test
	local tests=(
		test_toggle_now
	)

	for test in "${tests[@]}"; do
		"$test" || ((failures++))
	done

	return "$failures"
}

main
