generic configuration FakeKineticSensorC() {

	provides interface Read<uint16_t>;

} implementation {

	components MainC, RandomC;
	components new FakeKineticSensorP();
	components new TimerMilliC();
	
	// Connects the provided interface
	Read = FakeKineticSensorP;
	
	// Random interface and its initialization	
	FakeKineticSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	// Timer interface	
	FakeKineticSensorP.Timer -> TimerMilliC;

}
