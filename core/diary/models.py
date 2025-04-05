from django.db import models
from django.conf import settings
from django.utils import timezone

from django.contrib.auth.models import User
import os
import uuid

# def diary_image_path(instance, filename):
#     # Generate a unique filename with original extension
#     ext = filename.split('.')[-1]
#     filename = f"{uuid.uuid4()}.{ext}"
#     return os.path.join('diary_images', str(instance.diary.id), filename)

class Diary(models.Model):
    MOOD_CHOICES = [
        ('Happy', 'Happy'),
        ('Sad', 'Sad'),
        ('Excited', 'Excited'), 
        ('Tired', 'Tired'),
        ('Anxious', 'Anxious'),
    ]
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='diaries')
    title = models.CharField(max_length=255)
    content = models.TextField()
    date = models.DateField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    mood = models.CharField(max_length=50, choices=MOOD_CHOICES, blank=True, null=True)
    background_color = models.IntegerField()  # Storing as hex color
    text_color = models.IntegerField()  # Storing as hex color
    template = models.CharField(max_length=50, default='Default')
    
    class Meta:
        ordering = ['-date']
        
    def __str__(self):
        return f"{self.title} - {self.date}"
    
   