#include "smartBracelets.h"

configuration smartBraceletsAppC {}

implementation {

  /****** COMPONENTS *****/
  components MainC, smartBraceletsC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC() as PairTimer;
  components new TimerMilliC() as MissingTimer;
  components new FakeKineticSensorC();
  components ActiveMessageC;

  /****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Other interfaces *****/
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.SplitControl -> ActiveMessageC;
  App.PairTimer -> PairTimer;
  App.MissingTimer -> MissingTimer;
  App.Packet -> AMSenderC;
  
  // Fake KineticStatus Sensor read
  App.Read -> FakeKineticSensorC;
}
