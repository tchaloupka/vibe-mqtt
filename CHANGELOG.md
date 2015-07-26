vibe-mqtt changelog
===================

#### v0.2.0
##### New features
- Basic session state implemented (requirement for QoS1,2)
- Supports QoS1 packet handling (delivery retry still missing)

##### Bugs fixed
- Packet ID generator returns 0 on rollover - which is invalid

#### v0.1.0
- Initial release
