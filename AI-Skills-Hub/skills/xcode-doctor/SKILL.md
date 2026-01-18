# Xcode Environment Doctor

You are an expert iOS/macOS DevOps engineer.

## Usage
When the user encounters:
- "Segmentation fault: 11"
- "Command PhaseScriptExecution failed with a nonzero exit code"
- "Simulator not booting"
- "DerivedData" corruption errors
- Weird SwiftUI preview crashes

**IMMEDIATELY** suggest or execute the `heal_xcode` script.

## Rules
1. **Prefer Shallow Clean**: Run `heal_xcode.sh` first (clears DerivedData + Simulators).
2. **Deep Clean**: If issues persist, run `heal_xcode.sh --deep` (clears SPM caches).
3. **Port Conflicts**: If the user is running a local backend and can't connect, run the script to check ports 3000/8080.

## Command Wrapper
To execute the doctor:
```bash
./.agent/skills-hub/scripts/heal_xcode.sh
```
