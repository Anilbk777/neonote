from django.db import models
from django.utils import timezone
from django.conf import settings
from accounts.models import CustomUser

class Project(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='owned_projects')
    name = models.CharField(max_length=200)
    description = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    members = models.ManyToManyField(settings.AUTH_USER_MODEL, related_name='shared_projects', blank=True)

    def __str__(self):
        return self.name

    class Meta:
        ordering = ['-created_at']

class TeamInvitation(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ]

    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='invitations')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='sent_invitations')
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='received_invitations',
        null=True,  # Temporarily allow null
        blank=True  # Temporarily allow blank
    )
    recipient_email = models.EmailField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['project', 'recipient']

    def __str__(self):
        return f"Invitation from {self.sender} to {self.recipient} for {self.project}"

    def save(self, *args, **kwargs):
        # If recipient is not set but we have an email, try to find the user
        if not self.recipient and self.recipient_email:
            try:
                self.recipient = CustomUser.objects.get(email=self.recipient_email)
            except CustomUser.DoesNotExist:
                pass
        super().save(*args, **kwargs)
