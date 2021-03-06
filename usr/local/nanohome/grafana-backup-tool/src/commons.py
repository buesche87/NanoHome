import sys

def left_ver_newer_than_right_ver(current_version, specefic_version):
    def convertVersion(ver):
        return int(''.join(ver.split(".")))
    return convertVersion(current_version) > convertVersion(specefic_version)

def print_horizontal_line():
    print('')
    print("########################################")
    print('')

def log_response(resp):
    status_code = resp.status_code
    print("[DEBUG] status: {0}".format(status_code))
    print("[DEBUG] body: {0}".format(resp.json()))
    return resp

def to_python2_and_3_compatible_string(some_string):
    if sys.version_info[0] > 2:
        return some_string
    else:
        return some_string.encode('utf8')
