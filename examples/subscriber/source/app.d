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
	settings.clientId = "test subscriber";
	settings.reconnect = 1.seconds;
	settings.onPublish = (scope MqttClient ctx, in Publish packet)
	{
		writeln(packet.topic, ": ", (cast(const char[])packet.payload).idup);
	};
	settings.onConnAck = (scope MqttClient ctx, in ConnAck packet)
	{
		if (packet.returnCode != ConnectReturnCode.ConnectionAccepted) return;

		ctx.subscribe(["chat/#"], QoSLevel.QoS2);

		// unsubscribe after 15 seconds
		runTask(()
			{
				sleep(15.seconds());
				ctx.unsubscribe("chat/#");
			});

		// disconnect after 20 seconds
		runTask(()
			{
				sleep(20.seconds());
				ctx.disconnect();
			});
	};

	auto mqtt = new MqttClient(settings);
	mqtt.connect();
	scope (exit) mqtt.disconnect();

	runApplication();
}
