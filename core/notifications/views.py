from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Notification
from .serializers import NotificationSerializer

class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing notifications.
    """
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return notifications for the current user"""
        return Notification.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        """Set the user when creating a notification"""
        serializer.save(user=self.request.user)
    
    @action(detail=False, methods=['post'])
    def mark_all_as_read(self, request):
        """Mark all notifications as read"""
        self.get_queryset().update(is_read=True)
        return Response({'status': 'All notifications marked as read'})
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark a specific notification as read"""
        notification = self.get_object()
        notification.is_read = True
        notification.save()
        return Response({'status': 'Notification marked as read'})
    
    @action(detail=False, methods=['delete'])
    def delete_all(self, request):
        """Delete all notifications"""
        self.get_queryset().delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
