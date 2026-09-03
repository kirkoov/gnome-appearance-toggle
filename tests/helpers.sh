#!/usr/bin/env bash

GREEN='\033[32m'
RED='\033[31m'
RESET='\033[0m'

pass() {
	printf -- '- %s %b✓ PASS%b\n' "$1" "$GREEN" "$RESET"
}

fail() {
	printf -- '- %s %b✗ FAILED%b\n' "$1" "$RED" "$RESET"
	return 1
}
