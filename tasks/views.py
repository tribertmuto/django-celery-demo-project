from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Task
from .serializers import TaskSerializer, TaskStatusUpdateSerializer
from .tasks import process_task
import logging

logger = logging.getLogger(__name__)

class TaskViewSet(viewsets.ModelViewSet):
    """
    API endpoint that allows tasks to be viewed or edited.
    """
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Optionally filter tasks by status.
        """
        queryset = Task.objects.all()
        status_param = self.request.query_params.get('status', None)
        if status_param:
            queryset = queryset.filter(status=status_param.upper())
        return queryset

    def perform_create(self, serializer):
        """
        Create a new task and start processing it asynchronously.
        """
        task = serializer.save()
        # Start the background task
        process_task.delay(task.id)
        logger.info(f"Created and started processing task {task.id}")

    @action(detail=True, methods=['post'])
    def retry(self, request, pk=None):
        """
        Retry a failed task.
        """
        task = self.get_object()
        if task.status not in ['FAILED', 'COMPLETED']:
            return Response(
                {'error': 'Only failed or completed tasks can be retried'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create a new task with the same details
        new_task = Task.objects.create(
            title=f"{task.title} (Retry)",
            description=task.description,
            scheduled_time=task.scheduled_time
        )
        
        # Start processing the new task
        process_task.delay(new_task.id)
        
        serializer = self.get_serializer(new_task)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """
        Update the status of a task.
        """
        task = self.get_object()
        serializer = TaskStatusUpdateSerializer(
            task, 
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
