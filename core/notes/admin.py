# admin.py
from django.contrib import admin
from .models import Note

class NoteAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'created_at', 'updated_at')  # Columns to display in list view
    search_fields = ('title', 'content')  # Fields to search in the admin interface
    list_filter = ('created_at', 'updated_at')  # Filters to add in the admin panel

admin.site.register(Note, NoteAdmin)

