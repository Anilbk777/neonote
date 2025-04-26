from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from goals.models import Goal
from .models import Notification

@receiver(post_save, sender=Goal)
def create_or_update_goal_notification(sender, instance, created, **kwargs):
    """
    Create or update a notification when a goal is created or updated with a reminder.
    """
    if hasattr(instance, 'has_reminder') and instance.has_reminder and instance.reminder_date_time:
        Notification.create_goal_reminder(instance)
    elif hasattr(instance, 'has_reminder') and not instance.has_reminder:
        # If reminder was removed, remove the notification
        Notification.remove_goal_reminder(instance.id)

@receiver(post_delete, sender=Goal)
def delete_goal_notification(sender, instance, **kwargs):
    """
    Delete notifications when a goal is deleted.
    """
    Notification.remove_goal_reminder(instance.id)
