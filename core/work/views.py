# from django.db import models
# from rest_framework import viewsets, status
# from rest_framework.response import Response
# from rest_framework.decorators import action
# from rest_framework.permissions import IsAuthenticated
# from django.shortcuts import get_object_or_404
# from django.contrib.auth import get_user_model
# from .models import Project, TeamInvitation
# from .serializers import ProjectSerializer, TeamInvitationSerializer
# from accounts.models import CustomUser
# import logging
# from django.utils import timezone

# logger = logging.getLogger(__name__)

# User = get_user_model()

# class ProjectViewSet(viewsets.ModelViewSet):
#     permission_classes = [IsAuthenticated]
#     serializer_class = ProjectSerializer

#     def get_queryset(self):
#         return Project.objects.filter(
#             models.Q(user=self.request.user) |
#             models.Q(members=self.request.user)
#         ).distinct()

#     def get_serializer_context(self):
#         context = super().get_serializer_context()
#         context['request'] = self.request
#         return context

#     def perform_create(self, serializer):
#         serializer.save(user=self.request.user)

#     @action(detail=True, methods=['post'], url_path='invite_member')
#     def invite_member(self, request, pk=None):
#         project = self.get_object()

#         if project.user != request.user:
#             logger.warning("User is not the owner of the project")
#             return Response(
#                 {'error': 'Only project owner can invite members'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         email = request.data.get('email')
#         if not email:
#             logger.error("Email is missing in the request")
#             return Response(
#                 {'error': 'Email is required'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         if email == request.user.email:
#             logger.info("Validation failed: User is trying to invite themselves")
#             return Response(
#                 {'error': 'You are the host'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         logger.info(f"Invite member request received for project {project.id} with email: {email}")

#         try:
#             recipient = CustomUser.objects.get(email=email)
#         except CustomUser.DoesNotExist:
#             logger.error(f"Validation failed: User with email {email} does not exist")
#             return Response(
#                 {'error': 'User with this email does not exist'},
#                 status=status.HTTP_404_NOT_FOUND
#             )

#         if recipient in project.members.all():
#             logger.info(f"Validation failed: User {recipient.email} is already a member of the project")
#             return Response(
#                 {'error': 'User is already a member of this project'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         existing_invitation = TeamInvitation.objects.filter(
#             project=project,
#             recipient_email=email,
#             status='pending'
#         ).first()

#         if existing_invitation:
#             logger.info(f"Validation failed: An invitation has already been sent to {email}")
#             return Response(
#                 {'error': 'An invitation has already been sent to this user'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         logger.info(f"Creating a new invitation for {email}")
#         TeamInvitation.objects.create(
#             project=project,
#             sender=request.user,
#             recipient=recipient,
#             recipient_email=email
#         )

#         logger.info(f"Invitation sent successfully to {email}")
#         return Response(
#             {'message': 'Invitation sent successfully'},
#             status=status.HTTP_201_CREATED
#         )

#     def create(self, request, *args, **kwargs):
#         try:
#             logger.info(f"Attempting to create project with data: {request.data}")
            
#             # Check if user is authenticated
#             if not request.user.is_authenticated:
#                 logger.error("User is not authenticated")
#                 return Response(
#                     {"error": "Authentication required"},
#                     status=status.HTTP_401_UNAUTHORIZED
#                 )

#             serializer = self.get_serializer(data=request.data)
#             if serializer.is_valid():
#                 self.perform_create(serializer)
#                 logger.info(f"Project created successfully: {serializer.data}")
#                 return Response(serializer.data, status=status.HTTP_201_CREATED)
            
#             logger.error(f"Validation error: {serializer.errors}")
#             return Response(
#                 {"error": "Validation failed", "details": serializer.errors},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         except Exception as e:
#             logger.error(f"Error creating project: {str(e)}", exc_info=True)
#             return Response(
#                 {"error": "Failed to create project", "details": str(e)},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )

#     def update(self, request, *args, **kwargs):
#         try:
#             partial = kwargs.pop('partial', False)
#             instance = self.get_object()
#             serializer = self.get_serializer(instance, data=request.data, partial=partial)
            
#             if serializer.is_valid():
#                 serializer.save()
#                 return Response(serializer.data)
            
#             return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

#         except Exception as e:
#             logger.error(f"Error updating project: {str(e)}", exc_info=True)
#             return Response(
#                 {"error": "Failed to update project", "details": str(e)},
#                 status=status.HTTP_500_INTERNAL_SERVER_ERROR
#             )

#     @action(detail=True, methods=['post'], url_path='leave')
#     def leave_project(self, request, pk=None):
#         project = self.get_object()

#         if request.user not in project.members.all():
#             return Response(
#                 {'error': 'You are not a member of this project'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         # Remove related notifications for the user
#         from notifications.models import Notification
#         Notification.objects.filter(user=request.user, project=project).delete()

#         project.members.remove(request.user)
#         return Response(
#             {'message': 'You have successfully left the project'},
#             status=status.HTTP_200_OK
#         )

# class TeamInvitationViewSet(viewsets.ModelViewSet):
#     permission_classes = [IsAuthenticated]
#     serializer_class = TeamInvitationSerializer

#     def get_queryset(self):
#         # Check if include_sent parameter is provided
#         include_sent = self.request.query_params.get('include_sent', 'false').lower() == 'true'
        
#         if include_sent:
#             # Return both sent and received invitations
#             return TeamInvitation.objects.filter(
#                 models.Q(recipient=self.request.user) | 
#                 models.Q(sender=self.request.user)
#             ).order_by('-created_at')
#         else:
#             # Return only received invitations (default behavior)
#             return TeamInvitation.objects.filter(recipient=self.request.user).order_by('-created_at')

#     @action(detail=True, methods=['post'])
#     def respond(self, request, pk=None):
#         invitation = self.get_object()
#         if invitation.recipient != request.user:
#             return Response(
#                 {'error': 'Only the recipient can respond to this invitation'},
#                 status=status.HTTP_403_FORBIDDEN
#             )

#         action = request.data.get('action')
#         if action not in ['accept', 'reject']:
#             return Response(
#                 {'error': 'Invalid action'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         if invitation.status != 'pending':
#             return Response(
#                 {'error': 'Invitation has already been responded to'},
#                 status=status.HTTP_400_BAD_REQUEST
#             )

#         # Set responded_at timestamp
#         invitation.responded_at = timezone.now()
        
#         if action == 'accept':
#             invitation.project.members.add(request.user)
#             invitation.status = 'accepted'
#         else:
#             invitation.status = 'rejected'

#         invitation.save()
#         serializer = self.get_serializer(invitation)
#         return Response(serializer.data)

#     @action(detail=True, methods=['delete'], url_path='delete')
#     def delete_invitation(self, request, pk=None):
#         invitation = self.get_object()
#         if invitation.recipient != request.user and invitation.sender != request.user:
#             return Response(
#                 {'error': 'You do not have permission to delete this invitation'},
#                 status=status.HTTP_403_FORBIDDEN
#             )
#         invitation.delete()
#         return Response(
#             {'message': 'Invitation deleted successfully'},
#             status=status.HTTP_200_OK
#         )


# =================================================================================================================







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
from django.utils import timezone

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

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'], url_path='invite_member')
    def invite_member(self, request, pk=None):
        project = self.get_object()

        if project.user != request.user:
            logger.warning(f"User {request.user.id} is not the owner of project {project.id}")
            return Response(
                {'error': 'Only project owner can invite members'},
                status=status.HTTP_403_FORBIDDEN
            )

        email = request.data.get('email')
        if not email:
            logger.error("Email is missing in the request")
            return Response(
                {'error': 'Email is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if email == request.user.email:
            logger.info(f"User {request.user.id} tried to invite themselves to project {project.id}")
            return Response(
                {'error': 'You are the host'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            recipient = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            logger.error(f"User with email {email} does not exist")
            return Response(
                {'error': 'User with this email does not exist'},
                status=status.HTTP_404_NOT_FOUND
            )

        if recipient in project.members.all():
            logger.info(f"User {recipient.email} is already a member of project {project.id}")
            return Response(
                {'error': 'User is already a member of this project'},
                status=status.HTTP_400_BAD_REQUEST
            )

        existing_invitation = TeamInvitation.objects.filter(
            project=project,
            recipient_email=email,
            status='pending'
        ).first()

        if existing_invitation:
            logger.info(f"An invitation has already been sent to {email} for project {project.id}")
            return Response(
                {'error': 'An invitation has already been sent to this user'},
                status=status.HTTP_400_BAD_REQUEST
            )

        logger.info(f"Creating a new invitation for {email} to project {project.id}")
        TeamInvitation.objects.create(
            project=project,
            sender=request.user,
            recipient=recipient,
            recipient_email=email
        )

        logger.info(f"Invitation sent successfully to {email} for project {project.id}")
        return Response(
            {'message': 'Invitation sent successfully'},
            status=status.HTTP_201_CREATED
        )

    def create(self, request, *args, **kwargs):
        try:
            logger.info(f"Attempting to create project with data: {request.data}")

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

    @action(detail=True, methods=['post'], url_path='leave')
    def leave_project(self, request, pk=None):
        project = self.get_object()

        if request.user not in project.members.all():
            return Response(
                {'error': 'You are not a member of this project'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            from notifications.models import Notification
            # Corrected filter: Assuming 'source_id' field in Notification model
            # is used to store the related project's ID.
            notifications_deleted, _ = Notification.objects.filter(
                user=request.user, source_id=project.id).delete()
            logger.info(f"{notifications_deleted} notifications deleted for user {request.user.id} in project {project.id}")

            project.members.remove(request.user)
            logger.info(f"User {request.user.id} left project {project.id}")

            return Response(
                {'message': 'You have successfully left the project'},
                status=status.HTTP_200_OK
            )

        except Exception as e:
            logger.error(f"Error while leaving project {project.id}: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while leaving the project.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class TeamInvitationViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = TeamInvitationSerializer

    def get_queryset(self):
        include_sent = self.request.query_params.get('include_sent', 'false').lower() == 'true'

        if include_sent:
            return TeamInvitation.objects.filter(
                models.Q(recipient=self.request.user) |
                models.Q(sender=self.request.user)
            ).order_by('-created_at')
        else:
            return TeamInvitation.objects.filter(recipient=self.request.user).order_by('-created_at')

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

        try:
            if action == 'accept':
                invitation.project.members.add(request.user)
                invitation.status = 'accepted'
                logger.info(f"User {request.user.id} accepted invitation to project {invitation.project.id}")
            else:
                invitation.status = 'rejected'
                logger.info(f"User {request.user.id} rejected invitation to project {invitation.project.id}")

            invitation.save()
            serializer = self.get_serializer(invitation)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Error processing invitation response: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while responding to the invitation.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['delete'], url_path='delete')
    def delete_invitation(self, request, pk=None):
        invitation = self.get_object()
        if invitation.recipient != request.user and invitation.sender != request.user:
            return Response(
                {'error': 'You do not have permission to delete this invitation'},
                status=status.HTTP_403_FORBIDDEN
            )

        try:
            invitation.delete()
            logger.info(f"Invitation {pk} deleted by user {request.user.id}")
            return Response(
                {'message': 'Invitation deleted successfully'},
                status=status.HTTP_200_OK
            )

        except Exception as e:
            logger.error(f"Error deleting invitation: {str(e)}", exc_info=True)
            return Response(
                {'error': 'An error occurred while deleting the invitation.', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
