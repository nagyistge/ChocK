declare name "Tibetan Bowl";
declare description "Banded Waveguide Modeld Tibetan Bowl";
declare author "Romain Michon";
declare copyright "Romain Michon (rmichon@ccrma.stanford.edu)";
declare version "1.0";
declare licence "STK-4.3"; // Synthesis Tool Kit 4.3 (MIT style license);
declare description "This instrument uses banded waveguide. For more information, see Essl, G. and Cook, P. Banded Waveguides: Towards Physical Modelling of Bar Percussion Instruments, Proceedings of the 1999 International Computer Music Conference.";

import("music.lib");
import("instrument.lib");

//==================== GUI SPECIFICATION ================

freq = nentry("freq",440,20,20000,1);
gain = nentry("gain",0.8,0,1,0.01); 
gate = button("gate");

select = nentry("Excitation_Selector",0,0,1,1);
integrationConstant = hslider("Integration_Constant",0,0,1,0.01);
baseGain = hslider("Base_Gain",1,0,1,0.01);
bowPressure = hslider("Bow_Pressure",0.2,0,1,0.01);
bowPosition = hslider("Bow_Position",0,0,1,0.01);

typeModulation = nentry("Modulation_Type",0,0,4,1);
nonLinearity = hslider("Nonlinearity",0,0,1,0.01);
frequencyMod = hslider("Modulation_Frequency",220,20,1000,0.1);
nonLinAttack = hslider("Nonlinearity_Attack",0.1,0,2,0.01);

//==================== MODAL PARAMETERS ================

preset = 0;

nMode(0) = 12;

modes(0,0) = 0.996108344;
basegains(0,0) = 0.999925960128219;
excitation(0,0) = 11.900357 / 10;
    
modes(0,1) = 1.0038916562;
basegains(0,1) = 0.999925960128219;
excitation(0,1) = 11.900357 / 10;

modes(0,2) = 2.979178;
basegains(0,2) = 0.999982774366897;
excitation(0,2) = 10.914886 / 10;

modes(0,3) = 2.99329767;
basegains(0,3) = 0.999982774366897;
excitation(0,3) = 10.914886 / 10;
    
modes(0,4) = 5.704452;
basegains(0,4) = 1.0;
excitation(0,4) = 42.995041 / 10;
    
modes(0,5) = 5.704452;
basegains(0,5) = 1.0;
excitation(0,5) = 42.995041 / 10;
    
modes(0,6) = 8.9982;
basegains(0,6) = 1.0;
excitation(0,6) = 40.063034 / 10;
    
modes(0,7) = 9.01549726;
basegains(0,7) = 1.0;
excitation(0,7) = 40.063034 / 10;
    
modes(0,8) = 12.83303;
basegains(0,8) = 0.999965497558225;
excitation(0,8) = 7.063034 / 10;
   
modes(0,9) = 12.807382;
basegains(0,9) = 0.999965497558225;
excitation(0,9) = 7.063034 / 10;
    
modes(0,10) = 17.2808219;
basegains(0,10) = 0.9999999999999999999965497558225;
excitation(0,10) = 57.063034 / 10;
    
modes(0,11) = 21.97602739726;
basegains(0,11) = 0.999999999999999965497558225;
excitation(0,11) = 57.063034 / 10;

//==================== SIGNAL PROCESSING ================

//----------------------- Nonlinear filter ----------------------------
//nonlinearities are created by the nonlinear passive allpass ladder filter declared in filter.lib

//nonlinear filter order
nlfOrder = 6; 

//nonLinearModultor is declared in instrument.lib, it adapts allpassnn from filter.lib 
//for using it with waveguide instruments
NLFM =  nonLinearModulator((nonLinearity : smooth(0.999)),1,freq,
typeModulation,(frequencyMod : smooth(0.999)),nlfOrder);

//----------------------- Synthesis parameters computing and functions declaration ----------------------------

//the number of modes depends on the preset being used
nModes = nMode(preset);

//bow table parameters
tableOffset = 0;
tableSlope = 10 - (9*bowPressure);

delayLengthBase = SR/freq;

//delay lengths in number of samples
delayLength(x) = delayLengthBase/modes(preset,x);

//delay lines
delayLine(x) = delay(4096,delayLength(x));

//Filter bank: bandpass filters (declared in instrument.lib)
radius = 1 - PI*32/SR;
bandPassFilter(x) = bandPass(freq*modes(preset,x),radius);

//Delay lines feedback for bow table lookup control
baseGainApp = 0.8999999999999999 + (0.1*baseGain);
velocityInputApp = integrationConstant;
velocityInput = velocityInputApp + _*baseGainApp,par(i,(nModes-1),(_*baseGainApp)) :> +;

//Bow velocity is controled by an ADSR envelope
maxVelocity = 0.03 + 0.1*gain;
bowVelocity = maxVelocity*adsr(0.02,0.005,90,0.01,gate);

//stereoizer is declared in instrument.lib and implement a stereo spacialisation in function of 
//the frequency period in number of samples 
stereo = stereoizer(delayLengthBase);

//----------------------- Algorithm implementation ----------------------------

//Bow table lookup (bow is decalred in instrument.lib)
bowing = bowVelocity - velocityInput <: *(bow(tableOffset,tableSlope)) : /(nModes);

//One resonance
resonance(x) = + : + (excitation(preset,x)*select) : delayLine(x) : *(basegains(preset,x)) : bandPassFilter(x);

process =
		//Bowed Excitation
		(bowing*((select-1)*-1) <:
		//nModes resonances with nModes feedbacks for bow table look-up 
		par(i,nModes,(resonance(i)~_)))~par(i,nModes,_) :> + : 
		//Signal Scaling and stereo
		NLFM : stereo : instrReverb;

