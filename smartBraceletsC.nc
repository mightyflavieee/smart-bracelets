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
	interface Timer<TMilli> as PairTimer;
	interface Timer<TMilli> as InfoTimer;
	interface Timer<TMilli> as MissingTimer;
	
	// Interface used to perform kinematic status and coordinates fake reading
	interface Read<uint16_t>;
	interface Random;

  }

} implementation {
	/*  
	*	ASSUMPTIONS:
	* MOTE 2 AND MOTE 4 are a PAIR, they share KEY1.
	*	MOTE 1 AND MOTE 3 are a PAIR, they share KEY2.
	*
	*	MOTE 1 AND MOTE 2 are PARENTS.
	*	MOTE 3 AND MOTE 4 are CHILDREN.
	*/

	uint8_t KEY1[21] = {'F','1','R','S','T','K','3','Y','F','1','R','S','T','K','3','Y','1','1','1','1','\0'};
	uint8_t KEY2[21] = {'S','3','C','0','N','D','K','3','Y','S','3','C','0','N','D','K','3','Y','2','2','\0'};
	uint16_t PAIR_ID = 0;
	uint16_t last_x_position = 0;
	uint16_t last_y_position = 0;
  message_t packet;
	
	void sendPAIRMessage(uint8_t isStopPairing); 
	void sendINFOMessage(uint16_t data);
	void startOperationMode();

	//***************** Boot interface ********************//
  event void Boot.booted() {
		dbg("logger","MOTE [%d]: Application booted.\n", TOS_NODE_ID);
		call SplitControl.start();
  }

	//***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
		/*
		*	If the split control is started successfully, then we can start the timer in order to send pairing messages.
		*	Otherwise, we can't start the timer.
		*/
    if(err == SUCCESS) {
			dbg("logger","MOTE [%d]: is starting the PairTimer...\n", TOS_NODE_ID);
			call PairTimer.startPeriodic(100);
    }
  }

	event void SplitControl.stopDone(error_t err){
		/* 
		* When the split control is stopped, we stop the timer.
		*/
		call PairTimer.stop();
		call InfoTimer.stop();
		call MissingTimer.stop();
  }

	//***************** MilliTimer interface ********************//
  event void PairTimer.fired() {
		/* 
		* This function is used to call sendPAIRMessage function when the timer is fired.
		*/
		dbg("logger","MOTE [%d]: PairTimer fired.\n", TOS_NODE_ID);
		sendPAIRMessage(0);
  }
  
  event void InfoTimer.fired() {
		/* 
		* This function is used to call the read on the FakeKinematicSensor.
		*/
		call Read.read();
  }

	event void MissingTimer.fired() {
		/* 
		* This function is used to alert the parent about missing.
		*/
		dbg("logger","MOTE [%d]: MissingTimer fired.\n", TOS_NODE_ID);
		dbg("alert","MOTE [%d]: MISSING ALERT, LAST KNOWN COORDINATES [%d,%d].\n", TOS_NODE_ID, last_x_position, last_y_position);
  }

	//***************** Send PAIR/STOP_PAIRING message function ********************//
	void sendPAIRMessage(uint8_t isStopPairing){
		/*
		*	This function is used to send PARING and STOP_PARING messages.
		*	If isStopPairing is equal to 1, then we send a STOP_PAIRING message.
		*	Otherwise, we send a PARING message.
		*
		*	If TOS_NODE_ID is even, then we use KEY1 as KEY.
		*	Otherwise, we use KEY2 as KEY.
		*/
		uint16_t address = 0;
		pair_t* pair_msg = (pair_t*) call Packet.getPayload(&packet, sizeof(pair_t));
		if (pair_msg == NULL) return;

		if(TOS_NODE_ID%2==0) {
			strcpy(pair_msg->key,KEY1);	
		}
		else {
			strcpy(pair_msg->key,KEY2);
		}
		
		if(isStopPairing == 1){
			pair_msg->type = STOP_PAIR;
			address = PAIR_ID;
			dbg("logger","MOTE [%d]: Sending PAIR message type: STOP_PAIR to MOTE %d\n", TOS_NODE_ID, address);
		}
		if(isStopPairing == 0){
			pair_msg->type = PAIR;
			address = AM_BROADCAST_ADDR;
			dbg("logger","MOTE [%d]: Sending PAIR message type: PAIR, with key: %s.\n", TOS_NODE_ID, pair_msg->key);
		}
		
		// Send the message in broadcast.
		call AMSend.send(address, &packet, sizeof(pair_t));
	}


	void sendINFOMessage(uint16_t data){
		/*
		*	This function is used to send INFO messages.
		*	data = status
		*/
		info_t* info_msg = (info_t*) call Packet.getPayload(&packet, sizeof(info_t));
		if (info_msg == NULL) return;
		
		info_msg->status = data;
		info_msg->position_x = call Random.rand16();
		info_msg->position_y = call Random.rand16();
		

		dbg("logger","MOTE [%d]: Sending msg type: INFO, with position: [%d,%d], status: %d.\n", TOS_NODE_ID, info_msg->position_x, info_msg->position_y, info_msg->status);

		// TOS_NODE_ID - 2 is the PARENT.
		call AMSend.send(PAIR_ID, &packet, sizeof(info_t));
	}
	
	void startOperationMode(){
		// If the mote is a children, start InfoTimer.
		if(TOS_NODE_ID == 3 || TOS_NODE_ID == 4){
			call InfoTimer.startPeriodic(10000); // Call the read on the sensor every 10s.
		}
		else{
			call MissingTimer.startOneShot(60000);
		}	
	}

	

	//***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
		/* This event is triggered when a message is received.
		*
		*/
		uint8_t keyMatches = 0;
		if (len != sizeof(info_t) && len != sizeof(pair_t)) {
			dbg("logger","MOTE [%d]: Reception error!\n", TOS_NODE_ID);
			return buf;
		}
		
		// INFO_T STRUCTURE - HANDLE THE INFO MESSAGE.
		if(len == sizeof(info_t)){
			info_t* rsm_info = (info_t*)payload;
			
			// INFO received stop MissingTimer.
		 	call MissingTimer.stop();
			dbg("logger","MOTE [%d]: Received msg type: INFO, with position: [%d,%d], status: %d.\n", TOS_NODE_ID, rsm_info->position_x, rsm_info->position_y, rsm_info->status);
			
			// Update last known position.
			last_x_position = rsm_info->position_x;
			last_y_position = rsm_info->position_y;
			
			if(rsm_info->status == FALLING){
				dbg("logger","MOTE [%d]: FALLING ALERT, POSITION[%d,%d].\n", TOS_NODE_ID, rsm_info->position_x, rsm_info->position_y);
				dbg("alert","MOTE [%d]: FALLING ALERT, COORDINATES [%d,%d].\n", TOS_NODE_ID, rsm_info->position_x, rsm_info->position_y);
			}
			// Restart MissingTimer.
			call MissingTimer.startOneShot(60000);
		}

		// PAIR_T STRUCTURE - HANDLE THE PAIR MESSAGE.
		if(len == sizeof(pair_t)){
			pair_t* rsm_pair = (pair_t*)payload;

			if(rsm_pair->type == PAIR){
				dbg("logger","MOTE [%d]: Received msg type: PAIR, with key: %s.\n", TOS_NODE_ID, rsm_pair->key);
				
				// TOS_NODE_ID is even, check KEY1 match.
				if(TOS_NODE_ID%2==0){
					if(strcmp(rsm_pair->key,KEY1)==0){
						dbg("logger","MOTE [%d]: KEY: %s MATCHES.\n", TOS_NODE_ID, KEY1);
						keyMatches = 1;
						// Update PAIR_ID.
						if(TOS_NODE_ID == 2) PAIR_ID = TOS_NODE_ID + 2;
						else PAIR_ID = TOS_NODE_ID - 2;
					}
				}
				// TOS_NODE_ID is odd, check KEY2 match.
				else{
					if(strcmp(rsm_pair->key,KEY2)==0){
						dbg("logger","MOTE [%d]: KEY: %s MATCHES.\n", TOS_NODE_ID, KEY2);
						keyMatches = 1;
						// Update PAIR_ID.
						if(TOS_NODE_ID == 1) PAIR_ID = TOS_NODE_ID + 2;
						else PAIR_ID = TOS_NODE_ID - 2;
					}
				}
				
				if(keyMatches == 1){
					call PairTimer.stop();
					dbg("logger","MOTE [%d]: PairTimer stopped!\n", TOS_NODE_ID);
					sendPAIRMessage(1);
					startOperationMode();
				}
			}
			if(rsm_pair->type == STOP_PAIR){
				dbg("logger","MOTE [%d]: Received msg type: STOP_PAIR.\n", TOS_NODE_ID);
				call PairTimer.stop();
				startOperationMode();
			}
		}
		return buf;
  }

	//********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
		/* This event is triggered when a message is sent.
		*/
		if(&packet != buf || err != SUCCESS) {
			dbg("logger","MOTE [%d]: Message not sent, sendDone error!.\n", TOS_NODE_ID);
		}
  }

	//************************* Read interface **********************//
	event void Read.readDone(error_t result, uint16_t data) {
		/* 
		*	 This event is triggered when the fake status/coordinates sensor finishes to read (after a Read.read()) 
		*  The data is stored in data -> STATUS
		*/
		// If the read is successful then we can send the INFO message.
		if(result != SUCCESS) return;

		sendINFOMessage(data);
	}
}

