from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Task
        fields = [
            'id', 'title', 'description', 'status', 'status_display',
            'created_at', 'updated_at', 'scheduled_time', 'completed_at',
            'result', 'error', 'task_id'
        ]
        read_only_fields = [
            'id', 'status', 'created_at', 'updated_at', 'completed_at',
            'result', 'error', 'task_id', 'status_display'
        ]

    def create(self, validated_data):
        return Task.objects.create(**validated_data)

    def update(self, instance, validated_data):
        # Prevent updating certain fields directly
        for field in ['status', 'result', 'error', 'task_id']:
            validated_data.pop(field, None)
            
        for key, value in validated_data.items():
            setattr(instance, key, value)
            
        instance.save()
        return instance


class TaskStatusUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['status']
        extra_kwargs = {
            'status': {'required': True}
        }

    def update(self, instance, validated_data):
        status = validated_data.get('status')
        
        if status == 'COMPLETED':
            instance.mark_completed()
        elif status == 'FAILED':
            error = self.context.get('error', 'An error occurred')
            instance.mark_failed(error=error)
        elif status == 'IN_PROGRESS':
            instance.mark_in_progress()
        else:
            instance.status = status
            instance.save()
            
        return instance
