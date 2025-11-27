#!/bin/sh
echo "----------------------------------------------------------------"
echo "Starting Simulacrum in PORTABLE/COMPATIBILITY mode."
echo "----------------------------------------------------------------"
echo "NOTE: This game is running inside a self-contained Nix environment."
echo "      To ensure it runs on all Linux distributions without configuration,"
echo "      it is currently forced to use SOFTWARE RENDERING (CPU)."
echo ""
echo "      You may see errors like 'Parameter fbc is null' or"
echo "      'video card drivers seem not to support...'"
echo "      These are NORMAL side effects of this compatibility mode."
echo "      The game will automatically fall back to a working state."
echo "----------------------------------------------------------------"

# If we are inside the nix shell already (or just running the script),
# we want to ensure we use 'nix run' to leverage the flake environment.
# The flake itself sets LIBGL_ALWAYS_SOFTWARE=1.
nix run . -- "$@"
