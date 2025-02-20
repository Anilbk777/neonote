from rest_framework import viewsets, permissions
from .models import Note
from .serializers import NoteSerializer

class NoteViewSet(viewsets.ModelViewSet):
    serializer_class = NoteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Return only the notes that belong to the current user
        return Note.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Automatically associate the note with the current user
        serializer.save(user=self.request.user)
