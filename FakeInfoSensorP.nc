#include "smartBracelets.h"

generic module FakeInfoSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer0;

} implementation {

	// ***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer0.startOneShot( 10000 ); // Fake sensor read performed every 10 seconds
		return SUCCESS;
	}

	// ***************** Timer0 interface ********************//
	event void Timer0.fired() {
		uint16_t sample[3];
		uint16_t x = call Random.rand16(); 
		uint16_t y = call Random.rand16(); 
		
		// Generating a random status based on the given probabilities
		uint16_t status = (call Random.rand16() % 99) + 1;
		if (status >= 0 && status < 30) {
			status = STANDING;
		}
		if (status > 30 && status <= 60) {
			status = WALKING;
		}
		if (status > 60 && status <= 90) {
			status = RUNNING;
		}
		if (status > 90 && status <= 100) {
			status = FALLING;
		}
		sample[0] = x;
		sample[1] = y;
		sample[2] = status;
		
		// Sending data to the MOTE
		signal Read.readDone( SUCCESS, sample );
	}
}
