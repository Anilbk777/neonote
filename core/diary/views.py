# from django.shortcuts import render

# # views.py
# from rest_framework import viewsets, permissions, status, generics, parsers
# from rest_framework.decorators import action
# from rest_framework.response import Response
# from .models import Diary, DiaryImage
# from .serializers import (
#     DiarySerializer, DiaryCreateSerializer, 
#     DiaryImageSerializer, UserSerializer
# )
# from django.contrib.auth.models import User

# class IsOwner(permissions.BasePermission):
#     """
#     Custom permission to only allow owners of an object to access it
#     """
#     def has_object_permission(self, request, view, obj):
#         # Check if the user is the owner of the diary
#         if hasattr(obj, 'user'):
#             return obj.user == request.user
#         # For DiaryImage, check the diary owner
#         if hasattr(obj, 'diary'):
#             return obj.diary.user == request.user
#         return False

# class DiaryViewSet(viewsets.ModelViewSet):
#     serializer_class = DiarySerializer
#     permission_classes = [permissions.IsAuthenticated, IsOwner]
#     parser_classes = [parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser]
    
#     def get_queryset(self):
#         """
#         This view returns a list of all diaries for the currently authenticated user.
#         """
#         user = self.request.user
#         return Diary.objects.filter(user=user)
    
#     def get_serializer_class(self):
#         if self.action == 'create':
#             return DiaryCreateSerializer
#         return DiarySerializer
    
#     @action(detail=True, methods=['post'], parser_classes=[parsers.MultiPartParser])
#     def upload_images(self, request, pk=None):
#         """
#         Upload one or multiple images for a diary entry
#         """
#         diary = self.get_object()
#         images = request.FILES.getlist('images')
        
#         if not images:
#             return Response({'error': 'No images provided'}, status=status.HTTP_400_BAD_REQUEST)
        
#         image_instances = []
#         for image in images:
#             instance = DiaryImage.objects.create(diary=diary, image=image)
#             image_instances.append(instance)
        
#         serializer = DiaryImageSerializer(
#             image_instances, many=True, context={'request': request}
#         )
#         return Response(serializer.data, status=status.HTTP_201_CREATED)
    
#     @action(detail=True, methods=['get'])
#     def images(self, request, pk=None):
#         """
#         Get all images for a diary entry
#         """
#         diary = self.get_object()
#         images = diary.images.all()
#         serializer = DiaryImageSerializer(
#             images, many=True, context={'request': request}
#         )
#         return Response(serializer.data)
    
#     @action(detail=False, methods=['get'])
#     def moods(self, request):
#         """
#         Get all available mood choices
#         """
#         return Response(dict(Diary.MOOD_CHOICES))
    
#     @action(detail=False, methods=['get'])
#     def templates(self, request):
#         """
#         Get all available templates
#         """
#         templates = [
#             'Default',
#             'Gratitude Journal',
#             'Daily Reflection',
#             'Travel Log',
#             'Dream Journal'
#         ]
#         template_contents = {
#             'Default': '',
#             'Gratitude Journal': 'Today I am grateful for:\n1. \n2. \n3. \n\nOne positive thing that happened today: ',
#             'Daily Reflection': 'Morning thoughts:\n\nMain achievements today:\n\nChallenges faced:\n\nLessons learned:',
#             'Travel Log': 'Location: \nWeather: \nPlaces visited: \n\nHighlights: \n\nFood tried: \n\nMemories:',
#             'Dream Journal': 'Dream summary: \n\nKey symbols: \n\nEmotions: \n\nPossible interpretations:'
#         }
        
#         return Response({
#             'templates': templates,
#             'template_contents': template_contents
#         })

# class DiaryImageViewSet(viewsets.ModelViewSet):
#     serializer_class = DiaryImageSerializer
#     permission_classes = [permissions.IsAuthenticated, IsOwner]
    
#     def get_queryset(self):
#         """
#         Optionally restricts the returned images to a given diary,
#         by filtering against a `diary_id` query parameter
#         """
#         user = self.request.user
#         queryset = DiaryImage.objects.filter(diary__user=user)
#         diary_id = self.request.query_params.get('diary_id')
#         if diary_id:
#             queryset = queryset.filter(diary_id=diary_id)
#         return queryset

# class UserDetail(generics.RetrieveUpdateAPIView):
#     """
#     API endpoint that allows users to view or update their own profile
#     """
#     serializer_class = UserSerializer
#     permission_classes = [permissions.IsAuthenticated]
    
#     def get_object(self):
#         return self.request.user
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.decorators import action
from django.db.models import Q
from datetime import datetime

from core.accounts import models
from .models import DiaryEntry
from .serializers import DiaryEntrySerializer

class DiaryEntryViewSet(viewsets.ModelViewSet):
    serializer_class = DiaryEntrySerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DiaryEntry.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def search(self, request):
        query = request.query_params.get('q', '')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        mood = request.query_params.get('mood')

        queryset = self.get_queryset()

        if query:
            queryset = queryset.filter(
                Q(title__icontains=query) | Q(content__icontains=query)
            )

        if start_date:
            try:
                start = datetime.strptime(start_date, '%Y-%m-%d')
                queryset = queryset.filter(date__gte=start)
            except ValueError:
                return Response(
                    {'error': 'Invalid start_date format'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        if end_date:
            try:
                end = datetime.strptime(end_date, '%Y-%m-%d')
                queryset = queryset.filter(date__lte=end)
            except ValueError:
                return Response(
                    {'error': 'Invalid end_date format'},
                    status=status.HTTP_400_BAD_REQUEST
                )

        if mood:
            queryset = queryset.filter(mood=mood)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        queryset = self.get_queryset()
        total_entries = queryset.count()
        mood_distribution = queryset.values('mood').annotate(
            count=models.Count('id')
        )
        template_usage = queryset.values('template').annotate(
            count=models.Count('id')
        )

        return Response({
            'total_entries': total_entries,
            'mood_distribution': mood_distribution,
            'template_usage': template_usage
            })