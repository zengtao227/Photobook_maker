# AI Skills Hub (Universal Intelligence OS)

> **One Source, All IDEs.**
> This repository is the central brain for your AI development environments. It syncs your "First Principles", "Premium Aesthetics", and "Engineering Standards" across VS Code, Cursor, Trae, and Antigravity.

---

## ⚡️ Quick Start (Getting Started)

### Option 1: The "ZengTao" Fast Way (Recommended)
If you have run the `setup-alias.sh` script (see below), simply run this in any new project folder:

```bash
init-ai
```

That's it. It will initialize git, pull this hub, and inject your brain into the project.

### Option 2: The Manual Way (Standard)
Run these commands in your new project root:

```bash
# 1. Initialize Git (if not already done)
git init

# 2. Add this Hub as a Submodule (Keeps it syncable)
git submodule add https://github.com/zengtao227/AI-Skills-Hub.git .agent/skills-hub

# 3. Compile Skills for your IDE
./.agent/skills-hub/install.sh

# 4. Commit the results (So your teammates get it automatically)
git add .cursorrules .agent
git commit -m "chore: inject universal ai skills"
```

---

## 🔄 How to Update?
Did you update your design philosophy in the Cloud? Here is how to pull it into your current project:

```bash
# Pull the latest changes from the Hub
git submodule update --remote --merge

# Re-compile the rules
./.agent/skills-hub/install.sh
```

---

## 📂 Architecture

- **`global/`**: Contains your core thinking models (First Principles, etc.). Injected into EVERY prompt.
- **`skills/`**: Specific domain knowledge (Design, i18n, DevOps). On-demand or routed based on context.
- **`scripts/`**: Executable utilities (e.g., `heal_xcode.sh`) that the AI can call to fix your computer.
- **`install.sh`**: The compiler. It reads the above folders and generates `.cursorrules` (for VS Code/Trae) and `.agent/skills` (for Antigravity).

---

## 🤝 Team Workflow
1. **You** run `install.sh` and commit the generated files.
2. **Teammates** clone the repo.
3. **They** open VS Code / Trae.
4. **Result**: The AI automatically follows YOUR rules. They don't need to install anything.
