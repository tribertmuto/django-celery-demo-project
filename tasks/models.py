from django.db import models
from django.utils import timezone

class Task(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]

    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    scheduled_time = models.DateTimeField(default=timezone.now)
    completed_at = models.DateTimeField(null=True, blank=True)
    result = models.TextField(blank=True, null=True)
    error = models.TextField(blank=True, null=True)
    task_id = models.CharField(max_length=255, unique=True, null=True, blank=True)

    def __str__(self):
        return f"{self.title} - {self.get_status_display()}"

    def mark_completed(self, result=None):
        self.status = 'COMPLETED'
        self.completed_at = timezone.now()
        self.result = str(result) if result is not None else None
        self.save()

    def mark_failed(self, error=None):
        self.status = 'FAILED'
        self.completed_at = timezone.now()
        self.error = str(error) if error is not None else None
        self.save()

    def mark_in_progress(self):
        self.status = 'IN_PROGRESS'
        self.save()

    class Meta:
        ordering = ['-created_at']
