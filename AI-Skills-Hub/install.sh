#!/bin/bash

# Get the directory where the script is located
HUB_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Configuration (Master Source)
SKILLS_SOURCE_DIR="$HUB_ROOT/skills"
GLOBAL_RULES_FILE="$HUB_ROOT/global/thinking_model.md"
SCRIPTS_DIR="$HUB_ROOT/scripts"

# Target Settings (Current Project)
ANTIGRAVITY_DIR=".agent/skills"
CURSOR_RULES_FILE=".cursorrules"

echo "🔌 Starting Universal Skill Adapter..."
echo "📍 Source Hub: $HUB_ROOT"

# Ensure scripts are executable
if [ -d "$SCRIPTS_DIR" ]; then
    chmod +x "$SCRIPTS_DIR"/*.sh 2>/dev/null
fi

# ==========================================
# 1. Antigravity Adapter (Claude Code)
# ==========================================
if [ -d ".agent" ]; then
    echo "✅ Antigravity environment detected."
    mkdir -p "$ANTIGRAVITY_DIR"
    
    # Iterate over markdown files and folders in skills dir
    find "$SKILLS_SOURCE_DIR" -maxdepth 2 -name "SKILL.md" -o -name "*.md" | while read file; do
        # Logic to handle both flat .md files and nested SKILL.md folders
        filename=$(basename -- "$file")
        parentname=$(basename $(dirname "$file"))
        
        if [ "$filename" == "SKILL.md" ]; then
            # It's a folder-based skill (e.g. xcode-doctor/SKILL.md)
            skill_name="$parentname"
        else
            # It's a flat file (e.g. design-premium.md)
            skill_name="${filename%.*}"
        fi
        
        # Skip if it's not a skill file
        if [ "$skill_name" == "skills" ]; then continue; fi

        target_dir="$ANTIGRAVITY_DIR/$skill_name"
        mkdir -p "$target_dir"
        
        cp "$file" "$target_dir/SKILL.md"
        
        # Add YAML frontmatter if missing
        if ! grep -q "^---" "$target_dir/SKILL.md"; then
            temp_file=$(mktemp)
            echo "---" > "$temp_file"
            echo "name: $skill_name" >> "$temp_file"
            echo "description: Imported skill for $skill_name" >> "$temp_file"
            echo "---" >> "$temp_file"
            cat "$target_dir/SKILL.md" >> "$temp_file"
            mv "$temp_file" "$target_dir/SKILL.md"
        fi
        
        echo "   -> Installed Skill: [$skill_name]"
    done
else
    echo "ℹ️  .agent directory not found. Skipping Antigravity setup."
fi

# ==========================================
# 2. Cursor/Trae Adapter (With Global Rules)
# ==========================================
echo "✅ Updating Cursor/VSCode rules ($CURSOR_RULES_FILE)..."

HEADER_START="### GENERATED SKILLS START ###"
HEADER_END="### GENERATED SKILLS END ###"

touch "$CURSOR_RULES_FILE"
TEMP_CONTENT=$(mktemp)

# Read existing content excluding the generated block
sed "/$HEADER_START/,/$HEADER_END/d" "$CURSOR_RULES_FILE" > "$TEMP_CONTENT"

echo "" >> "$TEMP_CONTENT"
echo "$HEADER_START" >> "$TEMP_CONTENT"
echo "<!-- The following rules are automatically imported from SkillsHub. -->" >> "$TEMP_CONTENT"
echo "" >> "$TEMP_CONTENT"

# 2.1 Inject Global Thinking Model (High Priority)
if [ -f "$GLOBAL_RULES_FILE" ]; then
    echo "🧠 Injecting First Principles Framework..."
    cat "$GLOBAL_RULES_FILE" >> "$TEMP_CONTENT"
    echo -e "\n\n---\n\n" >> "$TEMP_CONTENT"
fi

# 2.2 Inject Active Routing Logic
echo "## 🚦 Active Routing & Tool Selection" >> "$TEMP_CONTENT"
echo "- IF issue == 'UI/Design' THEN Apply [Premium Design Skill]" >> "$TEMP_CONTENT"
echo "- IF issue == 'Build Error' THEN Suggest [Xcode Doctor]" >> "$TEMP_CONTENT"
echo "- IF issue == 'Translation' THEN Apply [SwiftUI Localization Pro]" >> "$TEMP_CONTENT"
echo "- IF user_query == 'Release' OR user_query == 'Publish' THEN Apply [Binary Release Manager]" >> "$TEMP_CONTENT"
echo -e "\n\n---\n\n" >> "$TEMP_CONTENT"

# 2.3 Inject Skills
find "$SKILLS_SOURCE_DIR" -maxdepth 2 -name "SKILL.md" -o -name "*.md" | while read file; do
    echo "Listing rule from $file"
    cat "$file" >> "$TEMP_CONTENT"
    echo -e "\n\n---\n\n" >> "$TEMP_CONTENT"
done

echo "$HEADER_END" >> "$TEMP_CONTENT"

mv "$TEMP_CONTENT" "$CURSOR_RULES_FILE"
echo "   -> Injected Global Rules + Active Routing + Skills into .cursorrules"

echo "🎉 All Skills Synced Successfully!"
