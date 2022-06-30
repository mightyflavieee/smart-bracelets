#ifndef SMARTBRACELETS_H
#define SMARTBRACELETS_H

// Pairing phase messages
typedef nx_struct pair {
	nx_uint16_t msg_type; // either PAIR or STOP_PAIRING
	nx_uint8_t[21] key; // 0 if the message type is STOP_PAIRING
} pair_t;

// Operation mode messages
typedef nx_struct info {
	nx_uint16_t status; // Status can be STANDING WALKING RUNNING FALLING
	nx_uint16_t position_x; // Posiotion of the child bracelet on the X assis
	nx_uint16_t position_y; // Posiotion of the child bracelet on the Y assis
} info_t;

#define PAIR 1
#define STOP_PAIRING 2
#define STANDING 3
#define WALKING 4
#define RUNNING 5
#define FALLING 6 

enum{
	AM_MY_MSG = 6,
};

#endif
