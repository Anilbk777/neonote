# from rest_framework import serializers
# from .models import Goal, Task

# class TaskSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Task
#         fields = '__all__'

# class GoalSerializer(serializers.ModelSerializer):
#     tasks = TaskSerializer(many=True, read_only=True)
#     completion_percentage = serializers.ReadOnlyField()

#     class Meta:
#         model = Goal
#         fields = '__all__'
from rest_framework import serializers
from .models import Goal, Task

class GoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Goal
        fields = ['id', 'title', 'start_date', 'completion_date', 'is_completed', 'completion_time', 'user', 'created_by', 'created_at', 'last_modified_by', 'last_modified_at']
        read_only_fields = ['user', 'created_by', 'created_at', 'last_modified_by', 'last_modified_at']

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = ['id', 'title', 'goal', 'description', 'status', 'priority', 'due_date', 'user', 'created_by', 'created_at', 'last_modified_by', 'last_modified_at']
        read_only_fields = ['user', 'created_by', 'created_at', 'last_modified_by', 'last_modified_at']