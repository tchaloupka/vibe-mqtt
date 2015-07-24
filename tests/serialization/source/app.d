import mqttd;

import std.datetime;
import std.conv;
import std.array;
import std.stdio;

void test() {
    auto con = Connect();
    con.clientIdentifier = "testclient";
    con.flags.userName = true;
    con.userName = "user";
	
	auto wr = writer(appender!(ubyte[]));
	wr.serialize(con);
	
	auto data = reader(wr.data);
    auto con2 = deserialize!Connect(data);
    assert(con == con2);
}


void main() {
    auto results = benchmark!(test)(1_000_000);
    writeln("Completed in:  ", to!Duration(results[0]));
}