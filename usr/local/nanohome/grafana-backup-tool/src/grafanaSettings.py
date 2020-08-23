import os

<<<<<<< HEAD
GRAFANA_URL = os.getenv('GRAFANA_URL', 'http://127.0.0.1:3001')
TOKEN = os.getenv('GRAFANA_TOKEN', 'eyJrIjoiVDcwQkZrN3lWSUE2M0NLVkVFUGg1bklEOElwRVFmRFciLCJuIjoiYmFja3VwIiwiaWQiOjF9')
=======
GRAFANA_URL = os.getenv('GRAFANA_URL', 'http://localhost:3000')
TOKEN = os.getenv('GRAFANA_TOKEN', 'eyJrIjoiSkQ5NkdvWllHdnVNdlVhWUV3Tm5LSGc4NG53UFdSTjQiLCJuIjoiYWRtaW4iLCJpZCI6MX0=')

EXTRA_HEADERS = dict(h.split(':') for h in os.getenv('GRAFANA_HEADERS', '').split(',') if 'GRAFANA_HEADERS' in os.environ)

>>>>>>> b45b703cf3afbce88d583e80984cfa8ea009fbb9
HTTP_GET_HEADERS = {'Authorization': 'Bearer ' + TOKEN}
HTTP_POST_HEADERS = {'Authorization': 'Bearer ' + TOKEN, 'Content-Type': 'application/json'}
for k,v in EXTRA_HEADERS.items():
    HTTP_GET_HEADERS.update({k: v})
    HTTP_POST_HEADERS.update({k: v})

SEARCH_API_LIMIT = 5000
DEBUG = True
VERIFY_SSL = False
