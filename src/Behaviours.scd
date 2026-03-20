/*
	---- ---- ---- ---- Accrete 'Behaviours' ---- ---- ---- ----
	Synthesis behaviours — each is a UGen function suitable for Ndef.
	Returned as an Event dictionary.
*/

(

var b = ();

b[\drone] = {|freq = 60, drift = 0.1, amp = 0.3|
	var sig = Mix.fill(5, {|i|
		var f = freq * (i + 1) * LFNoise1.kr(drift * (i + 1)).range(0.99, 1.01);
		SinOsc.ar(f, 0, 1 / (i + 1))
	});
	sig = sig + LPF.ar(PinkNoise.ar(0.01), freq * 2);
	Splay.ar(sig, 0.5) * amp
};

b[\grain] = {|density = 12, freq = 800, spread = 400, dur = 0.05, amp = 0.3|
	var trig = Dust.ar(density);
	var grainFreq = TRand.ar(freq - spread, freq + spread, trig);
	var sig = GrainSin.ar(2, trig, dur, grainFreq);
	sig * amp
};

b[\pulse] = {|rate = 4, freq = 200, width = 0.5, decay = 0.3, amp = 0.3|
	var trig = Impulse.ar(rate);
	var env = EnvGen.ar(Env.perc(0.001, decay), trig);
	var sig = Pulse.ar(freq, width) * env;
	Pan2.ar(sig, LFNoise1.kr(0.5)) * amp
};

b[\shimmer] = {|freq = 3000, mod = 0.1, feedback = 0.6, amp = 0.2|
	var sig = SinOsc.ar(freq * LFNoise2.kr(mod).range(0.98, 1.02));
	var verb = sig + LocalIn.ar(2).mean;
	8.do { verb = AllpassL.ar(verb, 0.1, { rrand(0.01, 0.08) } ! 2, 3) };
	LocalOut.ar(verb * feedback);
	Splay.ar(verb, 0.8) * amp
};

b[\rumble] = {|freq = 30, chaos = 1.5, amp = 0.4|
	var sig = LFNoise2.ar(freq) + Crackle.ar(chaos, 0.3);
	sig = LPF.ar(sig, freq * 3);
	sig = Pan2.ar(sig, LFNoise1.kr(0.2));
	sig * amp
};

b[\breath] = {|freq = 400, bw = 200, rate = 0.15, amp = 0.3|
	var env = LFNoise2.kr(rate).range(0.0, 1.0);
	var sig = BPF.ar(WhiteNoise.ar, freq, bw / freq) * env;
	Pan2.ar(sig, LFNoise1.kr(0.3)) * amp * 4
};

b[\bell] = {|freq = 800, decay = 4, amp = 0.2|
	var trig = Dust.kr(0.5);
	// fixed 6 partials — Mix.fill needs a literal integer, not a UGen
	var sig = Mix.fill(6, {|i|
		var detune = Array.fill(6, { rrand(0.99, 1.01) })[i];
		var decayScale = Array.fill(6, { rrand(0.5, 1.5) })[i];
		var partial = freq * (i + 1) * detune;
		var env = EnvGen.ar(Env.perc(0.001, decay * decayScale), trig);
		SinOsc.ar(partial) * env * (1 / (i + 1))
	});
	Pan2.ar(sig, TRand.kr(-0.8, 0.8, trig)) * amp
};

b[\crackle] = {|chaos = 1.8, density = 20, hpf = 1000, amp = 0.3|
	var sig = Crackle.ar(chaos) * Dust.ar(density);
	sig = HPF.ar(sig, hpf);
	Pan2.ar(sig, LFNoise0.kr(3)) * amp
};

// specs sub-dictionary with ControlSpec for each behaviour's params
b[\specs] = (
	drone: (
		freq: ControlSpec(20, 500, \exp, 0, 60),
		drift: ControlSpec(0.01, 2, \exp, 0, 0.1),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	),
	grain: (
		density: ControlSpec(1, 100, \exp, 0, 12),
		freq: ControlSpec(100, 10000, \exp, 0, 800),
		spread: ControlSpec(0, 2000, \lin, 0, 400),
		dur: ControlSpec(0.005, 0.5, \exp, 0, 0.05),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	),
	pulse: (
		rate: ControlSpec(0.5, 50, \exp, 0, 4),
		freq: ControlSpec(20, 5000, \exp, 0, 200),
		width: ControlSpec(0.01, 0.99, \lin, 0, 0.5),
		decay: ControlSpec(0.01, 2, \exp, 0, 0.3),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	),
	shimmer: (
		freq: ControlSpec(500, 10000, \exp, 0, 3000),
		mod: ControlSpec(0.01, 5, \exp, 0, 0.1),
		feedback: ControlSpec(0, 0.95, \lin, 0, 0.6),
		amp: ControlSpec(0, 1, \lin, 0, 0.2)
	),
	rumble: (
		freq: ControlSpec(10, 100, \exp, 0, 30),
		chaos: ControlSpec(1.0, 2.0, \lin, 0, 1.5),
		amp: ControlSpec(0, 1, \lin, 0, 0.4)
	),
	breath: (
		freq: ControlSpec(100, 5000, \exp, 0, 400),
		bw: ControlSpec(10, 2000, \lin, 0, 200),
		rate: ControlSpec(0.01, 2, \exp, 0, 0.15),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	),
	bell: (
		freq: ControlSpec(100, 5000, \exp, 0, 800),
		decay: ControlSpec(0.5, 20, \exp, 0, 4),
		amp: ControlSpec(0, 1, \lin, 0, 0.2)
	),
	crackle: (
		chaos: ControlSpec(1.0, 2.0, \lin, 0, 1.8),
		density: ControlSpec(1, 100, \exp, 0, 20),
		hpf: ControlSpec(100, 10000, \exp, 0, 1000),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	)
);

b

)
