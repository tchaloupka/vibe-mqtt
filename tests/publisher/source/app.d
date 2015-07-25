import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;

import mqttd;

shared static this()
{
    import vibe.core.log : setLogFormat, FileLogger;
    import vibe.core.core : sleep, runTask;
    import core.time;

    setLogFormat(FileLogger.Format.threadTime);

    auto settings = Settings();
    settings.clientId = "test publisher";

    auto mqtt = new MqttClient(settings);
    mqtt.connect();

    auto publisher = runTask(() 
        {
            while (mqtt.connected)
            {
                mqtt.publish("chat", "I'm still here!!!");

                sleep(2.seconds());
            }
        });
}
