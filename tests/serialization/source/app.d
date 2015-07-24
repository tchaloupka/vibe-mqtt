import std.datetime;
import std.conv;
import std.array;
import std.stdio;

import msgpack;
import mqttd;

void usingMQTTD(T)(ref T item)
{   
    auto wr = appender!(ubyte[]).serialize(item);
    auto item2 = wr.data.deserialize!T();
    assert(item == item2);
}

void usingMSGPACK(T)(ref T item)
{
    auto data = pack(item);
    auto item2 = data.unpack!T();
    assert(item == item2);
}

void main()
{
    auto con = Connect();
    con.clientIdentifier = "testclient";
    con.flags.userName = true;
    con.userName = "user";

    auto sub = Subscribe();
    sub.packetId = 0xabcd;
    foreach(_; 0..10)
    {
        sub.topics ~= Topic("/root/*", QoSLevel.ExactlyOnce);
    }

    auto results = benchmark!(
            () => usingMQTTD(con), 
            () => usingMSGPACK(con),
            () => usingMQTTD(sub), 
            () => usingMSGPACK(sub),
        )(1_000_000);

    writeln("MQTT-D (Connect):  ", to!Duration(results[0]));
    writeln("MSGPACK-D (Connect):  ", to!Duration(results[1]));
    writeln("MQTT-D (Subscribe):  ", to!Duration(results[2]));
    writeln("MSGPACK-D (Subscribe):  ", to!Duration(results[3]));
}