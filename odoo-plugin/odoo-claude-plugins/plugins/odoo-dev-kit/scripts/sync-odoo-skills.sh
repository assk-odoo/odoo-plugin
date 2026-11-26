#!/bin/bash
# Refresh the official Odoo skills bundled in this plugin from a community checkout.
# Usage: sync-odoo-skills.sh <path-to-community-repo> [git-ref]   (default ref: odoo/master)
#
# odoo-guidelines, odoo-web-guidelines, odoo-security and odoo-git are copied as skills.
# odoo-review is not a separate skill here: its process is folded into odoo-pr-review as
# references/odoo-review-process.md, so only one review skill is exposed.
set -euo pipefail

COMMUNITY=${1:?usage: $0 <path-to-community-repo> [git-ref]}
REF=${2:-odoo/master}
PLUGIN_DIR=$(cd "$(dirname "$0")/.." && pwd)
SKILLS=(odoo-git odoo-guidelines odoo-security odoo-web-guidelines)
PROCESS_FILE="$PLUGIN_DIR/skills/odoo-pr-review/references/odoo-review-process.md"

git -C "$COMMUNITY" fetch --quiet "${REF%%/*}" "${REF#*/}" || echo "warning: fetch failed, using local $REF"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$COMMUNITY" archive "$REF" skills | tar -x -C "$TMP"

for s in "${SKILLS[@]}"; do
    rm -rf "${PLUGIN_DIR:?}/skills/$s"
    cp -r "$TMP/skills/$s" "$PLUGIN_DIR/skills/$s"
done

# Fold odoo-review into odoo-pr-review: drop its frontmatter so it is not loaded as a skill,
# and add one level to its sibling paths because the file sits one folder deeper.
mkdir -p "$(dirname "$PROCESS_FILE")"
{
    echo "<!-- Copied from community skills/odoo-review/SKILL.md by scripts/sync-odoo-skills.sh. Do not edit; re-run the script. -->"
    awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$TMP/skills/odoo-review/SKILL.md" \
        | sed 's#\.\./odoo-#../../odoo-#g'
} > "$PROCESS_FILE"
rm -rf "${PLUGIN_DIR:?}/skills/odoo-review"

git -C "$COMMUNITY" rev-parse --short "$REF" > "$PLUGIN_DIR/UPSTREAM_SKILLS_REV"
echo "Synced ${SKILLS[*]} and odoo-review process from $REF@$(cat "$PLUGIN_DIR/UPSTREAM_SKILLS_REV")"
