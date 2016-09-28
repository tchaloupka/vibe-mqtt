#!/usr/bin/env dub
/+ dub.json:
{
    "name": "benchmark",
    "dependencies": {
        "vibe-mqtt": {"version": "~master", "path": "../../"}
    },
    "versions": ["VibeDefaultMain", "MqttDebug"]
}
+/
import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;
import vibe.core.core : yield, exitEventLoop;

import mqttd;

enum NUM_MESSAGES = 1_000_000u;

shared static this()
{
	import vibe.core.log;
	import vibe.core.core : sleep, runTask;
	import core.time;

	setLogFormat(FileLogger.Format.threadTime);

	auto settings = Settings();
	settings.clientId = "publisher";
	settings.sendQueueSize = 10;
	settings.inflightQueueSize = 5;

	auto mqtt = new MqttClient(settings);
	mqtt.connect();

	runTask(()
		{
			StopWatch sw;
			sw.start();
			foreach (_; 0..NUM_MESSAGES)
			{
				mqtt.publish("chat/simple", "QoS0 message");
				yield();
			}

			writefln("%d QoS0 messages sent in %d[ms], average %s/s", NUM_MESSAGES, sw.peek.msecs, cast(double)(1_000*NUM_MESSAGES)/sw.peek.msecs);
			sw.reset();

			foreach (_; 0..NUM_MESSAGES)
			{
				mqtt.publish("chat/qos1", "QoS1 message", QoSLevel.QoS1);
				yield();
			}
			
			writefln("%d QoS1 messages sent in %d[ms], average %s/s", NUM_MESSAGES, sw.peek.msecs, cast(double)(1_000*NUM_MESSAGES)/sw.peek.msecs);
			sw.reset();

			foreach (_; 0..NUM_MESSAGES)
			{
				mqtt.publish("chat/qos2", "QoS2 message", QoSLevel.QoS2);
				yield();
			}
			
			writefln("%d QoS2 messages sent in %d[ms], average %s/s", NUM_MESSAGES, sw.peek.msecs, cast(double)(1_000*NUM_MESSAGES)/sw.peek.msecs);
			sw.stop();

			exitEventLoop();
		});
}

