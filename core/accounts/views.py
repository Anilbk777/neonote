from rest_framework import status, generics
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from .models import CustomUser
from .serializers import CustomUserSerializer
from rest_framework.permissions import AllowAny

import logging

# Set up logging
logger = logging.getLogger(__name__)

class RegisterUserView(generics.CreateAPIView):
    """
    View to register a new user.
    """
    queryset = CustomUser.objects.all()
    serializer_class = CustomUserSerializer
    permission_classes = [AllowAny]  # No authentication required for registration


class LoginUserView(generics.GenericAPIView):
    """
    View to login and create a token for the user.
    """
    serializer_class = CustomUserSerializer
    permission_classes = [AllowAny]  # No authentication required for login

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')
        password = request.data.get('password')
        
        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            return Response({"detail": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        if not user.check_password(password):
            return Response({"detail": "Invalid credentials."}, status=status.HTTP_400_BAD_REQUEST)

        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token
        # Print access token in the terminal
        print(f"\n[DEBUG] Access Token for {email}: {access_token}\n")
        logger.info(f"Access Token for {email}: {access_token}")

        return Response({
            "refresh": str(refresh),
            "access": str(access_token),
        })
    
    
# views.py

from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import CustomUser
from .serializers import UserSerializer

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure only authenticated users can access this view
    
    def get(self, request):
        user = request.user  # `request.user` is the currently authenticated user
        serializer = UserSerializer(user)
        return Response(serializer.data)


