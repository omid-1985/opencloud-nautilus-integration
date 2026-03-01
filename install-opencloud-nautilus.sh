#!/bin/bash
# Installer for "OpenCloud Integration" Nautilus Script
# Coded by: Omid Khalili, adapted for OpenCloud by user request
# Inspired by initial work of Philipp Fruck (https://gist.github.com/p-fruck/6ec354da8fb348c19cca013c6c64df76)
# License: GNU General Public License (GPL) version 3+
# Description: Implement OpenCloud Nautilus Integration for OpenCloud AppImage package
# Requires: bash, nautilus, nautilus-python, opencloud-desktop-client via AppImage
# Note: Safe to install alongside an existing Nextcloud Nautilus integration.

# Exit on any error
set -e

# Step 1: Download syncstate.py from OpenCloud nautilus integration repo.
# Renamed to opencloud_syncstate.py so it does not conflict with the
# Nextcloud syncstate.py that may already exist in the same extensions directory.
echo "Downloading opencloud_syncstate.py..."
curl -L -o opencloud_syncstate.py \
  https://raw.githubusercontent.com/opencloud-eu/desktop-shell-integration-nautilus/main/src/syncstate.py

# Step 2: Create the extensions directory (in case it doesn't exist yet)
echo "Creating extensions directory..."
mkdir -p ~/.local/share/nautilus-python/extensions/

# Step 3: Move opencloud_syncstate.py to the extensions directory
echo "Moving opencloud_syncstate.py to extensions directory..."
mv opencloud_syncstate.py ~/.local/share/nautilus-python/extensions/

# Step 4: Download the OpenCloud shell integration resources (icons)
echo "Downloading OpenCloud icon resources (resources.tar.gz)..."
curl -L -o resources.tar.gz \
  https://github.com/opencloud-eu/desktop-shell-integration-resources/archive/refs/heads/main.tar.gz

# Step 5: Extract the archive
echo "Extracting resources.tar.gz..."
tar -xzf resources.tar.gz

# Step 6: Copy icons into the 'emblems' subdirectory of the hicolor icon theme,
# renaming the 'oC_' prefix to 'OpenCloud_' on the way.
#
# Two fixes are applied here vs a naive copy:
#   1. Target is 'emblems/', not 'apps/' — Nautilus add_emblem() only looks in emblems/.
#   2. The resources repo ships files as oC_ok.png, oC_sync.png, etc. but syncstate.py
#      calls add_emblem('OpenCloud_ok'), add_emblem('OpenCloud_sync'), etc., so the
#      prefix must be replaced or the emblems are silently ignored.
echo "Installing emblem icons (renaming oC_ -> OpenCloud_)..."
for size in 16x16 32x32 48x48 64x64 72x72 128x128 256x256 512x512 1024x1024
do
  src_dir="desktop-shell-integration-resources-main/${size}"
  target=~/.local/share/icons/hicolor/${size}/emblems
  if [ -d "${src_dir}" ]; then
    mkdir -p "${target}"
    for icon in "${src_dir}"/*
    do
      [ -f "${icon}" ] || continue
      basename=$(basename "${icon}")
      cp "${icon}" "${target}/${basename/oC_/OpenCloud_}"
    done
    echo "  Installed $(ls "${src_dir}" | wc -l) icon(s) to ${target}"
  else
    echo "  Warning: source directory ${src_dir} not found, skipping ${size}."
  fi
done

# Step 7: Remove any stale oC_*.png files that may have been placed in the
# 'apps' directories by a previous run of this installer.
echo "Removing any stale oC_*.png files from apps directories..."
for size in 16x16 32x32 48x48 64x64 72x72 128x128 256x256 512x512 1024x1024
do
  rm -f ~/.local/share/icons/hicolor/${size}/apps/oC_*.png
done

# Step 8: Rebuild the GTK icon cache so Nautilus picks up the changes
echo "Rebuilding icon cache..."
if command -v gtk-update-icon-cache &>/dev/null; then
  gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/
elif command -v update-icon-caches &>/dev/null; then
  update-icon-caches ~/.local/share/icons/hicolor/
else
  echo "  Warning: neither gtk-update-icon-cache nor update-icon-caches found."
  echo "  You may need to log out and back in for emblems to appear."
fi

# Step 9: Cleanup
echo "Cleaning up temporary files..."
rm -rf desktop-shell-integration-resources-main resources.tar.gz

# Step 10: Restart Nautilus
echo "Restarting Nautilus..."
pkill -9 nautilus || true

echo "Done! Nautilus integration for OpenCloud is now installed alongside Nextcloud!"
echo ""
echo "Verify installed emblems with:"
echo "  ls ~/.local/share/icons/hicolor/16x16/emblems/ | grep -i opencloud"
