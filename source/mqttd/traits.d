﻿/**
 *
 * /home/tomas/workspace/mqtt-d/source/mqttd/traits.d
 *
 * Author:
 * Tomáš Chaloupka <chalucha@gmail.com>
 *
 * Copyright (c) 2015 Tomáš Chaloupka
 *
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
module mqttd.traits;

import std.range;
import std.traits : isDynamicArray, isIntegral;

import mqttd.messages;

/// Is one of Mqtt packet types?
enum bool isMqttPacket(T) = is(T == Connect) || is(T == ConnAck)
    || is(T == Publish) || is(T == PubAck) || is(T == PubRec) || is(T == PubRel) || is(T == PubComp)
        || is(T == Subscribe) || is(T == SubAck)
        || is(T == Unsubscribe) || is(T == UnsubAck)
        || is(T == PingReq) || is(T == PingResp)
        || is(T == Disconnect);

enum bool canReadBase(T) = is(T:ubyte) || is(T:ushort) || is(T:string)
    || is(T == FixedHeader) || is(T == ConnectFlags) || is(T == ConnAckFlags) || is(T == Topic);

/// Can T be read by Reader?
enum bool canRead(T) = canReadBase!T || (isDynamicArray!T && canReadBase!(ElementType!T));

/// Can T be written by Writer?
enum bool canWrite(T) = canRead!T;

/// Has Fixed Header member
enum bool hasFixedHeader(T) = is(typeof(()
        {
            auto obj = T.init;
            FixedHeader h = obj.header;
        }));

/// Range type Mqtt packed can be deserialized from
enum bool canDeserializeFrom(R) = isInputRange!R && isIntegral!(ElementType!R) && !isInfinite!R;

/// Range type Mqtt packed can be serialized to
enum bool canSerializeTo(R) = isOutputRange!(R, ubyte) &&
            is(typeof(() { auto r = R(); r.clear(); const(ubyte)[] d = r.data; }));

enum bool isCondition(C) = is(C : Condition!C, alias C);
