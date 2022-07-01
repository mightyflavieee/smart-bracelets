#include "smartBracelets.h"

configuration smartBraceletsAppC {}

implementation {

  /****** COMPONENTS *****/
  components MainC, smartBraceletsC as App, RandomC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components new TimerMilliC() as PairTimer;
  components new TimerMilliC() as InfoTimer;
  components new TimerMilliC() as MissingTimer;
  components new FakeKinematicSensorC();
  components ActiveMessageC;

  /****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Other interfaces *****/
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.SplitControl -> ActiveMessageC;
  App.PairTimer -> PairTimer;
  App.InfoTimer -> InfoTimer;
  App.MissingTimer -> MissingTimer;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
  
  // Fake KineticStatus Sensor read
  App.Read -> FakeKinematicSensorC;
}
