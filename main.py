#!/usr/bin/env python3
"""
PhotoBook Maker - Main Application Entry Point
"""
import sys
from src.ui.main_window import MainWindow
from PyQt6.QtWidgets import QApplication

def main():
    """Main application entry point"""
    app = QApplication(sys.argv)
    app.setApplicationName("PhotoBook Maker")
    
    window = MainWindow()
    window.show()
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
