# Generated by Django 5.1.5 on 2025-04-07 15:36

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('goals', '0002_goal_created_at_goal_created_by_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='task',
            name='created_at',
        ),
        migrations.RemoveField(
            model_name='task',
            name='last_modified_at',
        ),
        migrations.RemoveField(
            model_name='task',
            name='last_modified_by',
        ),
    ]
