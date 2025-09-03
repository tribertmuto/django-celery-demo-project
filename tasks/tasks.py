import time
from celery import shared_task
from django.core.mail import send_mail
from django.utils import timezone
from .models import Task
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

@shared_task(bind=True)
def process_task(self, task_id):
    """
    Background task to process a task asynchronously.
    """
    try:
        task = Task.objects.get(id=task_id)
        task.task_id = self.request.id
        task.mark_in_progress()
        
        # Simulate some processing time
        time.sleep(5)
        
        # Update task as completed
        result = f"Task {task.title} completed successfully"
        task.mark_completed(result=result)
        
        # Send email notification if email settings are configured
        if all([
            settings.EMAIL_HOST_USER,
            settings.EMAIL_HOST_PASSWORD,
            settings.DEFAULT_FROM_EMAIL
        ]):
            send_task_notification.delay(task_id)
            
        return result
    except Exception as e:
        logger.error(f"Error processing task {task_id}: {str(e)}", exc_info=True)
        if 'task' in locals():
            task.mark_failed(error=str(e))
        raise

@shared_task
def send_task_notification(task_id):
    """
    Send an email notification when a task is completed.
    """
    try:
        task = Task.objects.get(id=task_id)
        
        subject = f"Task Completed: {task.title}"
        message = f"""
        Task Details:
        Title: {task.title}
        Status: {task.get_status_display()}
        Completed at: {task.completed_at}
        Result: {task.result}
        """
        
        send_mail(
            subject=subject,
            message=message.strip(),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[settings.DEFAULT_FROM_EMAIL],
            fail_silently=False,
        )
        
        logger.info(f"Notification email sent for task {task_id}")
        return f"Notification sent for task {task_id}"
        
    except Exception as e:
        logger.error(f"Error sending notification for task {task_id}: {str(e)}", exc_info=True)
        raise

@shared_task
def cleanup_old_tasks(days_old=30):
    """
    Clean up completed tasks older than the specified number of days.
    """
    try:
        cutoff_date = timezone.now() - timezone.timedelta(days=days_old)
        deleted_count, _ = Task.objects.filter(
            status='COMPLETED',
            completed_at__lte=cutoff_date
        ).delete()
        
        logger.info(f"Cleaned up {deleted_count} old tasks")
        return f"Cleaned up {deleted_count} old tasks"
        
    except Exception as e:
        logger.error(f"Error cleaning up old tasks: {str(e)}", exc_info=True)
        raise
