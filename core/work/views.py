from django.db import models
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from .models import Project, TeamInvitation
from .serializers import ProjectSerializer, TeamInvitationSerializer
from accounts.models import CustomUser
import logging

logger = logging.getLogger(__name__)

User = get_user_model()

class ProjectViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = ProjectSerializer

    def get_queryset(self):
        return Project.objects.filter(
            models.Q(user=self.request.user) |
            models.Q(members=self.request.user)
        ).distinct()

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def invite_member(self, request, pk=None):
        project = self.get_object()
        if project.user != request.user:
            return Response(
                {'error': 'Only project owner can invite members'},
                status=status.HTTP_403_FORBIDDEN
            )

        email = request.data.get('email')
        if not email:
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            recipient = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            return Response(
                {'error': 'User with this email does not exist'},
                status=status.HTTP_404_NOT_FOUND
            )

        if TeamInvitation.objects.filter(
            project=project,
            recipient=recipient,
            status='pending'
        ).exists():
            return Response(
                {'error': 'Invitation already sent'},
                status=status.HTTP_400_BAD_REQUEST
            )

        invitation = TeamInvitation.objects.create(
            project=project,
            sender=request.user,
            recipient=recipient,
            recipient_email=email
        )

        serializer = TeamInvitationSerializer(invitation)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def create(self, request, *args, **kwargs):
        try:
            logger.info(f"Attempting to create project with data: {request.data}")
            
            # Check if user is authenticated
            if not request.user.is_authenticated:
                logger.error("User is not authenticated")
                return Response(
                    {"error": "Authentication required"},
                    status=status.HTTP_401_UNAUTHORIZED
                )

            serializer = self.get_serializer(data=request.data)
            if serializer.is_valid():
                self.perform_create(serializer)
                logger.info(f"Project created successfully: {serializer.data}")
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            
            logger.error(f"Validation error: {serializer.errors}")
            return Response(
                {"error": "Validation failed", "details": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST
            )

        except Exception as e:
            logger.error(f"Error creating project: {str(e)}", exc_info=True)
            return Response(
                {"error": "Failed to create project", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def update(self, request, *args, **kwargs):
        try:
            partial = kwargs.pop('partial', False)
            instance = self.get_object()
            serializer = self.get_serializer(instance, data=request.data, partial=partial)
            
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data)
            
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Error updating project: {str(e)}", exc_info=True)
            return Response(
                {"error": "Failed to update project", "details": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TeamInvitationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = TeamInvitationSerializer

    def get_queryset(self):
        return TeamInvitation.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=['post'])
    def respond(self, request, pk=None):
        invitation = self.get_object()
        if invitation.recipient != request.user:
            return Response(
                {'error': 'Only the recipient can respond to this invitation'},
                status=status.HTTP_403_FORBIDDEN
            )

        action = request.data.get('action')
        if action not in ['accept', 'reject']:
            return Response(
                {'error': 'Invalid action'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if invitation.status != 'pending':
            return Response(
                {'error': 'Invitation has already been responded to'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if action == 'accept':
            invitation.project.members.add(request.user)
            invitation.status = 'accepted'
        else:
            invitation.status = 'rejected'

        invitation.save()
        serializer = self.get_serializer(invitation)
        return Response(serializer.data)
