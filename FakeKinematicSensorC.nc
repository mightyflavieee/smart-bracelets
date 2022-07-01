generic configuration FakeKinematicSensorC() {

	provides interface Read<uint16_t>;

} implementation {

	components MainC, RandomC;
	components new FakeKinematicSensorP();
	components new TimerMilliC();
	
	// Connects the provided interface
	Read = FakeKinematicSensorP;
	
	// Random interface and its initialization	
	FakeKinematicSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	// Timer interface	
	FakeKinematicSensorP.Timer -> TimerMilliC;

}
