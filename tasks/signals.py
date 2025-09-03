from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Task
import logging

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Task)
def log_task_update(sender, instance, created, **kwargs):
    """
    Log when a task is created or updated.
    """
    if created:
        logger.info(f"Task created: {instance.id} - {instance.title}")
    else:
        logger.info(f"Task updated - ID: {instance.id}, Status: {instance.status}")

@receiver(post_save, sender=Task)
def handle_task_completion(sender, instance, **kwargs):
    """
    Handle actions when a task is marked as completed.
    """
    if instance.status == 'COMPLETED' and not instance.completed_at:
        # This block will be executed when a task is marked as completed
        logger.info(f"Task {instance.id} completed: {instance.title}")
        # You can add additional completion logic here if needed
