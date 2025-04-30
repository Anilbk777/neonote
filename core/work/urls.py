from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ProjectViewSet, TeamInvitationViewSet

router = DefaultRouter()
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'invitations', TeamInvitationViewSet, basename='invitation')

urlpatterns = [
    path('', include(router.urls)),
]
