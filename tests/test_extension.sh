#!/usr/bin/env bash

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$TESTS_DIR/helpers.sh"

ROOT_DIR="$(cd "$TESTS_DIR/.." && pwd)"

METADATA="$ROOT_DIR/appearance-toggle@kirkoov/metadata.json"
SCHEMAS_DIR="$ROOT_DIR/appearance-toggle@kirkoov/schemas"

test_metadata() {
	local test_name="metadata"

	jq -e '
    .uuid == "appearance-toggle@kirkoov" and
    .name == "Appearance Toggle" and
    .version == 1 and
    (.["shell-version"] | index("42") != null) and
    .url == "https://github.com/kirkoov/gnome-appearance-toggle"
  ' "$METADATA" >/dev/null || {
		fail "$test_name"
		return
	}

	pass "$test_name"
}

test_schema() {
	local test_name="GSettings schema"

	glib-compile-schemas --strict --dry-run "$SCHEMAS_DIR" || {
		fail "$test_name"
		return
	}

	pass "$test_name"
}

test_package() {
	local test_name="extension package"
	local tmp_dir

	tmp_dir="$(mktemp -d)" || {
		fail "$test_name"
		return
	}

	gnome-extensions pack \
		--out-dir="$tmp_dir" \
		"$ROOT_DIR/appearance-toggle@kirkoov" >/dev/null || {
		rm -rf "$tmp_dir"
		fail "$test_name"
		return
	}

	rm -rf "$tmp_dir"
	pass "$test_name"
}

test_package_contents() {
	local test_name="package contents"
	local tmp_dir
	local package
	local actual
	local expected

	tmp_dir="$(mktemp -d)" || {
		fail "$test_name"
		return
	}

	gnome-extensions pack \
		--out-dir="$tmp_dir" \
		"$ROOT_DIR/appearance-toggle@kirkoov" >/dev/null || {
		rm -rf "$tmp_dir"
		fail "$test_name"
		return
	}

	package="$tmp_dir/appearance-toggle@kirkoov.shell-extension.zip"

	actual="$(
		unzip -Z1 "$package" |
			grep -v '/$' |
			sort
	)"

	expected="$(
		printf '%s\n' \
			'extension.js' \
			'metadata.json' \
			'schemas/gschemas.compiled' \
			'schemas/org.gnome.shell.extensions.appearance-toggle.gschema.xml' |
			sort
	)"

	if [[ "$actual" != "$expected" ]]; then
		printf '%s\n' "$actual"
		rm -rf "$tmp_dir"
		fail "$test_name"
		return
	fi

	rm -rf "$tmp_dir"
	pass "$test_name"
}

main() {
	local failures=0
	local test
	local tests=(
		test_metadata
		test_schema
		test_package
		test_package_contents
	)

	for test in "${tests[@]}"; do
		"$test" || ((failures++))
	done

	return "$failures"
}

main
