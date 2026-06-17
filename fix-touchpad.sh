#!/usr/bin/env bash
#
# fix-touchpad.sh — Apply the libinput pressure-axis quirk that restores
# cursor motion on the Dell PixArt touchpad (VEN_0488:00 0488:108C).
#
# Root cause: libinput used pressure-based touch detection, but this pad's
# real ABS_MT_PRESSURE only reaches ~12, so every touch was dropped as a
# "palm". Disabling the pressure axes makes libinput use contact/tip-based
# detection instead.
#
# Requires sudo (writes to /etc). Safe to re-run; it backs up any existing
# quirks file before overwriting.

set -euo pipefail

QUIRK_FILE="/etc/libinput/local-overrides.quirks"

read -r -d '' QUIRK_CONTENT <<'EOF' || true
[PixArt 0488:108C pressure fix]
MatchName=VEN_0488:00 0488:108C Touchpad
AttrEventCode=-ABS_MT_PRESSURE;-ABS_PRESSURE;
EOF

echo "Applying libinput touchpad quirk to ${QUIRK_FILE} ..."

# Ensure the target directory exists.
sudo mkdir -p "$(dirname "${QUIRK_FILE}")"

# Back up an existing file (one-time, timestamped) so nothing is lost.
if [ -f "${QUIRK_FILE}" ]; then
    BACKUP="${QUIRK_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "Backing up existing file to ${BACKUP}"
    sudo cp "${QUIRK_FILE}" "${BACKUP}"
fi

# Write the quirk.
printf '%s\n' "${QUIRK_CONTENT}" | sudo tee "${QUIRK_FILE}" >/dev/null

echo "Done. Quirk written:"
echo "----------------------------------------"
printf '%s\n' "${QUIRK_CONTENT}"
echo "----------------------------------------"

# Validate the quirk parses correctly, if the tool is available.
if command -v libinput >/dev/null 2>&1; then
    echo "Validating quirks file..."
    if sudo libinput quirks list 2>/dev/null | grep -qi "AttrEventCode"; then
        echo "libinput accepted the quirk."
    else
        echo "Quirk written; run 'libinput quirks validate --verbose' to inspect."
    fi
fi

cat <<'EOF'

Next steps:
  1. Log out and back in (or reboot) so libinput reloads the quirk.
  2. Verify with:  libinput debug-events --verbose
     - look for it disabling ABS_MT_PRESSURE / ABS_PRESSURE
     - move a finger and confirm a POINTER_MOTION stream appears.
EOF
