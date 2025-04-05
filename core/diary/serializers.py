# serializers.py
from rest_framework import serializers
# from .models import Diary, DiaryImage
from django.contrib.auth.models import User
from .models import DiaryEntry

# class DiaryImageSerializer(serializers.ModelSerializer):
#     image_url = serializers.SerializerMethodField()
    
#     class Meta:
#         model = DiaryImage
#         fields = ['id', 'image', 'image_url', 'uploaded_at']
#         read_only_fields = ['uploaded_at']
    
#     def get_image_url(self, obj):
#         request = self.context.get('request')
#         if obj.image and request:
#             return request.build_absolute_uri(obj.image.url)
#         return None

# class DiarySerializer(serializers.ModelSerializer):
#     # images = DiaryImageSerializer(many=True, read_only=True)
#     # image_count = serializers.IntegerField(read_only=True)
    
#     class Meta:
#         model = DiaryEntry
#         fields = [
#             'id', 'title', 'content', 'date', 'created_at', 'updated_at',
#             'mood', 'background_color', 'text_color', 'template'
#         ]
#         read_only_fields = ['created_at', 'updated_at']

class DiaryEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DiaryEntry
        fields = ['id', 'title', 'content', 'date', 'mood', 'template', 
                 'background_color', 'text_color', 'created_at', 'updated_at']
        read_only_fields = ['created_at', 'updated_at']

    def create(self, validated_data):
        user = self.context['request'].user
        return DiaryEntry.objects.create(user=user, **validated_data)
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']