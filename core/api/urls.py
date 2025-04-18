# api/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PageViewSet

router = DefaultRouter()
router.register(r'pages', PageViewSet, basename='page')  # Provide basename explicitly

urlpatterns = [
    path('', include(router.urls)),
]
