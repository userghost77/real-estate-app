from django.urls import path, include
from . import views

app_name = 'my-app'

urlpatterns = [
    path('', views.index, name='index'),
    path('api/validate/', views.validation_proxy, name='validate_proxy'),
    path('api/value/', views.valuation_proxy, name='value_proxy'),
    path('api/recommend/', views.recommendation_proxy, name='recommend_proxy'),
]
