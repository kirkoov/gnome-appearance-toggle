#!/usr/bin/env bash

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$TESTS_DIR/helpers.sh"

SCHEMA="org.gnome.desktop.interface"
KEY="color-scheme"
EXTENSION_SCHEMA="org.gnome.shell.extensions.appearance-toggle"
FOLLOW_KEY="follow-night-light"
SCHEMAS_DIR="$TESTS_DIR/../appearance-toggle@kirkoov/schemas"

get_night_light_active() {
	local output

	output="$(
		gdbus call \
			--session \
			--dest org.gnome.SettingsDaemon.Color \
			--object-path /org/gnome/SettingsDaemon/Color \
			--method org.freedesktop.DBus.Properties.Get \
			org.gnome.SettingsDaemon.Color \
			NightLightActive
	)" || return 1

	case "$output" in
	*"<true>"*)
		printf '%s\n' true
		;;
	*"<false>"*)
		printf '%s\n' false
		;;
	*)
		printf 'Unexpected NightLightActive value: %s\n' "$output" >&2
		return 1
		;;
	esac
}

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

test_initial_night_light_sync() {
	local test_name="Initial Night Light synchronization"
	local night_light_active
	local appearance_before
	local appearance_after
	local extension_follow_before
	local expected
	local wrong
	local attempt

	night_light_active="$(get_night_light_active)" || {
		fail "$test_name"
		return
	}

	appearance_before="$(gsettings get "$SCHEMA" "$KEY")"

	extension_follow_before="$(
		gsettings \
			--schemadir "$SCHEMAS_DIR" \
			get "$EXTENSION_SCHEMA" "$FOLLOW_KEY"
	)"

	case "$night_light_active" in
	true)
		expected="'prefer-dark'"
		wrong="'prefer-light'"
		;;
	false)
		expected="'prefer-light'"
		wrong="'prefer-dark'"
		;;
	*)
		fail "$test_name"
		return
		;;
	esac

	printf 'Current GNOME NightLightActive: %s\n' "$night_light_active"
	printf 'Setting appearance deliberately wrong: %s\n' "$wrong"

	gsettings \
		--schemadir "$SCHEMAS_DIR" \
		set "$EXTENSION_SCHEMA" "$FOLLOW_KEY" true || {
		fail "$test_name"
		return
	}

	gsettings set "$SCHEMA" "$KEY" "$wrong" || {
		fail "$test_name"
		return
	}

	gnome-extensions disable appearance-toggle@kirkoov
	gnome-extensions enable appearance-toggle@kirkoov

	# Proxy creation is asynchronous, so give the extension a short time
	# to read NightLightActive and synchronize the appearance.
	for ((attempt = 0; attempt < 20; attempt++)); do
		appearance_after="$(gsettings get "$SCHEMA" "$KEY")"

		if [[ "$appearance_after" == "$expected" ]]; then
			break
		fi

		sleep 0.1
	done

	printf 'Appearance after re-enable: %s\n' "$appearance_after"

	# Restore the extension preference first.
	gsettings \
		--schemadir "$SCHEMAS_DIR" \
		set "$EXTENSION_SCHEMA" "$FOLLOW_KEY" "$extension_follow_before"

	# Reload once more so the menu reflects the restored preference.
	gnome-extensions disable appearance-toggle@kirkoov
	gnome-extensions enable appearance-toggle@kirkoov

	# Finally restore the original appearance.
	gsettings set "$SCHEMA" "$KEY" "$appearance_before"

	if [[ "$appearance_after" != "$expected" ]]; then
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
		test_initial_night_light_sync
	)

	for test in "${tests[@]}"; do
		"$test" || ((failures++))
	done

	return "$failures"
}

main
