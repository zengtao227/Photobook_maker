"""
Main Window for PhotoBook Maker Application
"""
from PyQt6.QtWidgets import (QMainWindow, QVBoxLayout, QHBoxLayout, QWidget, 
                            QPushButton, QLabel, QFileDialog, QListWidget,
                            QSplitter, QGroupBox, QScrollArea, QProgressBar)
from PyQt6.QtCore import Qt, QSize, QThread, pyqtSignal
from PyQt6.QtGui import QPixmap, QImage
from src.core.photo_processor import PhotoProcessor

class AnalysisThread(QThread):
    progress = pyqtSignal(int)
    completed = pyqtSignal()

    def __init__(self, photo_processor, photos):
        super().__init__()
        self.photo_processor = photo_processor
        self.photos = photos

    def run(self):
        total_photos = len(self.photos)
        for idx, photo in enumerate(self.photos):
            self.photo_processor.analyze_photos([photo])
            self.progress.emit(int((idx + 1) / total_photos * 100))
        self.completed.emit()

class MainWindow(QMainWindow):
    """Main application window for PhotoBook Maker"""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("PhotoBook Maker")
        self.setMinimumSize(1000, 700)
        self.photo_processor = PhotoProcessor()
        self.selected_photos = []
        
        self.init_ui()
        
    def init_ui(self):
        """Initialize the user interface"""
        # Main layout
        central_widget = QWidget()
        main_layout = QVBoxLayout(central_widget)
        
        # Create splitter for main sections
        splitter = QSplitter(Qt.Orientation.Horizontal)
        
        # Left panel - Photo selection and controls
        left_panel = QWidget()
        left_layout = QVBoxLayout(left_panel)
        
        # Photo selection buttons
        select_group = QGroupBox("Photo Selection")
        select_layout = QVBoxLayout(select_group)
        
        self.select_btn = QPushButton("Select Photos")
        self.select_btn.clicked.connect(self.select_photos)
        select_layout.addWidget(self.select_btn)
        
        self.photo_list = QListWidget()
        self.photo_list.setMinimumHeight(200)
        self.photo_list.itemSelectionChanged.connect(self.update_preview)
        select_layout.addWidget(QLabel("Selected Photos:"))
        select_layout.addWidget(self.photo_list)
        
        left_layout.addWidget(select_group)
        
        # Processing controls
        process_group = QGroupBox("Processing")
        process_layout = QVBoxLayout(process_group)
        
        self.analyze_btn = QPushButton("Analyze Photos")
        self.analyze_btn.clicked.connect(self.analyze_photos)
        self.analyze_btn.setEnabled(False)
        process_layout.addWidget(self.analyze_btn)
        
        self.categorize_btn = QPushButton("Categorize")
        self.categorize_btn.clicked.connect(self.categorize_photos)
        self.categorize_btn.setEnabled(False)
        process_layout.addWidget(self.categorize_btn)
        
        self.generate_btn = QPushButton("Generate Document")
        self.generate_btn.clicked.connect(self.generate_document)
        self.generate_btn.setEnabled(False)
        process_layout.addWidget(self.generate_btn)
        
        left_layout.addWidget(process_group)
        left_layout.addStretch()
        
        # Right panel - Preview and results
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        
        # Preview section
        preview_group = QGroupBox("Preview")
        preview_layout = QVBoxLayout(preview_group)
        
        self.preview_label = QLabel("No photo selected")
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setMinimumHeight(300)
        
        preview_scroll = QScrollArea()
        preview_scroll.setWidget(self.preview_label)
        preview_scroll.setWidgetResizable(True)
        preview_layout.addWidget(preview_scroll)
        
        right_layout.addWidget(preview_group)
        
        # Results section
        results_group = QGroupBox("Analysis Results")
        results_layout = QVBoxLayout(results_group)
        
        self.results_label = QLabel("No analysis results yet")
        results_layout.addWidget(self.results_label)
        
        right_layout.addWidget(results_group)
        
        # Add progress bar to the UI
        self.progress_bar = QProgressBar()
        self.progress_bar.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.progress_bar.setValue(0)
        main_layout.addWidget(self.progress_bar)

        # Add panels to splitter
        splitter.addWidget(left_panel)
        splitter.addWidget(right_panel)
        splitter.setSizes([300, 700])
        
        # Add splitter to main layout
        main_layout.addWidget(splitter)
        
        # Status bar
        self.status_bar = self.statusBar()
        self.status_bar.showMessage("Ready")
        
        self.setCentralWidget(central_widget)
        
    def select_photos(self):
        """Open file dialog to select photos"""
        file_dialog = QFileDialog()
        file_dialog.setFileMode(QFileDialog.FileMode.ExistingFiles)
        file_dialog.setNameFilter("Images (*.png *.jpg *.jpeg *.bmp)")
        
        if file_dialog.exec():
            filenames = file_dialog.selectedFiles()
            self.selected_photos = filenames
            
            # Update photo list
            self.photo_list.clear()
            for photo in filenames:
                self.photo_list.addItem(photo.split("/")[-1])
            
            # Enable analyze button if photos selected
            if self.selected_photos:
                self.analyze_btn.setEnabled(True)
                self.status_bar.showMessage(f"Selected {len(self.selected_photos)} photos")
            
    def update_preview(self):
        """Update the preview with selected photo"""
        selected_items = self.photo_list.selectedItems()
        
        if not selected_items:
            self.preview_label.setText("No photo selected")
            return
        
        # Get index of selected item
        selected_idx = self.photo_list.row(selected_items[0])
        photo_path = self.selected_photos[selected_idx]
        
        # Load and display image
        image = QImage(photo_path)
        if not image.isNull():
            pixmap = QPixmap.fromImage(image)
            # Scale image to fit preview area while maintaining aspect ratio
            self.preview_label.setPixmap(pixmap.scaled(
                self.preview_label.width(), 
                self.preview_label.height(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation
            ))
        else:
            self.preview_label.setText("Error loading image")
    
    def analyze_photos(self):
        """Analyze the selected photos for content"""
        if not self.selected_photos:
            return
        
        self.status_bar.showMessage("Analyzing photos...")
        self.analysis_thread = AnalysisThread(self.photo_processor, self.selected_photos)
        self.analysis_thread.progress.connect(self.progress_bar.setValue)
        self.analysis_thread.completed.connect(self.on_analysis_complete)
        self.analysis_thread.start()

    def on_analysis_complete(self):
        self.status_bar.showMessage("Analysis complete")
        self.categorize_btn.setEnabled(True)
        self.progress_bar.setValue(100)
    
    def categorize_photos(self):
        """Categorize photos based on analysis results"""
        self.status_bar.showMessage("Categorizing photos...")
        # Call the photo processor to categorize photos
        categories = self.photo_processor.categorize_photos()
        
        # Update the UI with results
        self.results_label.setText(f"Created {len(categories)} categories")
        self.generate_btn.setEnabled(True)
        self.status_bar.showMessage("Categorization complete")
    
    def generate_document(self):
        """Generate the printable document"""
        self.status_bar.showMessage("Generating document...")
        # Call the photo processor to generate document
        doc_path = self.photo_processor.generate_document()
        
        # Update the UI with results
        self.results_label.setText(f"Document generated at: {doc_path}")
        self.status_bar.showMessage("Document generation complete")
