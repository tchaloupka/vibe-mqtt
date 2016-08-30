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
	settings.clientId = "publisher";

	auto mqtt = new MqttClient(settings);
	mqtt.connect();

	auto publisherQ0 = runTask(()
		{
			while (mqtt.connected)
			{
				mqtt.publish("chat/simple", "I'm still here!!!");

				sleep(2.seconds());
			}
		});

	auto publisherQ1 = runTask(()
		{
			sleep(1.seconds());
			while (mqtt.connected)
			{
				mqtt.publish("chat/qos1", "Ack required", QoSLevel.QoS1);

				sleep(2.seconds());
			}
		});
}
