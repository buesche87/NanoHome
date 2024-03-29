#!/usr/bin/env python3

"""A MQTT to InfluxDB Bridge

This script receives MQTT data and saves those to InfluxDB.

"""

import re
from typing import NamedTuple

import paho.mqtt.client as mqtt
from influxdb import InfluxDBClient

influxdb_server = 'localhost'
influxdb_database = 'INFLUXDATABASE'
influxdb_user = 'DATABASEUSER'
influxdb_userpass = 'DATABASEPASS'

mqtt_server = 'localhost'
mqtt_system_user = 'MQTTSYSTEMUSER'
mqtt_system_pass = 'MQTTSYSTEMPASS'

MQTT_TOPIC = 'home/+/+'  # [home/Device]/[temperature|humidity|status]
MQTT_REGEX = 'home/([^/]+)/([^/]+)' # Home Topic
MQTT_CLIENT_ID = 'mqtt_home_bridge'

influxdb_client = InfluxDBClient(influxdb_server, 8086, influxdb_user, influxdb_userpass, None)


#class SensorData(NamedTuple):
#    location = str
#    measurement = str
#    value = float

SensorData = NamedTuple('SensorData', [('location',str), ('measurement', str), ('value', float)])


def on_connect(client, userdata, flags, rc):
    """ The callback for when the client receives a CONNACK response from the server."""
    print('Connected with result code ' + str(rc))
    client.subscribe(MQTT_TOPIC)


def on_message(client, userdata, msg):
    """The callback for when a PUBLISH message is received from the server."""
    print(msg.topic + ' ' + str(msg.payload))
    sensor_data = _parse_mqtt_message(msg.topic, msg.payload.decode('utf-8'))
    if sensor_data is not None:
        _send_sensor_data_to_influxdb(sensor_data)


def _parse_mqtt_message(topic, payload):
    match = re.match(MQTT_REGEX, topic)
    if match:
        location = match.group(1)
        measurement = match.group(2)
        if measurement == 'status':
            return None
        return SensorData(location, measurement, float(payload))
    else:
        return None


def _send_sensor_data_to_influxdb(sensor_data):
    json_body = [
        {
            'measurement': sensor_data.measurement,
            'tags': {
                'location': sensor_data.location
            },
            'fields': {
                'value': sensor_data.value
            }
        }
    ]
    influxdb_client.write_points(json_body)


def _init_influxdb_database():
    databases = influxdb_client.get_list_database()
    if len(list(filter(lambda x: x['name'] == influxdb_database, databases))) == 0:
        influxdb_client.create_database(influxdb_database)
    influxdb_client.switch_database(influxdb_database)


def main():
    _init_influxdb_database()

    mqtt_client = mqtt.Client(MQTT_CLIENT_ID)
    mqtt_client.username_pw_set(mqtt_system_user, mqtt_system_pass)
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message

    mqtt_client.connect(mqtt_server, 1883)
    mqtt_client.loop_forever()


if __name__ == '__main__':
    print('MQTT to InfluxDB bridge')
    main()
