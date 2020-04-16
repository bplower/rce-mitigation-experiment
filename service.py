
from werkzeug.wrappers import Request
from werkzeug.wrappers import Response

def leaky_function(payload):
    return eval(payload)

class CodeExecService:
    def __init__(self, config_path):
        self.config = open(config_path, 'r').read()

    def endpoint_controller(self, request):
        payload = request.get_data().decode("utf-8")
        return Response(leaky_function(payload))

    def wsgi_app(self, environ, start_response):
        request = Request(environ)
        response = self.endpoint_controller(request)
        return response(environ, start_response)

    def __call__(self, environ, start_response):
        return self.wsgi_app(environ, start_response)
