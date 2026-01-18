#!/bin/bash

# heal_xcode.sh - The Ultimate Xcode Environment Doctor
# Usage: ./heal_xcode.sh [--deep]

DEEP_CLEAN=false
if [ "$1" == "--deep" ]; then
    DEEP_CLEAN=true
fi

echo "👨‍⚕️ Xcode Doctor is starting diagnosis..."

# 1. Kill Zombie Simulators
echo "🩹 Checking for zombie simulator processes..."
pkill -9 Simulator 2>/dev/null
pkill -9 CoreSimulator 2>/dev/null
xcrun simctl shutdown all 2>/dev/null
echo "   -> Simulators reset."

# 2. Clean DerivedData
echo "🧹 Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "   -> DerivedData evicted."

# 3. Reset Package Caches (Deep Clean Only)
if [ "$DEEP_CLEAN" = true ]; then
    echo "🧽 Deep cleaning Swift Package Manager caches..."
    rm -rf ~/Library/Caches/org.swift.swiftpm
    rm -rf ~/Library/org.swift.swiftpm
    
    # Clean local project build folder if exists
    if [ -d ".build" ]; then
        rm -rf .build
    fi
    echo "   -> SPM caches flushed."
fi

# 4. Check Port Conflicts (Common Dev Ports)
echo "🔌 Checking port availability..."
PORTS_TO_CHECK=(3000 8080 8000)
for port in "${PORTS_TO_CHECK[@]}"; do
    if lsof -i :$port >/dev/null; then
        echo "   ⚠️  Port $port is in use by:"
        lsof -i :$port | grep LISTEN
        # Optional: Ask to kill? For now just warn.
    else
        echo "   -> Port $port is free."
    fi
done

echo "✅ Diagnosis complete. Try running your build again."
