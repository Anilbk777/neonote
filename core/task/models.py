
from django.db import models
from django.utils import timezone
from accounts.models import CustomUser
from django.db.models.signals import post_save
from django.dispatch import receiver

class Task(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('on_hold', 'On Hold'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]

    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='independent_tasks')  # Task owner
    title = models.CharField(max_length=255)  # Task name
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='pending')  # Task status
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')  # Task priority
    due_date = models.DateField(null=True, blank=True)  # Optional due date
    date_created = models.DateTimeField(auto_now_add=True)  # Auto-created timestamp
    has_reminder = models.BooleanField(default=False)  # Whether the task has a reminder
    reminder_date_time = models.DateTimeField(null=True, blank=True)  # When to send the reminder

    def __str__(self):
        return self.title

# We'll use signals instead of overriding save() to avoid circular imports
@receiver(post_save, sender=Task)
def handle_task_reminder(sender, instance, created, **kwargs):
    # Import here to avoid circular import
    from notifications.models import Notification

    # Handle reminder notifications
    if instance.has_reminder and instance.reminder_date_time:
        # Create or update reminder notification
        Notification.create_task_reminder(instance)
    elif not instance.has_reminder or instance.status == 'completed':
        # Remove any existing reminder notifications
        Notification.remove_task_reminder(instance.id)