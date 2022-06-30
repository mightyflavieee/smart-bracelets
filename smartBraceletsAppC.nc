#include "smartBracelets.h"

configuration smartBraceletsAppC {}

implementation {

  /****** COMPONENTS *****/
  components MainC, smartBraceletsC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC();
  components new FakeKineticSensorC();
  components ActiveMessageC;

  /****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Other interfaces *****/
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements -> AMSenderC;
  
  // Fake KineticStatus/Coordinates Sensor read
  App.Read -> FakeInfoSensorC;
}
