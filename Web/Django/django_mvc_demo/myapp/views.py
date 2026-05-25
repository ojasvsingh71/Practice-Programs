from django.shortcuts import render

from .forms import StudentForm


def home(request):
	form = StudentForm()
	return render(request, 'myapp/home.html', {'form': form})


def submit_form(request):
	if request.method != 'POST':
		return render(request, 'myapp/home.html', {'form': StudentForm()})

	form = StudentForm(request.POST)
	if not form.is_valid():
		return render(request, 'myapp/home.html', {'form': form})

	return render(request, 'myapp/response.html', {'data': form.cleaned_data})
