from django.db import models
from django.conf import settings

class Note(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name="notes"
    )
    title = models.CharField(max_length=255)
    content = models.TextField(blank=True)  # Allow empty content if needed
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Optionally, add file fields if you need media uploads:
    image = models.ImageField(upload_to='notes/images/', null=True, blank=True)
    file = models.FileField(upload_to='notes/files/', null=True, blank=True)
    video = models.FileField(upload_to='notes/videos/', null=True, blank=True)

    def __str__(self):
        return self.title
