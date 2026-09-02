#!/usr/bin/env bash

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$TESTS_DIR/helpers.sh"

SCHEMA="org.gnome.desktop.interface"
KEY="color-scheme"
EXTENSION_SCHEMA="org.gnome.shell.extensions.appearance-toggle"
FOLLOW_KEY="follow-night-light"
SCHEMAS_DIR="$TESTS_DIR/../appearance-toggle@kirkoov/schemas"

test_toggle_now() {
	local test_name="Toggle now"
	local before
	local after
	local expected

	before="$(gsettings get "$SCHEMA" "$KEY")"

	case "$before" in
	"'prefer-dark'")
		expected="'prefer-light'"
		;;
	"'prefer-light'")
		expected="'prefer-dark'"
		;;
	*)
		printf 'Unexpected initial appearance: %s\n' "$before"
		fail "$test_name"
		return
		;;
	esac

	printf 'Current appearance: %s\n' "$before"
	printf 'Use Appearance Toggle -> Toggle now, then press Enter here... '
	read -r

	after="$(gsettings get "$SCHEMA" "$KEY")"

	printf 'New appearance: %s\n' "$after"

	gsettings set "$SCHEMA" "$KEY" "$before" || {
		printf 'Failed to restore appearance: %s\n' "$before" >&2
		fail "$test_name"
		return
	}

	if [[ "$after" != "$expected" ]]; then
		fail "$test_name"
		return
	fi

	pass "$test_name"
}

test_follow_night_light_toggle() {
	local test_name="Follow Night Light"
	local before
	local after
	local expected

	before="$(
		gsettings \
			--schemadir "$SCHEMAS_DIR" \
			get "$EXTENSION_SCHEMA" "$FOLLOW_KEY"
	)"

	case "$before" in
	true)
		expected=false
		;;
	false)
		expected=true
		;;
	*)
		printf 'Unexpected initial setting: %s\n' "$before"
		fail "$test_name"
		return
		;;
	esac

	printf 'Current Follow Night Light: %s\n' "$before"
	printf 'Toggle Follow Night Light in the extension menu, then press Enter here... '
	read -r

	after="$(
		gsettings \
			--schemadir "$SCHEMAS_DIR" \
			get "$EXTENSION_SCHEMA" "$FOLLOW_KEY"
	)"

	printf 'New Follow Night Light: %s\n' "$after"

	gsettings \
		--schemadir "$SCHEMAS_DIR" \
		set "$EXTENSION_SCHEMA" "$FOLLOW_KEY" "$before" || {
		printf 'Failed to restore Follow Night Light: %s\n' "$before" >&2
		fail "$test_name"
		return
	}

	if [[ "$after" != "$expected" ]]; then
		fail "$test_name"
		return
	fi

	pass "$test_name"
}

test_follow_night_light_persistence() {
	local test_name="Follow Night Light persistence"
	local before
	local after

	before="$(
		gsettings \
			--schemadir "$SCHEMAS_DIR" \
			get "$EXTENSION_SCHEMA" "$FOLLOW_KEY"
	)"

	gnome-extensions disable appearance-toggle@kirkoov
	gnome-extensions enable appearance-toggle@kirkoov

	after="$(
		gsettings \
			--schemadir "$SCHEMAS_DIR" \
			get "$EXTENSION_SCHEMA" "$FOLLOW_KEY"
	)"

	if [[ "$after" != "$before" ]]; then
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
		test_follow_night_light_toggle
		test_follow_night_light_persistence
	)

	for test in "${tests[@]}"; do
		"$test" || ((failures++))
	done

	return "$failures"
}

main
