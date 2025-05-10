"""
Utility functions for image handling
"""
from PIL import Image
import os

def get_image_dimensions(image_path):
    """
    Get the dimensions of an image file
    
    Args:
        image_path (str): Path to the image file
        
    Returns:
        tuple: (width, height) of the image
    """
    try:
        with Image.open(image_path) as img:
            return img.size
    except Exception as e:
        print(f"Error getting image dimensions: {e}")
        return (0, 0)

def resize_image(image_path, max_size):
    """
    Resize an image while maintaining aspect ratio
    
    Args:
        image_path (str): Path to the image file
        max_size (tuple): Maximum (width, height)
        
    Returns:
        Image: Resized PIL Image object
    """
    try:
        with Image.open(image_path) as img:
            img.thumbnail(max_size, Image.LANCZOS)
            return img
    except Exception as e:
        print(f"Error resizing image: {e}")
        return None

def get_image_creation_date(image_path):
    """
    Attempt to get the creation date of an image
    First tries EXIF data, then falls back to file creation date
    
    Args:
        image_path (str): Path to the image file
        
    Returns:
        datetime: Image creation date
    """
    import datetime
    
    try:
        # Try to get EXIF data
        with Image.open(image_path) as img:
            if hasattr(img, '_getexif') and img._getexif() is not None:
                exif = {
                    ExifTags.TAGS[k]: v
                    for k, v in img._getexif().items()
                    if k in ExifTags.TAGS
                }
                
                # Try different date fields
                for date_field in ['DateTimeOriginal', 'DateTime', 'DateTimeDigitized']:
                    if date_field in exif:
                        date_str = exif[date_field]
                        # Parse date format (typically 'YYYY:MM:DD HH:MM:SS')
                        try:
                            return datetime.datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
                        except ValueError:
                            pass
    except:
        pass
    
    # Fall back to file creation/modification time
    try:
        mod_time = os.path.getmtime(image_path)
        return datetime.datetime.fromtimestamp(mod_time)
    except:
        return datetime.datetime.now()  # Last resort
