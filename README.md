mqtt-d
=============

[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) client written in D.

Protocol version supported: 3.1.1

Depends on: [vibe.d](https://github.com/rejectedsoftware/vibe.d)

Tested on: [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled.

###Things to work on
####Proper PacketId usage
Each time a Client sends a new packet (which has packetId) it MUST assign it a currently unused Packet Identifier. If a Client re-sends a particular Control Packet, then it MUST use the same Packet Identifier in subsequent re-sends of that packet. The Packet Identifier becomes available for reuse after the Client has processed the corresponding acknowledgement packet. In the case of a QoS 1 PUBLISH this is the corresponding PUBACK; in the case of QoS 2 it is PUBCOMP. For SUBSCRIBE or UNSUBSCRIBE it is the corresponding SUBACK or UNSUBACK.

####QoS level support above 0
TODO

