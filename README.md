[![Build Status](https://travis-ci.org/tchaloupka/vibe-mqtt.svg?branch=master)](https://travis-ci.org/tchaloupka/vibe-mqtt)
[![Dub downloads](https://img.shields.io/dub/dt/vibe-mqtt.svg)](http://code.dlang.org/packages/vibe-mqtt)
[![License](https://img.shields.io/dub/l/vibe-mqtt.svg)](http://code.dlang.org/packages/vibe-mqtt)
[![Latest version](https://img.shields.io/dub/v/vibe-mqtt.svg)](http://code.dlang.org/packages/vibe-mqtt)

vibe-mqtt
=========
[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) broker client library written completely in D.

**MQTT protocol version supported:** 3.1.1

**Depends on:** [vibe.d](https://github.com/rejectedsoftware/vibe.d)

**Tested on:**
* [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled - **Doesn't support QoS2**
* [Mosquitto](http://mosquitto.org/)

**Supported MQTT 3.1.1 features:**
- [x] QoS0, QoS1 and QoS2 messages handling
- [x] Authentication
- [x] Session state storage (currently in memory only - [#20](https://github.com/tchaloupka/vibe-mqtt/issues/20))
- [x] Sending retain messages
- [x] Async API (publish blocks if send queue is full)
- [x] Data agnostic
- [x] Message ordering
- [x] KeepAlive mechanism support (PingReq/PingResp) ([#11](https://github.com/tchaloupka/vibe-mqtt/issues/11))
- [ ] On subscribe topics validation ([#17](https://github.com/tchaloupka/vibe-mqtt/issues/17))
- [ ] Last Will and Testament (LWT) ([#21](https://github.com/tchaloupka/vibe-mqtt/issues/21))
- [ ] Delivery retry ([#14](https://github.com/tchaloupka/vibe-mqtt/issues/22))
- [ ] Auto reconnect to broker ([#15](https://github.com/tchaloupka/vibe-mqtt/issues/22))
- [ ] TLS/SSL ([#16](https://github.com/tchaloupka/vibe-mqtt/issues/22))

Pull Requests are welcome, don't be shy ;)

# Usage

Example code can be found in the `examples` directory.

## Publisher
Simple publisher which connects to the MQTT broker and periodically sends a message.
Implicitly it connects to 127.0.0.1:1883

```D
auto settings = Settings();
settings.clientId = "test publisher";

auto mqtt = new MqttClient(settings);
mqtt.connect();

auto publisher = runTask(() {
        while (mqtt.connected) {
            mqtt.publish("chat", "I'm still here!!!");
            sleep(2.seconds());
        }
    });
```

## Subscriber
Simple subscriber which connects to the MQTT broker, subscribes to the topic and outputs each received message.
Implicitly it connects to 127.0.0.1:1883

```D
class Subscriber : MqttClient {
    this(Settings settings) {
        super(settings);
    }

    override void onPublish(Publish packet) {
        super.onPublish(packet);
        writeln("chat: ", cast(string)packet.payload);
    }

    override void onConnAck(ConnAck packet) {
        super.onConnAck(packet);
        this.subscribe(["chat"]);
    }
}

auto settings = Settings();
settings.clientId = "test subscriber";

auto mqtt = new Subscriber(settings);
mqtt.connect();
```
