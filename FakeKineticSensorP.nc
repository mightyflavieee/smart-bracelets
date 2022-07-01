#include "smartBracelets.h"

generic module FakeKineticSensorP() {

	provides interface Read<uint16_t>;
	
	uses interface Random;
	uses interface Timer<TMilli> as Timer;

} implementation {

	// ***************** Boot interface ********************//
	command error_t Read.read(){
		call Timer.startOneShot( 10 );
		return SUCCESS;
	}

	// ***************** Timer0 interface ********************//
	event void Timer.fired() {
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
		
		// Sending data to the MOTE
		signal Read.readDone( SUCCESS, status );
	}
}
