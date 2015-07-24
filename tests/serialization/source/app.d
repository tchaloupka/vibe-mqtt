import std.datetime;
import std.conv;
import std.array;
import std.stdio;
import std.string : format;

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

    auto mqttd = appender!(ubyte[]).serialize(con).data;
    auto msgpack = pack(con);

    auto results = benchmark!(
            () => usingMQTTD(con), 
            () => usingMSGPACK(con)
        )(1_000_000);

    writeln(format("MQTT-D (Connect[%d]): ", mqttd.length), to!Duration(results[0]));
    writeln(format("MSGPACK-D (Connect[%d]): ", msgpack.length), to!Duration(results[1]));

    mqttd = appender!(ubyte[]).serialize(sub).data;
    msgpack = pack(sub);

    results = benchmark!(
        () => usingMQTTD(sub), 
        () => usingMSGPACK(sub),
        )(1_000_000);
    
    writeln(format("MQTT-D (Subscribe[%d]): ", mqttd.length), to!Duration(results[0]));
    writeln(format("MSGPACK-D (Subscribe[%d]): ", msgpack.length), to!Duration(results[1]));
}