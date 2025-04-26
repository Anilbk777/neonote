from django.db import models
from django.utils import timezone
from accounts.models import CustomUser
from goals.models import Goal

class Notification(models.Model):
    """
    Model for storing user notifications, particularly for goal reminders.
    """
    NOTIFICATION_TYPES = [
        ('goal_reminder', 'Goal Reminder'),
        ('task_due', 'Task Due'),
        ('system', 'System Notification'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    created_at = models.DateTimeField(default=timezone.now)
    due_date_time = models.DateTimeField(null=True, blank=True)
    is_read = models.BooleanField(default=False)
    source_id = models.IntegerField(null=True, blank=True)  # ID of the related item (goal, task, etc.)
    
    class Meta:
        ordering = ['-created_at']
        
    def __str__(self):
        return f"{self.title} - {self.user.email}"
    
    @property
    def is_past_due(self):
        """Check if the notification is past due"""
        if self.due_date_time:
            return self.due_date_time < timezone.now()
        return False
    
    @classmethod
    def create_goal_reminder(cls, goal):
        """Create a notification for a goal reminder"""
        if not goal.has_reminder or not goal.reminder_date_time:
            return None
            
        # Check if a notification for this goal already exists
        existing = cls.objects.filter(
            user=goal.user,
            notification_type='goal_reminder',
            source_id=goal.id
        ).first()
        
        if existing:
            # Update existing notification
            existing.title = f"Goal Reminder: {goal.title}"
            existing.message = f"Reminder for your goal: {goal.title}"
            existing.due_date_time = goal.reminder_date_time
            existing.is_read = False
            existing.save()
            return existing
        else:
            # Create new notification
            return cls.objects.create(
                user=goal.user,
                title=f"Goal Reminder: {goal.title}",
                message=f"Reminder for your goal: {goal.title}",
                notification_type='goal_reminder',
                due_date_time=goal.reminder_date_time,
                source_id=goal.id
            )
    
    @classmethod
    def remove_goal_reminder(cls, goal_id):
        """Remove notifications for a goal"""
        cls.objects.filter(
            notification_type='goal_reminder',
            source_id=goal_id
        ).delete()
