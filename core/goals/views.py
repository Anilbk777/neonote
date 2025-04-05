
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Goal, Task
from .serializers import GoalSerializer, TaskSerializer

class GoalViewSet(viewsets.ModelViewSet):
    serializer_class = GoalSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        This view should return a list of all the goals
        for the currently authenticated user.
        """
        user = self.request.user
        return Goal.objects.filter(user=user)
    
    def perform_create(self, serializer):
        """
        Override this method to associate the created goal with the authenticated user.
        """
        serializer.save(user=self.request.user, created_by=self.request.user.email)

    def perform_update(self, serializer):
        """
        Override this method to ensure the goal remains associated with the authenticated user.
        """
        serializer.save(user=self.request.user, last_modified_by=self.request.user.email)

class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Optionally restricts the returned tasks to a given goal,
        by filtering against a `goal_id` query parameter in the URL.
        """
        queryset = Task.objects.all()
        goal_id = self.request.query_params.get('goal_id')
        if goal_id is not None:
            queryset = queryset.filter(goal_id=goal_id)
        return queryset
    
    def perform_create(self, serializer):
        """
        Override this method to associate the created task with the authenticated user.
        """
        serializer.save(user=self.request.user, created_by=self.request.user.email)

    def perform_update(self, serializer):
        """
        Override this method to ensure the task remains associated with the authenticated user.
        """
        serializer.save(user=self.request.user, last_modified_by=self.request.user.email)