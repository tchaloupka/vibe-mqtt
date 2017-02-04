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

	setLogFormat(FileLogger.Format.threadTime);

	auto settings = Settings();
	settings.clientId = "publisher";

	auto mqtt = new MqttClient(settings);
	mqtt.connect();

	auto publisherQ0 = runTask(()
		{
			while (mqtt.connected)
			{
				mqtt.publish("chat/simple", "QoS0 message");

				sleep(3.seconds());
			}
		});

	auto publisherQ1 = runTask(()
		{
			sleep(1.seconds());
			while (mqtt.connected)
			{
				mqtt.publish("chat/qos1", "QoS1 message", QoSLevel.QoS1);

				sleep(3.seconds());
			}
		});

	auto publisherQ2 = runTask(()
		{
			sleep(2.seconds());
			while (mqtt.connected)
			{
				mqtt.publish("chat/qos2", "QoS2 message", QoSLevel.QoS2);

				sleep(3.seconds());
			}
		});
}
