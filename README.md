mqtt-d
=============

# Description
[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) client library written in D.

MQTT protocol version supported: 3.1.1

Depends on: [vibe.d](https://github.com/rejectedsoftware/vibe.d)

Tested on: [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled.

# Usage

Example code can be found in the `tests` directory.

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

## Serialization
Simple benchmark for MQTT messages serialization/deserialization with comparison to [msgpack-d](https://github.com/msgpack/msgpack-d)

# Backlog items (pull requests are welcome)

## Wait for ConnAck on Connect
If ConnAck is not received after sending Connect packet, client has to disconnect itself.
Clients typically wait for a CONNACK Packet, However, if the Client exploits its freedom to send Control Packets before it receives a CONNACK, it might simplify the Client implementation as it does not have to police the connected state. The Client accepts that any data that it sends before it receives a CONNACK packet from the Server will not be processed if the Server rejects the connection.
Clients need not wait for a CONNACK Packet to arrive from the Server.

## Proper PacketId usage
Each time a Client sends a new packet (which has packetId) it MUST assign it a currently unused Packet Identifier. If a Client re-sends a particular Control Packet, then it MUST use the same Packet Identifier in subsequent re-sends of that packet. The Packet Identifier becomes available for reuse after the Client has processed the corresponding acknowledgement packet. In the case of a QoS 1 PUBLISH this is the corresponding PUBACK; in the case of QoS 2 it is PUBCOMP. For SUBSCRIBE or UNSUBSCRIBE it is the corresponding SUBACK or UNSUBACK.

## PingReq and PingResp handling
Add possibility to automatically send PingReq and handle delivery (or not) of PingResp to check connection state.

## QoS level support above 0
TODO

## Maintain client session state
TODO

##Autoreconnect to broker
Allow automatic reconnections with broker if it disconnects due to network problems.
