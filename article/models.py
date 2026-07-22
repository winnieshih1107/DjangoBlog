from django.db import models
from markdownx.models import MarkdownxField

# Create your models here

class Post(models.Model):
    title = models.CharField(max_length=200)
    slug = models.CharField(max_length=200)
    content = MarkdownxField()
    pub_date = models.DateTimeField(auto_now_add=True)


    class Meta:
        ordering = ['-pub_date']


    def __str__(self):
        return self.title

