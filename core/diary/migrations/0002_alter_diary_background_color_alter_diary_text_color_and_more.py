# Generated by Django 5.1.6 on 2025-02-22 09:26

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('diary', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='diary',
            name='background_color',
            field=models.IntegerField(),
        ),
        migrations.AlterField(
            model_name='diary',
            name='text_color',
            field=models.IntegerField(),
        ),
    #     migrations.AlterField(
    #         model_name='diaryimage',
    #         name='image',
    #         field=models.ImageField(upload_to='diary_image/'),
    #     ),
    ]
