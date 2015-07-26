vibe-mqtt
=========

# Description
[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) broker client library written in D.

MQTT protocol version supported: 3.1.1

Depends on: [vibe.d](https://github.com/rejectedsoftware/vibe.d)

Tested on: [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled.

[![Build Status](https://travis-ci.org/chalucha/vibe-mqtt.svg?branch=master)](https://travis-ci.org/chalucha/vibe-mqtt)

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

# Backlog items (pull requests are welcome)

## Wait for ConnAck on Connect
If ConnAck is not received after sending Connect packet, client has to disconnect itself.
Clients typically wait for a CONNACK Packet, However, if the Client exploits its freedom to send Control Packets before it receives a CONNACK, it might simplify the Client implementation as it does not have to police the connected state. The Client accepts that any data that it sends before it receives a CONNACK packet from the Server will not be processed if the Server rejects the connection.
Clients need not wait for a CONNACK Packet to arrive from the Server.

## Proper Packet Id usage
Each time a Client sends a new packet (which has packetId) it MUST assign it a currently unused Packet Identifier. If a Client re-sends a particular Control Packet, then it MUST use the same Packet Identifier in subsequent re-sends of that packet. The Packet Identifier becomes available for reuse after the Client has processed the corresponding acknowledgement packet. In the case of a QoS 1 PUBLISH this is the corresponding PUBACK; in the case of QoS 2 it is PUBCOMP. For SUBSCRIBE or UNSUBSCRIBE it is the corresponding SUBACK or UNSUBACK.

## PingReq and PingResp handling
Add possibility to automatically send PingReq and handle delivery (or not) of PingResp to check connection state.

## QoS level support above 0
Specs - [Quality of Service levels and protocol flows](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718099)

MQTT delivers Application Messages according to the Quality of Service (QoS) levels. The delivery protocol is symmetric, in the description below the Client can take the role of either Sender or Receiver. The delivery protocol is concerned solely with the delivery of an application message from a single Sender to a single Receiver. When the Server is delivering an Application Message to more than one Client, each Client is treated independently. The QoS level used to deliver an Application Message outbound to the Client could differ from that of the inbound Application Message.

### QoS 1
This quality of service ensures that the message arrives at the receiver at least once. A QoS 1 PUBLISH Packet has a Packet Identifier in its variable header and is acknowledged by a PUBACK Packet.

#### Sender
- **[DONE]** MUST assign an unused Packet Identifier each time it has a new Application Message to publish.
- **[DONE]**MUST send a PUBLISH Packet containing this Packet Identifier with QoS=1, DUP=0.
- MUST treat the PUBLISH Packet as “unacknowledged” until it has received the corresponding PUBACK packet from the receiver.

#### Receiver
- **[DONE]** MUST respond with a PUBACK Packet containing the Packet Identifier from the incoming PUBLISH Packet, having accepted ownership of the Application Message
- **[DONE]** After it has sent a PUBACK Packet the Receiver MUST treat any incoming PUBLISH packet that contains the same Packet Identifier as being a new publication, irrespective of the setting of its DUP flag.

### QoS 2
This is the highest quality of service, for use when neither loss nor duplication of messages are acceptable. There is an increased overhead associated with this quality of service.

A QoS 2 message has a Packet Identifier in its variable header. The receiver of a QoS 2 PUBLISH Packet acknowledges receipt with a two-step acknowledgement process.

#### Sender
- **[DONE]** MUST assign an unused Packet Identifier when it has a new Application Message to publish.
- **[DONE]** MUST send a PUBLISH packet containing this Packet Identifier with QoS=2, DUP=0.
- MUST treat the PUBLISH packet as “unacknowledged” until it has received the corresponding PUBREC packet from the receiver.
- MUST send a PUBREL packet when it receives a PUBREC packet from the receiver. This PUBREL packet MUST contain the same Packet Identifier as the original PUBLISH packet.
- MUST treat the PUBREL packet as “unacknowledged” until it has received the corresponding PUBCOMP packet from the receiver.
- MUST NOT re-send the PUBLISH once it has sent the corresponding PUBREL packet.

#### Receiver
- MUST respond with a PUBREC containing the Packet Identifier from the incoming PUBLISH Packet, having accepted ownership of the Application Message.
- Until it has received the corresponding PUBREL packet, the Receiver MUST acknowledge any subsequent PUBLISH packet with the same Packet Identifier by sending a PUBREC. It MUST NOT cause duplicate messages to be delivered to any onward recipients in this case.
- MUST respond to a PUBREL packet by sending a PUBCOMP packet containing the same Packet Identifier as the PUBREL.
- After it has sent a PUBCOMP, the receiver MUST treat any subsequent PUBLISH packet that contains that Packet Identifier as being a new publication.

## Message delivery retry
Specs - [Message delivery retry](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718103), [Message ordering](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718105)

When a Client reconnects with CleanSession set to 0, both the Client and Server MUST re-send any unacknowledged PUBLISH Packets (where QoS > 0) and PUBREL Packets using their original Packet Identifiers. This is the only circumstance where a Client or Server is REQUIRED to redeliver messages.

## Maintain client session state
Specs - [Storing state](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Toc398718096)

It is necessary for the Client Session state in order to provide Quality of Service guarantees. The Client MUST store Session state for the entire duration of the Session. A Session MUST last at least as long it has an active Network Connection.

Add possibility to connect with Clean Session flag on/off.

## Autoreconnect to broker
Allow automatic reconnections with broker if it disconnects due to network problems.

## Communication over TLS channel
Enable secure communication with TLS enabled broker.
