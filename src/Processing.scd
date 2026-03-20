/*
	---- ---- ---- ---- Accrete 'Processing' ---- ---- ---- ----
	Filter effects — each returns a processing function {|in| ... }
	Applied via Ndef filtering or chaining.
*/

(

var p = ();

p[\verb] = {|in, room = 10, damp = 0.5, mix = 0.3|
	var verb = FreeVerb2.ar(in[0], in.last, mix, room / 100, damp);
	XFade2.ar(in, verb, mix * 2 - 1)
};

p[\fold] = {|in, foldFreq = 20, amount = 0.5|
	var folded = in.fold2(SinOsc.ar(foldFreq) * amount);
	HPF.ar(folded, 40)
};

p[\delay] = {|in, delayTime = 0.3, feedback = 0.5, maxDelay = 2|
	var sig = in + LocalIn.ar(2);
	var delayed = DelayC.ar(sig, maxDelay, delayTime);
	LocalOut.ar(delayed * feedback);
	(in + delayed) * 0.5
};

p[\filter] = {|in, cutoff = 2000, res = 0.5, type = 0|
	// type: 0 = lowpass, 1 = highpass, 2 = bandpass
	Select.ar(type, [
		RLPF.ar(in, cutoff, res),
		RHPF.ar(in, cutoff, res),
		BPF.ar(in, cutoff, res)
	])
};

p[\shift] = {|in, shiftFreq = 100, mod = 0.1|
	FreqShift.ar(in, LFNoise1.kr(mod).range(shiftFreq * 0.5, shiftFreq))
};

p[\crush] = {|in, bits = 8, rate = 10000|
	var crushed = Latch.ar(in, Impulse.ar(rate));
	crushed.round(2.pow(bits.neg))
};

p

)
