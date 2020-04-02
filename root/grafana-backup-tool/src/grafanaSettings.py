import os

GRAFANA_URL = os.getenv('GRAFANA_URL', 'http://127.0.0.1:3001')
TOKEN = os.getenv('GRAFANA_TOKEN', 'eyJrIjoiVDcwQkZrN3lWSUE2M0NLVkVFUGg1bklEOElwRVFmRFciLCJuIjoiYmFja3VwIiwiaWQiOjF9')
HTTP_GET_HEADERS = {'Authorization': 'Bearer ' + TOKEN}
HTTP_POST_HEADERS = {'Authorization': 'Bearer ' + TOKEN, 'Content-Type': 'application/json'}
SEARCH_API_LIMIT = 10000
DEBUG = True
VERIFY_SSL = False
