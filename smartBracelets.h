#ifndef SMARTBRACELETS_H
#define SMARTBRACELETS_H

// Pairing phase messages
typedef nx_struct pair {
	nx_uint16_t type; // either PAIR or STOP_PAIRING
	nx_uint8_t key[21]; 
} pair_t;

// Operation mode messages
typedef nx_struct info {
	nx_uint16_t status; // Status can be STANDING WALKING RUNNING FALLING
	nx_uint16_t position_x; // Position of the child bracelet on the X axis
	nx_uint16_t position_y; // Position of the child bracelet on the Y axis
} info_t;

#define PAIR 1
#define STOP_PAIR 2
#define STANDING 3
#define WALKING 4
#define RUNNING 5
#define FALLING 6 

enum{
	AM_MY_MSG = 6,
};

#endif
