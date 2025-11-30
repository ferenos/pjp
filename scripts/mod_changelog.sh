#!/bin/bash
# Generate changelog between two versions

set -e

PREV_VERSION=${1:-$(git describe --tags --abbrev=0 HEAD^)}
CURRENT_VERSION=${2:-$(git describe --tags --abbrev=0)}

echo "Generating changelog from $PREV_VERSION to $CURRENT_VERSION..."

# Output file
CHANGELOG_FILE="CHANGELOG-${CURRENT_VERSION}.md"

# Header
cat > "$CHANGELOG_FILE" << EOF
# Changelog - ${CURRENT_VERSION}

**Release Date:** $(date +%Y-%m-%d)

---

EOF

# Get mod changes
echo "## 📦 Mod Changes" >> "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"

# Added mods
ADDED=$(git diff --name-status $PREV_VERSION..$CURRENT_VERSION -- mods/*.pw.toml | grep "^A" | cut -f2 | sed 's/mods\///' | sed 's/.pw.toml//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g' || true)
if [ -n "$ADDED" ]; then
    echo "### ✅ Added" >> "$CHANGELOG_FILE"
    echo "$ADDED" | while read mod; do
        echo "- $mod" >> "$CHANGELOG_FILE"
    done
    echo "" >> "$CHANGELOG_FILE"
fi

# Removed mods
REMOVED=$(git diff --name-status $PREV_VERSION..$CURRENT_VERSION -- mods/*.pw.toml | grep "^D" | cut -f2 | sed 's/mods\///' | sed 's/.pw.toml//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g' || true)
if [ -n "$REMOVED" ]; then
    echo "### ❌ Removed" >> "$CHANGELOG_FILE"
    echo "$REMOVED" | while read mod; do
        echo "- $mod" >> "$CHANGELOG_FILE"
    done
    echo "" >> "$CHANGELOG_FILE"
fi

# Modified mods (version updates)
echo "### 🔄 Updated" >> "$CHANGELOG_FILE"
git diff $PREV_VERSION..$CURRENT_VERSION -- mods/*.pw.toml | grep -E "^\+.*version|^\-.*version" | sed 's/^+/NEW: /' | sed 's/^-/OLD: /' > /tmp/mod_versions.txt || true

# Parse version changes
CURRENT_MOD=""
while IFS= read -r line; do
    if [[ $line == *"filename"* ]]; then
        CURRENT_MOD=$(echo "$line" | sed 's/.*"\(.*\)"/\1/' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')
    elif [[ $line == OLD:* ]]; then
        OLD_VER=$(echo "$line" | sed 's/.*version = "\(.*\)"/\1/')
    elif [[ $line == NEW:* ]]; then
        NEW_VER=$(echo "$line" | sed 's/.*version = "\(.*\)"/\1/')
        if [ -n "$CURRENT_MOD" ] && [ "$OLD_VER" != "$NEW_VER" ]; then
            echo "- $CURRENT_MOD: \`$OLD_VER\` → \`$NEW_VER\`" >> "$CHANGELOG_FILE"
        fi
    fi
done < <(git diff $PREV_VERSION..$CURRENT_VERSION -- mods/*.pw.toml)

echo "" >> "$CHANGELOG_FILE"

# Git commit changes
echo "## 📝 Other Changes" >> "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"
git log $PREV_VERSION..$CURRENT_VERSION --pretty=format:"- %s (%h)" --no-merges >> "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"

# Download links
echo "## 📥 Downloads" >> "$CHANGELOG_FILE"
echo "" >> "$CHANGELOG_FILE"
echo "- [Client Pack (.mrpack)](https://github.com/$GITHUB_REPOSITORY/releases/download/${CURRENT_VERSION}/NutAndJamPack-${CURRENT_VERSION}.mrpack)" >> "$CHANGELOG_FILE"
echo "- [Server Pack (.zip)](https://github.com/$GITHUB_REPOSITORY/releases/download/${CURRENT_VERSION}/server-pack-${CURRENT_VERSION}.zip)" >> "$CHANGELOG_FILE"

echo "Changelog saved to $CHANGELOG_FILE"
cat "$CHANGELOG_FILE"