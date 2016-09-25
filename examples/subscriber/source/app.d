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

	class Subscriber : MqttClient
	{
		this(Settings settings)
		{
			super(settings);
		}

		override void onPublish(Publish packet)
		{
			super.onPublish(packet);

			writeln(packet.topic, ": ", cast(string)packet.payload);
		}

		override void onConnAck(ConnAck packet)
		{
			super.onConnAck(packet);

			this.subscribe(["chat/#"], QoSLevel.QoS2);

			// unsubscribe after 15 seconds
			runTask(()
				{
					sleep(15.seconds());
					this.unsubscribe("chat/#");
				});

			// disconnect after 20 seconds
			runTask(()
				{
					sleep(20.seconds());
					this.disconnect();
				});
		}
	}

	setLogFormat(FileLogger.Format.threadTime);

	auto settings = Settings();
	settings.clientId = "test subscriber";

	auto mqtt = new Subscriber(settings);
	mqtt.connect();
}
