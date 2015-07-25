mqtt-d
=============

[MQTT](http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html) client written in D.

Protocol version supported: 3.1.1

Depends on: [vibe.d](https://github.com/rejectedsoftware/vibe.d)

Tested on: [RabbitMQ](https://www.rabbitmq.com) with [MQTT](https://www.rabbitmq.com/mqtt.html) plugin enabled.

###Things to work on
####Wait for ConnAck
If ConnAck is not received after sending Connect packet, client has to disconnect itself.
Clients typically wait for a CONNACK Packet, However, if the Client exploits its freedom to send Control Packets before it receives a CONNACK, it might simplify the Client implementation as it does not have to police the connected state. The Client accepts that any data that it sends before it receives a CONNACK packet from the Server will not be processed if the Server rejects the connection.
Clients need not wait for a CONNACK Packet to arrive from the Server.

####Proper PacketId usage
Each time a Client sends a new packet (which has packetId) it MUST assign it a currently unused Packet Identifier. If a Client re-sends a particular Control Packet, then it MUST use the same Packet Identifier in subsequent re-sends of that packet. The Packet Identifier becomes available for reuse after the Client has processed the corresponding acknowledgement packet. In the case of a QoS 1 PUBLISH this is the corresponding PUBACK; in the case of QoS 2 it is PUBCOMP. For SUBSCRIBE or UNSUBSCRIBE it is the corresponding SUBACK or UNSUBACK.

####PingReq and PingResp handling
Add possibility to automatically send PingReq and handle delivery (or not) of PingResp to check connection state.

####QoS level support above 0
TODO

####Maintain client session state
TODO

####Autoreconnect to broker
Allow automatic reconnections with broker if it disconnects due to network problems.
