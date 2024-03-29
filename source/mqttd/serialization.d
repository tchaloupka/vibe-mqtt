﻿/**
 * Serialization and deserialization of MQTT protocol messages
 *
 * Author:
 * Tomáš Chaloupka <chalucha@gmail.com>
 *
 * License:
 * Boost Software License 1.0 (BSL-1.0)
 *
 * Permission is hereby granted, free of charge, to any person or organization obtaining a copy
 * of the software and accompanying documentation covered by this license (the "Software") to use,
 * reproduce, display, distribute, execute, and transmit the Software, and to prepare derivative
 * works of the Software, and to permit third-parties to whom the Software is furnished to do so,
 * all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including the above license
 * grant, this restriction and the following disclaimer, must be included in all copies of the Software,
 * in whole or in part, and all derivative works of the Software, unless such copies or derivative works
 * are solely in the form of machine-executable object code generated by a source language processor.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR ANYONE
 * DISTRIBUTING THE SOFTWARE BE LIABLE FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
module mqttd.serialization;

import std.string : format;
import std.range;

import mqttd.messages;
import mqttd.traits;

debug import std.stdio;

@safe:

auto serialize(R, T)(auto ref R output, ref T item) if (canSerializeTo!(R))
{
	auto ser = serializer(output);
	ser.serialize(item);
	return ser;
}

auto serializer(R)(auto ref R output) if (canSerializeTo!(R))
{
	return Serializer!R(output);
}

struct Serializer(R) if (canSerializeTo!(R))
{
	this(R output)
	{
		_output = output;
	}

	@safe
	void put(const ubyte val)
	{
		_output.put(val);
	}

	@safe
	void put(scope const(ubyte)[] val)
	{
		_output.put(val);
	}

	static if(__traits(hasMember, R, "data"))
	{
		@safe
		@property auto data() nothrow
		{
			return _output.data();
		}
	}

	static if(__traits(hasMember, R, "clear"))
	{
		void clear()
		{
			_output.clear();
		}
	}

	/// Serialize given Mqtt packet
	void serialize(T)(ref T item) if (isMqttPacket!T)
	{
		static assert(hasFixedHeader!T, format("'%s' packet has no required header field!", T.stringof));

		mixin processMembersTemplate!(uint, `res += f.itemLength;`) L;
		mixin processMembersTemplate!(uint, `write(f);`) W;

		//set remaining packet length by checking packet conditions
		item.header.length = L.processMembers(item);

		static if (__traits(hasMember, R, "reserve")) // we can reserve required size to serialize packet
		{
			_output.reserve(item.header.length + 4); // 4 = max header size
		}

		//check if is valid
		try item.validate();
		catch (Exception ex)
			throw new PacketFormatException(format("'%s' packet is not valid: %s", T.stringof, ex.msg), ex);

		//write members to output writer
		W.processMembers(item);
	}

	package ref Serializer write(T)(T val) if (canWrite!T)
	{
		import std.traits : isDynamicArray;

		bool handled = true;
		static if (is(T == FixedHeader)) // first to avoid implicit conversion to ubyte
		{
			put(val.flags);

			int tmp = val.length;
			do
			{
				byte digit = tmp % 128;
				tmp /= 128;
				if (tmp > 0) digit |= 0x80;
				put(digit);
			} while (tmp > 0);
		}
		else static if (is(T:ubyte))
		{
			put(val);
		}
		else static if (is(T:ushort))
		{
			put(cast(ubyte) (val >> 8));
			put(cast(ubyte) val);
		}
		else static if (is(T:string))
		{
			import std.string : representation;
			import std.exception : enforce;

			enforce(val.length <= 0xFF, "String too long: ", val);

			write((cast(ushort)val.length));
			put(val.representation);
		}
		else static if (isDynamicArray!T)
		{
			static if (is(ElementType!T == ubyte)) put(val);
			else foreach(ret; val) write(ret);
		}
		else static if (is(T == struct)) //write struct members individually
		{
			foreach(memberName; __traits(allMembers, T))
				write(__traits(getMember, val, memberName));
		}
		else
		{
			handled = false;
		}

		if (handled) return this;
		assert(0, "Not implemented write for: " ~ T.stringof);
	}

private:
	R _output;
}

template deserialize(T)
{
	auto deserialize(R)(auto ref R input) if (canDeserializeFrom!(R))
	{
		return deserializer(input).deserialize!T();
	}
}

auto deserializer(R)(auto ref R input) if (canDeserializeFrom!(R))
{
	return Deserializer!R(input);
}

struct Deserializer(R) if (canDeserializeFrom!(R))
{
	this(R input)
	{
		_input = input;
	}

	@property ubyte front()
	{
		//debug writef("%.02x ", _input.front);
		return cast(ubyte)_input.front;
	}

	@property bool empty()
	{
		//debug if (_input.empty) writeln();
		return _input.empty;
	}

	void popFront()
	{
		_input.popFront();
		if(_remainingLen > 0) _remainingLen--; //decrease remaining length set from fixed header
		//debug writefln("Pop: %s", empty? "empty" : format("%.02x", front));
	}

	T deserialize(T)() if (isMqttPacket!T)
	{
		import std.typetuple;
		import std.exception : enforce;

		static assert(hasFixedHeader!T, format("'%s' packet has no required header field!", T.stringof));

		mixin processMembersTemplate!(void, "item.tupleof[i] = read!(typeof(f))();");

		T res;

		processMembers(res);

		enforce(empty, "Some data are remaining after packet deserialization!");

		// validate initialized packet
		try res.validate();
		catch (Exception ex)
			throw new PacketFormatException(format("'%s' packet is not valid: %s", T.stringof, ex.msg), ex);

		return res;
	}

	package T read(T)() if (canRead!T)
	{
		import std.traits : isDynamicArray;

		auto handled = true;
		T res;

		static if (is(T == FixedHeader)) // first to avoid implicit conversion to ubyte
		{
			res.flags = read!ubyte();
			res.length = 0;

			uint multiplier = 1;
			ubyte digit;
			do
			{
				digit = read!ubyte();
				res.length += ((digit & 127) * multiplier);
				multiplier *= 128;
				if (multiplier > 128*128*128) throw new PacketFormatException("Malformed remaining length");
			} while ((digit & 128) != 0);

			//set remaining length for calculations
			_remainingLen = res.length;
		}
		else static if (is(T:ubyte))
		{
			res = cast(T)front;
			popFront();
		}
		else static if (is(T:ushort))
		{
			res = cast(ushort) (read!ubyte() << 8);
			res |= cast(ushort) read!ubyte();
		}
		else static if (is(T:string))
		{
			import std.array : array;
			import std.algorithm : map;

			auto length = read!ushort();
			static if(hasSlicing!R)
			{
				//writeln(cast(string)_input[0..length]);
				res = (cast(char[])_input[0..length]).idup;
				_remainingLen -= length;
				_input = _input.length > length ? _input[length..$] : R.init;
			}
			else res = (&this).takeExactly(length).map!(a => cast(immutable char)a).array;
		}
		else static if (isDynamicArray!T)
		{
			res = T.init;
			static if (is(ElementType!T == ubyte) && hasSlicing!R) //slice it
			{
				res = _input[0..$];
				_remainingLen -= res.length;
				_input = R.init;
			}
			else
			{
				while(_remainingLen > 0) // read to end
				{
					res ~= read!(ElementType!T)();
				}
			}
		}
		else static if (is(T == struct)) //read struct members individually
		{
			foreach(memberName; __traits(allMembers, T))
				__traits(getMember, res, memberName) = read!(typeof(__traits(getMember, res, memberName)))();
		}
		else
		{
			handled = false;
		}

		if (handled) return res;
		assert(0, "Not implemented read for: " ~ T.stringof);
	}

private:
	R _input;
	uint _remainingLen;
}

/// Gets required buffer size to encode into
@safe @nogc
uint itemLength(T)(auto ref scope const T item) pure nothrow
{
	import std.traits : isDynamicArray;

	static if (is(T == FixedHeader)) return 0;
	else static if (is(T:ubyte)) return 1;
	else static if (is(T:ushort)) return 2;
	else static if (is(T:string)) return cast(uint)(2 + item.length);
	else static if (is(T == QoSLevel[])) return cast(uint)item.length;
	else static if (is(T == Topic)) return 3u + cast(uint)item.filter.length;
	else static if (isDynamicArray!T)
	{
		static if (is(ElementType!T == ubyte)) return cast(uint)item.length;
		else
		{
			uint len;
			foreach(ref e; item) len += e.itemLength();
			return len;
		}
	}
	else assert(0, "Not implemented itemLength for " ~ T.stringof);
}

@safe
void validate(T)(auto ref scope const T packet) pure
{
	import std.string : format;
	import std.exception : enforce;

	static if (__traits(hasMember, T, "header"))
	{
		import std.typecons : Nullable;

		void checkHeader(ubyte value, ubyte mask = 0xFF, Nullable!uint length = Nullable!uint())
		{
			enforce((mask & 0xF0) == 0x00
				|| (packet.header & 0xF0 & mask) == (value & 0xF0),
				"Wrong packet type");

			enforce((mask & 0x0F) == 0x00
				|| (packet.header & 0x0F & mask) == (value & 0x0F),
				"Wrong fixed header flags");

			enforce(length.isNull || packet.header.length == length.get, "Wrong fixed header length");
		}
	}

	static if (__traits(hasMember, T, "clientIdentifier"))
	{
		import std.string : representation;

		if (packet.clientIdentifier.length == 0)
			enforce(
				packet.flags.cleanSession,
				"If the Client supplies a zero-byte ClientId, the Client MUST also set CleanSession to 1");

		// note that some broker implementations MAY not support client identifiers with more than 23 encoded bytes - http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc385349242
	}

	static if (is(T == ConnectFlags))
	{
		enforce(packet.will || (packet.willQoS == QoSLevel.QoS0 && !packet.willRetain),
			"WillQoS and Will Retain MUST be 0 if Will flag is not set");
		enforce(packet.userName || !packet.password, "Password MUST be set to 0 if User flag is 0");
	}
	else static if (is(T == Connect))
	{
		checkHeader(0x10);
		enforce(packet.header.length != 0, "Length must be set!");
		enforce(packet.protocolName == MQTT_PROTOCOL_NAME,
			format("Wrong protocol name '%s', must be '%s'", packet.protocolName, MQTT_PROTOCOL_NAME));
		enforce(packet.protocolLevel == MQTT_PROTOCOL_LEVEL_3_1_1,
			format("Unsupported protocol level '%d', must be '%d' (v3.1.1)", packet.protocolLevel, MQTT_PROTOCOL_LEVEL_3_1_1));
		packet.flags.validate();
		enforce(!packet.flags.userName || packet.userName.length > 0, "Username not set");
		enforce(packet.flags.userName || !packet.flags.password > 0, "Username not set, but password is");
	}
	else static if (is(T == ConnAck))
	{
		checkHeader(0x20, 0xFF, Nullable!uint(0x02));
		enforce(packet.flags <= 1, "Invalid Connect Acknowledge Flags");
		enforce(packet.returnCode <= 5, "Invalid return code");
	}
	else static if(is(T == Subscribe))
	{
		checkHeader(0x82, 0xFF);
		enforce(packet.topics.length > 0, "At least one topic filter MUST be provided");
		enforce(packet.header.length >= 5, "Invalid length");
	}
}

mixin template processMembersTemplate(R, string fn)
{
	private R processMembers(T)(ref T item) if (isMqttPacket!T)
	{
		enum hasReturn = !is(R == void);

		static if (hasReturn)
		{
			R res;
		}

		import std.typetuple;

		foreach(i, f; item.tupleof)
		{
			enum memberName = __traits(identifier, T.tupleof[i]);
			static if (is(T == Connect)) //special case for Connect packet
			{
				static if (memberName == "willTopic" || memberName == "willMessage")
				{
					if (!item.flags.will) continue;
				}
				else static if (memberName == "userName") { if (!item.flags.userName) continue; }
				else static if (memberName == "password") { if (!item.flags.password) continue; }
			}
			else static if(is(T == Publish)) //special case for Publish packet
			{
				static if (memberName == "packetId") if (item.header.qos == QoSLevel.QoS0) continue;
			}

			//debug writeln("processing ", memberName);
			mixin(fn);
		}

		static if (hasReturn)
		{
			return res;
		}
	}
}
