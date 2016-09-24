[![Build Status](https://travis-ci.org/tchaloupka/vibe-mqtt.svg?branch=master)](https://travis-ci.org/tchaloupka/vibe-mqtt)

vibe-mqtt
=========
[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) broker client library written in D.

**MQTT protocol version supported:** 3.1.1

**Depends on:** [vibe.d](https://github.com/rejectedsoftware/vibe.d)

**Tested on:** [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled.

**Status:** Supports QoS level 0 and QoS level 1 (QoS 2 TBD - [#12](https://github.com/tchaloupka/vibe-mqtt/issues/12))

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
