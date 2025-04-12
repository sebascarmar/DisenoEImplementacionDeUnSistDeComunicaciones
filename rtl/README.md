# Instructions to use the communication system with uBlaze

## ber_counter
- Uncomment output ports (counters)
- Uncomment assignment of the output ports (counters)

## ber_top
- Uncomment output ports (I and Q counters)
- Uncomment output ports of the `ber_counter` I module
- Uncomment output ports of the `ber_counter` Q module

## adaptive_filter
- Uncomment output ports (input and output signals, and taps)
- Uncomment assignments of those ports

## qpsk_comm_sys
- Uncomment output ports (counters and FSE data)
- Uncomment output ports of the `adaptive_filter` module
- Uncomment output ports of the `ber_top` module
- Uncomment assignments of the remaining outputs (bottom part)

