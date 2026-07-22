from django.shortcuts import render, get_object_or_404
from django.http import HttpResponse
from article.models import  Post
from datetime import datetime

# Create your views here.


def index(request):
    #posts = Post.objects.all()
    #post_list = list() 

    #for count, post in enumerate(posts): 
    #    post_list.append("{}:{}<br><hr>".format(str(count), str(post)))
    #    post_list.append("<small>{}</small><br><hr>".format(post.content))
    #    post_list.append("<h6><i>{}</i></h6></br>".format(str(post.slug)))
    #    post_list.append("<h6>{}</h6>".format(str(post.pub_date)))

    #return HttpResponse(post_list)
    now = datetime.now()
    posts = Post.objects.all()
    
    return render(request, "article/list.html", {'posts': posts, 'now': now})


def detail(request, pk):
    post = get_object_or_404(Post, pk=pk)

    return render(request, "article/detail.html", {'post': post})
