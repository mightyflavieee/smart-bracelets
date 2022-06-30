#include "smartBracelets.h"
#include "Timer.h"

module smartBraceletsC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
    
	// Interfaces for communication
    interface AMSend;
    interface Receive;
    interface Packet;
    interface PacketAcknowledgements as Acks;
    interface SplitControl;

	// Interface for timer
	interface Timer<TMilli>;
	
	// Interface used to perform kinetic status and coordinates fake reading
	interface Read<uint16_t>;

  }

} implementation {
	/*  
	*	ASSUMPTIONS:
	*	MOTE 1 AND MOTE 2 is a PAIR, they share KEY1.
	* MOTE 3 AND MOTE 4 is a PAIR, they share KEY2.
	*
	*	MOTE 1 AND MOTE 3 are PARENTS.
	*	MOTE 2 AND MOTE 4 are CHILDREN.
	*/

	uint8_t KEY1[21] = "AAAAAAAAAAAAAAAAAAAA\0";
	uint8_t KEY2[21] = "BBBBBBBBBBBBBBBBBBBB\0";
	uint8_t isPaired = 0;
	uint8_t last_x_position = 0;
	uint8_t last_y_position = 0;
  message_t packet;

	void sendINFOMessage(uint16_t data[3]);
	void sendPAIRMessage(uint8_t isStopPairing); 

	//***************** Boot interface ********************//
  event void Boot.booted() {
		dbg("logger","MOTE [%d]: Application booted.\n", TOS_NODE_ID);
		call SplitControl.start();
  }

	//***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
		/*
			If the split control is started successfully, then we can start the timer in order to send pairing messages.
			Otherwise, we can't start the timer.
		*/
    if(err == SUCCESS) {
			dbg("logger","MOTE [%d]: is starting the Timer...\n", TOS_NODE_ID);
			call Timer.startPeriodic(500);
    }
  }

	//***************** Send PAIR/STOP_PAIRING message function ********************//
	void sendPAIRMessage(uint8_t isStopPairing){
		/*
			This function is used to send PARING and STOP_PARING messages.
			If isStopPairing is equal to 1, then we send a STOP_PAIRING message.
			Otherwise, we send a PARING message.

			If TOS_NODE_ID is even, then we use KEY1 as KEY.
			Otherwise, we use KEY2 as KEY.
		*/
		pair_t* pair_msg = (pair_t*)call Packet.getPayload(&packet, sizeof(pair_t));
		if (pair_msg == NULL) return;

		if(isStopPairing == 1){
			pair_msg->type = STOP_PAIRING;
		}
		if(isStopPairing == 0){
			pair_msg->type = PAIR;
		}
		
		if(TOS_NODE_ID%2==0) {
			pair_msg->key = KEY1;
		}
		else {
			pair_msg->key = KEY2;
		}

		dbg("logger","MOTE [%d]: Sending INFO message type: PAIR, with key: %s.\n", TOS_NODE_ID, pair_msg->key);
		call AMSend.send(6, &packet, sizeof(pair_t));	
	}

	void sendINFOMessage(uint16_t data[3]){
		/*
			This function is used to send INFO messages.
			The data is composed of:
				data[0] = x_position
				data[1] = y_position
				data[2] = status
		*/
		info_t* info_msg = (info_t*) call Packet.getPayload(&packet, sizeof(info_t));
		if (info_msg == NULL) return;
		
		info_msg->position_x = data[0];
		info_msg->position_y = data[1];
		info_msg->status = data[2];

		dbg("logger","MOTE [%d]: Sending msg type: INFO, with position_x: %d, position_y: %d, status: %d.\n", TOS_NODE_ID, info_msg->position_x, info_msg->position_y, info_msg->status);

		// TOS_NODE_ID - 2 is the PARENT.
		call AMSend.send(TOS_NODE_ID - 2, &packet, sizeof(info_t));
	}

	//***************** MilliTimer interface ********************//
  event void Timer.fired() {
		/* 
		* This function is used call sendPAIRMessage function when the timer is fired.
		*/
		dbg("logger","MOTE [%d]: Timer fired.\n", TOS_NODE_ID);
		sendPAIRMessage(0);
  }

	//***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		/* This event is triggered when a message is received.
		*
		*/
		if (len != sizeof(info_t) && len != sizeof(pair_t)) return buf;
		
		// INFO_T STRUCTURE
		if(len == sizeof(info_t)){
			info_t* rsm_info = (info_t*)payload;
			dbg("logger","MOTED [%d]: Received msg type: INFO, with status: %d, position_x: %d, position_y: %d.\n", TOS_NODE_ID, rsm_info->status, rsm_info->position_x, rsm_info->position_y);
			// CHECK STATUS OF THE CHILD
		}

		// PAIR_T STRUCTURE
		if(len == sizeof(pair_t)){
			pair_t* rsm_pair = (pair_t*)payload;
			dbg("logger","MOTED [%d]: Received msg type: PAIR, with key: %s.\n", TOS_NODE_ID, rsm_pair->key);
			// CHECK KEYS TO END PAIR
		}
		return buf;
  }

	//************************* Read interface **********************//
	event void Read.readDone(error_t result, uint16_t data[3]) {
		/* 
		*	 This event is triggered when the fake status/coordinates sensor finishes to read (after a Read.read()) 
		*  The data is stored in data[3] -> [X,Y,STATUS]
		*/
		if(result != SUCCESS || isPaired == 0 || TOS_NODE_ID == 1 || TOS_NODE_ID == 2) return;

		sendINFOMessage(data);
	}
}
