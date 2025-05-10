"""
Photo processing module for photo book maker application
"""
import os
from datetime import datetime
import time
from pathlib import Path
from google.cloud import vision
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

class PhotoProcessor:
    """
    Handles photo processing, analysis, categorization and document generation
    """
    
    def __init__(self):
        """Initialize the photo processor"""
        self.photos = []
        self.analysis_results = {}
        self.categories = {}
        self.client = vision.ImageAnnotatorClient()
        
    def analyze_photos(self, photo_paths):
        """
        Analyze photos for content and metadata
        
        Args:
            photo_paths (list): List of photo file paths
            
        Returns:
            dict: Analysis results for each photo
        """
        self.photos = photo_paths
        self.analysis_results = {}
        
        for photo in photo_paths:
            # Get file name without extension
            file_name = os.path.basename(photo)
            
            # Extract date from filename (assuming format with date)
            try:
                date = datetime.fromtimestamp(os.path.getctime(photo))
            except Exception:
                date = datetime.now()
            
            # Analyze photo with Google Cloud Vision API
            tags = self._analyze_with_vision_api(photo)
            
            # Store results
            self.analysis_results[photo] = {
                'date': date,
                'tags': tags,
                'file_name': file_name
            }
            
            # Simulate processing time
            time.sleep(0.2)
            
        return self.analysis_results
    
    def _analyze_with_vision_api(self, photo_path):
        """
        Analyze photo content using Google Cloud Vision API
        
        Args:
            photo_path (str): Path to photo file
            
        Returns:
            list: Content tags from Vision API
        """
        with open(photo_path, 'rb') as image_file:
            content = image_file.read()

        image = vision.Image(content=content)
        response = self.client.label_detection(image=image)

        if response.error.message:
            print(f"Error analyzing {photo_path}: {response.error.message}")
            return []

        return [label.description for label in response.label_annotations]
    
    def categorize_photos(self):
        """
        Categorize photos based on analyzed content
        
        Returns:
            dict: Categories with photos
        """
        if not self.analysis_results:
            return {}
            
        # Initialize categories
        self.categories = {}
        
        # First, categorize by timeline/date
        timeline = {}
        for photo, data in self.analysis_results.items():
            date = data['date']
            month_year = date.strftime("%Y-%m")
            
            if month_year not in timeline:
                timeline[month_year] = []
                
            timeline[month_year].append(photo)
        
        # Then subcategorize by content tags
        for period, photos in timeline.items():
            # Count tag occurrences in this time period
            tag_counts = {}
            for photo in photos:
                for tag in self.analysis_results[photo]['tags']:
                    if tag not in tag_counts:
                        tag_counts[tag] = 0
                    tag_counts[tag] += 1
            
            # Find dominant tags (tags that occur in multiple photos)
            dominant_tags = [tag for tag, count in tag_counts.items() if count > 1]
            
            if dominant_tags:
                # Create categories based on time period + dominant tag
                for tag in dominant_tags:
                    category_name = f"{period} - {tag.capitalize()}"
                    self.categories[category_name] = []
                    
                    # Add photos with this tag to the category
                    for photo in photos:
                        if tag in self.analysis_results[photo]['tags']:
                            self.categories[category_name].append(photo)
            else:
                # If no dominant tags, just use the time period
                self.categories[period] = photos
        
        return self.categories
    
    def generate_document(self):
        """
        Generate a printable document with categorized photos
        
        Returns:
            str: Path to the generated document
        """
        output_dir = Path("output")
        output_dir.mkdir(exist_ok=True)

        doc_name = f"photobook_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        doc_path = output_dir / doc_name

        c = canvas.Canvas(str(doc_path), pagesize=letter)
        width, height = letter

        y_position = height - 50

        c.setFont("Helvetica-Bold", 16)
        c.drawString(50, y_position, "PhotoBook")
        y_position -= 30

        for category, photos in self.categories.items():
            c.setFont("Helvetica-Bold", 14)
            c.drawString(50, y_position, f"Category: {category}")
            y_position -= 20

            for photo in photos:
                if y_position < 100:
                    c.showPage()
                    y_position = height - 50

                c.setFont("Helvetica", 12)
                c.drawString(70, y_position, f"- {photo}")
                y_position -= 20

        c.save()

        return str(doc_path)
