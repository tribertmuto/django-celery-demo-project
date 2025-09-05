from http import HTTPStatus
from django.http import JsonResponse
from django.conf import settings
from django.core.handlers.wsgi import WSGIHandler
from django.core.wsgi import get_wsgi_application

def handler(request, context):
    # For API routes
    if request['path'].startswith('/api/'):
        return {
            'statusCode': HTTPStatus.OK,
            'headers': {
                'Content-Type': 'application/json',
            },
            'body': {
                'message': 'Hello from Django Serverless Function!',
                'status': 'success',
                'path': request['path']
            }
        }
    
    # For all other routes, use the Django WSGI application
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    django_app = get_wsgi_application()
    response = django_app(request, context)
    
    return {
        'statusCode': response.status_code,
        'headers': dict(response.headers),
        'body': response.content.decode('utf-8') if response.content else ''
    }

# For local development
if __name__ == '__main__':
    from django.core.management import execute_from_command_line
    import os
    import sys
    
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
