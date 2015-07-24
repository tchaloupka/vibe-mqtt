import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;

import mqttd;

shared static this()
{
    auto settings = Settings();

    auto mqtt = new MqttClient(settings);
    mqtt.connect();
}
