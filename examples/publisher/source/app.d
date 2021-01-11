import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;

import mqttd;

void main()
{
	import vibe.core.log : setLogFormat, FileLogger;
	import vibe.core.core : sleep, runApplication, runTask;

	setLogFormat(FileLogger.Format.threadTime);

	auto settings = Settings();
	settings.clientId = "publisher";
	settings.reconnect = 1.seconds;
	settings.onConnAck = (scope MqttClient ctx, in ConnAck ack)
	{
		if (ack.returnCode != ConnectReturnCode.ConnectionAccepted) return;

		auto publisherQ0 = runTask(()
			{
				while (ctx.connected)
				{
					ctx.publish("chat/simple", "QoS0 message");

					sleep(3.seconds());
				}
			});

		auto publisherQ1 = runTask(()
			{
				sleep(1.seconds());
				while (ctx.connected)
				{
					ctx.publish("chat/qos1", "QoS1 message", QoSLevel.QoS1);

					sleep(3.seconds());
				}
			});

		auto publisherQ2 = runTask(()
			{
				sleep(2.seconds());
				while (ctx.connected)
				{
					ctx.publish("chat/qos2", "QoS2 message", QoSLevel.QoS2);

					sleep(3.seconds());
				}
			});
	};

	auto mqtt = new MqttClient(settings);
	mqtt.connect();
	scope (exit) mqtt.disconnect();

	runApplication();
}
