/*
	---- ---- ---- ---- Accrete 'AverseBehaviours' ---- ---- ---- ----

	Buffer-playback behaviours derived from Averse.States.24.
	Each is a Pbind that works as an Ndef source inside AcNode.

	Requirements:
	  - Server booted
	  - ~hpb buffer dictionary loaded (see loadBuffers below)

	Usage:
	  ~hpb = AverseBehaviours.loadBuffers(server, path);
	  ... or load manually, then:
	  a = Accrete(thisProcess.interpreter);
	  a.averse[\r01]  // a Pbind behaviour
*/

(

var b = ();

// ---- SynthDef for buffer playback ----

SynthDef(\acBuf, {|out = 0, buf = 0, rate = 1, amp = 0.5, atk = 0.01, dec = 0.1, rel = 0.3, pan = 0|
	var sig = PlayBuf.ar(1, buf, BufRateScale.kr(buf) * rate, doneAction: 2);
	var env = EnvGen.ar(Env.perc(atk, rel), doneAction: 2);
	Out.ar(out, Pan2.ar(sig * env * amp, pan));
}).add;

// ---- buffer loader convenience ----

b[\loadBuffers] = {|ev, server, path|
	var hpb = Dictionary();
	"abcdefghijk".do {|letter|
		var folder = path ++ "/hp" ++ letter ++ "/*";
		var files = SoundFile.collect(folder);
		if(files.notNil and: { files.notEmpty }) {
			hpb[letter.asString] = files.collect {|sf|
				Buffer.readChannel(server, sf.path, channels: 0)
			};
		};
	};
	~hpb = hpb;
	"AverseBehaviours: loaded % buffer sets from %".format(hpb.size, path).postln;
	hpb
};

// ---- PART 01 behaviours ----

// R01: seg-sweep through c+d, beta amplitude cascade
b[\r01] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq(~hpb["c"] ++ ~hpb["d"], inf),
	\dur, Pseq([
		Pseg(Pwhite(0.1, 0.2), Pseq([1, 5]), \linear),
		Pseg(Pwhite(0.2, 0.05), Pseq([5, 1]), \linear)
	], inf),
	\amp, Pseq([0.1, 0.2, 0.3, 0.4,
		Pstutter(2, Pbeta(0.2, 1, 1, 1, 6)),
		Pstutter(4, Pbeta(0.6, 1, 1, 1, 18)),
		Pseq([0], 4)], inf) * 1.5
);

// R02: brownian drift through shuffled c+d
b[\r02] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq((~hpb["c"] ++ ~hpb["d"]).scramble, inf),
	\dur, Pbrown(0.05, 0.15, 0.01),
	\amp, Pseq([0.1, 0.2, 0.3, 0.4,
		Pstutter(2, Pbeta(0.2, 1, 1, 1, 6)),
		Pstutter(4, Pbeta(0.6, 1, 1, 1, 18)),
		Pseq([0], 4)], inf) * 1.5
);

// R03: triple-section brownian, b+c
b[\r03] = Pbind(
	\instrument, \acBuf,
	\buf, Plazy { Pseq(~hpb["b"] ++ ~hpb["c"].scramble, inf) },
	\dur, Pseq([
		Pbrown(0.02, 0.04, 0.001, 16),
		Pbrown(0.01, 0.1, 0.05, 32),
		Pbrown(0.1, 0.4, 0.05, 16)
	] * rrand(0.8, 1.2), inf),
	\amp, 0.8
);

// R04: stutter-scramble across b+d+c, stretched durations
b[\r04] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq([Plazy {
		Pstutter(Pseq([1, 2, 3], 1),
			Pseq((~hpb["b"] ++ ~hpb["d"] ++ ~hpb["c"]).scramble, inf))
	}], inf),
	\dur, Pseq([
		Pbrown(0.02, 0.08, 0.001, 16),
		Pbrown(0.01, 0.4, 0.05, 32),
		Pbrown(0.1, 0.3, 0.05, 16)
	] * 10, inf),
	\amp, 0.8
);

// ---- PART 02 behaviours ----

// S05: c scrambled, gapped amplitude
b[\s05] = Pbind(
	\instrument, \acBuf,
	\buf, Plazy { Pseq(~hpb["c"].scramble, inf) },
	\dur, Pseq([
		Pbrown(0.04, 0.08, 0.001, 16),
		Pbrown(0.01, 0.02, 0.05, 32),
		Pbrown(0.2, 1.4, 0.05, 4)
	], inf),
	\amp, Pseq([0.8, 0.7, 0.6, 0.0, 0.0] * 1.5, inf)
);

// S06: b+c brownian dense
b[\s06] = Pbind(
	\instrument, \acBuf,
	\buf, Plazy { Pseq(~hpb["b"] ++ ~hpb["c"].scramble, inf) },
	\dur, Pseq([
		Pbrown(0.02, 0.04, 0.001, 16),
		Pbrown(0.01, 0.1, 0.05, 32),
		Pbrown(0.1, 0.4, 0.05, 16)
	], inf),
	\amp, 0.8
);

// S07: b+c with randomized time scaling
b[\s07] = Pbind(
	\instrument, \acBuf,
	\buf, Plazy { Pseq(~hpb["b"] ++ ~hpb["c"].scramble, inf) },
	\dur, Pseq([
		Pbrown(0.02, 0.04, 0.001, 16),
		Pbrown(0.01, 0.1, 0.05, 32),
		Pbrown(0.1, 0.4, 0.05, 16)
	] * rrand(0.8, 1.2), inf),
	\amp, 0.8
);

// S08: shuffled micro-timing
b[\s08] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq((~hpb["b"] ++ ~hpb["c"]).scramble, inf),
	\dur, Pseq([
		Plazy { Pshuf(Pwhite(0.04, 0.8).round(0.02).asStream.nextN(3), 8) },
		Plazy { Pshuf(Pwhite(0.04, 1.2).round(0.04).asStream.nextN(5), 4) },
		Plazy { Pshuf(Pwhite(0.01, 0.9).round(0.01).asStream.nextN(5), 4) },
		Plazy { Pshuf(Pwhite(0.1, 0.2).round(0.01).asStream.nextN(5), 2) }
	], inf),
	\amp, 1
);

// ---- PART 03 behaviours ----

// T09: tight shuffled micro-timing
b[\t09] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq((~hpb["b"] ++ ~hpb["c"]).scramble, inf),
	\dur, Pseq([
		Plazy { Pshuf(Pwhite(0.04, 0.08).round(0.02).asStream.nextN(3), 8) },
		Plazy { Pshuf(Pwhite(0.04, 0.12).round(0.04).asStream.nextN(5), 4) },
		Plazy { Pshuf(Pwhite(0.01, 0.09).round(0.01).asStream.nextN(5), 4) },
		Plazy { Pshuf(Pwhite(0.1, 0.2).round(0.01).asStream.nextN(5), 2) }
	], inf),
	\amp, 0.8
);

// T10: seg-sweep c+d with release
b[\t10] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq((~hpb["c"] ++ ~hpb["d"]).scramble, inf),
	\dur, Pseq([
		Pseg(Pwhite(0.1, 0.2), Pseq([1, 5]), \linear),
		Pseg(Pwhite(0.2, 0.05), Pseq([5, 1]), \linear)
	], inf),
	\rel, 0.01,
	\amp, Pseq([0.1, 0.2, 0.3, 0.4,
		Pstutter(2, Pbeta(0.2, 1, 1, 1, 6)),
		Pstutter(4, Pbeta(0.6, 1, 1, 1, 18)),
		Pseq([0], 4)], inf) * 1.5
);

// T11: finite state machine rhythms, b only
b[\t11] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq(~hpb["b"], inf),
	\dec, 0.2,
	\dur, Pseq([
		Pfsm([[0], 0.1, [0, 1], 0.06, [2, 3], 0.14, [0, 2], 0.08, [0]], 4),
		Pwhite(0.1, 0.4, 4)
	], inf),
	\amp, Prand([0.1, 1, 0.2, 1, 1, 0.1], inf) * 2
);

// T12: euclidean rhythms, h set
b[\t12] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq(~hpb["h"].scramble, inf),
	\dur, (Pbjorklund2(Pseq([5, 4, 7, 2], inf), 14, inf) / rrand(12, 20)),
	\amp, Pseq([Pseq([0.4, 1.0], 17), Pseq([0.0, 0.0], 9), 1], inf) * 1.2
);

// ---- PART 04 behaviours ----

// Q01: rapid-fire stutter, fixed duration
b[\q01] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq([Plazy {
		Pstutter(Pseq([1, 2, 3], 1),
			Pseq((~hpb["b"] ++ ~hpb["d"] ++ ~hpb["c"]).scramble, inf))
	}], inf),
	\dur, 0.07,
	\amp, 0.8
);

// Q02: d-set random, mixed rhythm
b[\q02] = Pbind(
	\instrument, \acBuf,
	\buf, Pxrand(~hpb["d"], inf),
	\dur, Pseq([
		Plazy { Pshuf(Pwhite(0.1, 0.2).round(0.05).asStream.nextN(3), 4) },
		Pseq([0.1, 0.5], 4),
		Pseq([0.1, 0.2], 4)
	], inf),
	\rate, 1.5,
	\dec, 0.8, \rel, 0.01,
	\amp, 0.8
);

// Q03: envelope-driven duration sweep
b[\q03] = Pbind(
	\instrument, \acBuf,
	\buf, Pseq((~hpb["b"] ++ ~hpb["c"]).scramble, inf),
	\dur, Pseq([
		Penv([0.01, 0.2, 0.01, 0.8, 0.01], [2, 3, 4, 5])
	], inf),
	\amp, 0.9
);

// Q04: indexed c-set, stutter-brown
b[\q04] = Pbind(
	\instrument, \acBuf,
	\buf, Pindex(~hpb["c"], Pseq([1, 2, 1, 0, 2, 1], inf)),
	\dur, Pstutter(Pseq([1, 4, 8].scramble, inf), Pbrown(0.02, 0.2, 0.04)),
	\amp, Pseq([0.0, 0.4, 1.0, 1, 0.8].scramble, inf)
);

// ---- single-buffer variants (from PART 02 section 2) ----

// R01b: single buffer c[1], seg sweep
b[\r01b] = Pbind(
	\instrument, \acBuf,
	\buf, ~hpb["c"][1],
	\dur, Pseq([
		Pseg(Pwhite(0.1, 0.2), Pseq([1, 5]), \linear),
		Pseg(Pwhite(0.2, 0.05), Pseq([5, 1]), \linear)
	], inf),
	\amp, Pseq([0.1, 0.2, 0.3, 0.4,
		Pstutter(2, Pbeta(0.2, 1, 1, 1, 6)),
		Pstutter(4, Pbeta(0.6, 1, 1, 1, 18)),
		Pseq([0], 4)], inf) * 1.5
);

// R02b: single buffer c[2], brown drift
b[\r02b] = Pbind(
	\instrument, \acBuf,
	\buf, ~hpb["c"][2],
	\dur, Pbrown(0.15, 0.5, 0.01),
	\amp, Pseq([0.1, 0.2, 0.3, 0.4,
		Pstutter(2, Pbeta(0.2, 1, 1, 1, 6)),
		Pstutter(4, Pbeta(0.6, 1, 1, 1, 18)),
		Pseq([0], 4)], inf) * 1.5
);

// R03b: single buffer c[8], triple brownian
b[\r03b] = Pbind(
	\instrument, \acBuf,
	\buf, ~hpb["c"][8],
	\dur, Pseq([
		Pbrown(0.02, 0.04, 0.001, 16),
		Pbrown(0.01, 0.1, 0.05, 32),
		Pbrown(0.1, 0.4, 0.05, 16)
	] * rrand(0.8, 1.2), inf),
	\amp, 0.8
);

// ---- legacy behaviours ----

// L19: indexed c, envelope-driven, amp follows duration
b[\l19] = Pbind(
	\instrument, \acBuf,
	\buf, Pindex(~hpb["c"].scramble, Pseq([1, 2, 1, 0, 2, 1], inf)),
	\dur, Pn(Penv([0.1, 0.02, 0.2, 0.01, 0.4, 0.1], [6, 3, 4, 5], 6)),
	\amp, Pfunc {|ev| ev.dur.linlin(0.002, 0.2, 0.3, 1.0) } * 1.8
);

// behaviour names (exclude helpers)
b[\names] = {
	b.keys.asArray.reject {|k| [\loadBuffers, \names].includesEqual(k) }.sort
};

b

)
