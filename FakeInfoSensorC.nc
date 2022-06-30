generic configuration FakeInfoSensorC() {

	provides interface Read<uint16_t>;

} implementation {

	components MainC, RandomC;
	components new FakeInfoSensorP();
	components new TimerMilliC();
	
	// Connects the provided interface
	Read = FakeInfoSensorP;
	
	// Random interface and its initialization	
	FakeInfoSensorP.Random -> RandomC;
	RandomC <- MainC.SoftwareInit;
	
	// Timer interface	
	FakeInfoSensorP.Timer0 -> TimerMilliC;

}
