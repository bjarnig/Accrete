/*
	---- ---- ---- ---- Accrete 'Behaviours' ---- ---- ---- ----
	Synthesis behaviours — each is a UGen function suitable for Ndef.
	Sources adapted from becoming.scd (desktop); refactored for clarity, same signal flow.
*/

(

var b = ();

b[\invdem] = {|wfmult = 0.2, seqmult = 10, amp = 0.5|
	var sd = SampleDur.ir * wfmult;
	DemandEnvGen.ar(
		Dseq([-0.1, 0.1], inf),
		Dseq([sd * seqmult, sd * 8 * seqmult, sd * Dwhite(seqmult * 6, seqmult * 9, inf)], inf)
	) * amp
};

b[\vpay] = {|freq = 10, fmod = 10, ffrom = 20, fto = 2250, index = 0.8, amp = 0.2|
	Splay.ar(PMOsc.ar(freq, Lag.ar(LFDClipNoise.ar(fmod).range(ffrom, fto), 0.001),
		Array.rand(4, index, index * 5), 0, Array.rand(4, 0.1, 1.0)) * amp)
};

b[\pulse] = {|freq = 5, fmod = 400, ffrom = 20, fto = 50, index = 0.9, amp = 0.3|
	var mod = Lag.ar(LFDClipNoise.ar(fmod).range(ffrom, fto), 0.001);
	var indexPair = Array.rand(2, index, index * 5);
	var levelPair = Array.rand(2, 0.1, 8.0);
	var sig = PMOsc.ar(freq, mod, indexPair, 0, levelPair);
	sig * (amp * (0.04 / 0.3))
};

b[\shimmer] = {|drive = 20, modLo = 50, modHi = 100, lpfFreq = 2000, amp = 0.1|
	var mod = PMOsc.ar(drive, LFDClipNoise.ar(200).range(modLo, modHi), 1);
	var grid = GravityGrid.ar(0, [12, 30]);
	var shaped = LeastChange.ar(grid, mod);
	LPF.ar(shaped, lpfFreq) * 0.1 * (amp / 0.1)
};

b[\rumble] = {|rate = 12, trigMin = 400, trigMax = 1000, freq = 30, amp = 0.4|
	var trigKr = Impulse.kr(rate);
	var trigMs = Demand.kr(trigKr, 0, Diwhite(trigMin, trigMax, inf));
	var grid = GravityGrid.ar(0, [freq / 2, freq / 16]);
	var src = Saw.ar(freq);
	var diff = LeastChange.ar(grid, src);
	var band = BBandStop.ar(diff, Lag.kr(trigMs), 10);
	var out = HPF.ar(band, 40);
	out * (amp * (0.15 / 0.4))
};

b[\breath] = {|sdm = 1, repeats = 2, from = 1, to = 20, mod = 40, mf = 0.3, amp = 0.6|
	var sd = SampleDur.ir * sdm;
	var demandEnv = DemandEnvGen.ar(
		Dseq([Dseries(-1.0, Array.rand(2, 0.01, 0.1), 30)], inf),
		Dseq([
			Dwhite(from, to, repeats),
			Dwhite(from / 1.5, to * 3, repeats)
		], inf) * sd
	);
	var carrier = SinOsc.ar(Array.rand(2, mod, mod * 0.9));
	HPF.ar(demandEnv.clip(carrier) * mf * amp, 50)
};

b[\bell] = {|rate = 12, bfmin = 400, bfmax = 1000, bw = 12, freq = 10, hpf = 40, amp = 0.8|
	var gridFreqs = Array.fill(2, { freq * rrand(1.25, 10.2) });
	var grid = GravityGrid.ar(0, gridFreqs);
	var lo = LoFM.ar(freq);
	var diff = LeastChange.ar(grid, lo);
	var sweep = LFNoise1.kr(0.1).range(bfmin, bfmax);
	var band = BBandStop.ar(diff, sweep, bw);
	var body = HPF.ar(band, hpf);
	BPeakEQ.ar(body, 100, 2, -4) * amp
};

b[\crackle] = {|dustRate = 120, crackle = 0.9, timeUp = 6, timeDown = 8, amp = 0.3|
	var raw = Dust.ar(dustRate) + Crackle.ar(crackle);
	var holder = EnvGen.ar(Env([0.8, 1, 0.8], [timeUp, timeDown]).circle);
	var sinFrom = EnvGen.ar(Env([0, 1, 0], [timeUp * 2, timeDown / 2]).circle);
	var mod = LFNoise2.ar([4, 8]).range(sinFrom, 1.0);
	raw * mod * holder * amp
};

b[\specs] = (
	invdem: (
		wfmult: ControlSpec(0.01, 2, \exp, 0, 0.2),
		seqmult: ControlSpec(1, 50, \exp, 0, 10),
		amp: ControlSpec(0, 1, \lin, 0, 0.5)
	),
	vpay: (
		freq: ControlSpec(1, 80, \exp, 0, 10),
		fmod: ControlSpec(1, 200, \exp, 0, 10),
		ffrom: ControlSpec(10, 2000, \exp, 0, 20),
		fto: ControlSpec(100, 8000, \exp, 0, 2250),
		index: ControlSpec(0.1, 4, \exp, 0, 0.8),
		amp: ControlSpec(0, 1, \lin, 0, 0.2)
	),
	pulse: (
		freq: ControlSpec(1, 80, \exp, 0, 5),
		fmod: ControlSpec(50, 2000, \exp, 0, 400),
		ffrom: ControlSpec(1, 200, \exp, 0, 20),
		fto: ControlSpec(10, 2000, \exp, 0, 50),
		index: ControlSpec(0.1, 2, \lin, 0, 0.9),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	),
	shimmer: (
		drive: ControlSpec(5, 80, \exp, 0, 20),
		modLo: ControlSpec(20, 200, \exp, 0, 50),
		modHi: ControlSpec(50, 500, \exp, 0, 100),
		lpfFreq: ControlSpec(500, 8000, \exp, 0, 2000),
		amp: ControlSpec(0, 0.5, \lin, 0, 0.1)
	),
	rumble: (
		rate: ControlSpec(2, 40, \exp, 0, 12),
		trigMin: ControlSpec(50, 2000, \exp, 0, 400),
		trigMax: ControlSpec(100, 4000, \exp, 0, 1000),
		freq: ControlSpec(5, 200, \exp, 0, 30),
		amp: ControlSpec(0, 1, \lin, 0, 0.4)
	),
	breath: (
		sdm: ControlSpec(0.5, 4, \exp, 0, 1),
		repeats: ControlSpec(1, 16, \lin, 1, 2),
		from: ControlSpec(1, 40, \lin, 1, 1),
		to: ControlSpec(2, 80, \lin, 1, 20),
		mod: ControlSpec(10, 2000, \exp, 0, 40),
		mf: ControlSpec(0.05, 1, \exp, 0, 0.3),
		amp: ControlSpec(0, 1, \lin, 0, 0.6)
	),
	bell: (
		rate: ControlSpec(2, 40, \exp, 0, 12),
		bfmin: ControlSpec(100, 4000, \exp, 0, 400),
		bfmax: ControlSpec(200, 8000, \exp, 0, 1000),
		bw: ControlSpec(1, 40, \exp, 0, 12),
		freq: ControlSpec(2, 80, \exp, 0, 10),
		hpf: ControlSpec(20, 200, \exp, 0, 40),
		amp: ControlSpec(0, 1, \lin, 0, 0.8)
	),
	crackle: (
		dustRate: ControlSpec(20, 400, \exp, 0, 120),
		crackle: ControlSpec(0.5, 1.95, \lin, 0, 0.9),
		timeUp: ControlSpec(1, 30, \lin, 0, 6),
		timeDown: ControlSpec(1, 30, \lin, 0, 8),
		amp: ControlSpec(0, 1, \lin, 0, 0.3)
	)
);

b

)
