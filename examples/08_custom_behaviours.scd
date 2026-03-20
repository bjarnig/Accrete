/*
	Custom Behaviours — build a network entirely from your own synths.
	No presets needed. Any {|args| UGen } function works as a behaviour.
	Combine with processing chain and growth.
*/

(
s.waitForBoot {

	var g, fm, saw, noise, pluck, feedback, formant, dust, gendy;

	g = AcGraph(2, 0);
	g.initRouting(\master);

	// ---- define behaviours inline ----

	fm = {|carrier = 200, ratio = 1.5, index = 3, amp = 0.2|
		var mod = carrier * ratio;
		var sig = PMOsc.ar(carrier, mod, index * LFNoise2.kr(0.1).range(0.5, 1.5));
		Pan2.ar(sig, LFNoise1.kr(0.3)) * amp
	};

	saw = {|freq = 150, cut = 1200, res = 0.3, amp = 0.25|
		var sig = RLPF.ar(Saw.ar([freq, freq * 1.005]), cut, res);
		sig * amp
	};

	noise = {|bpFreq = 800, bw = 0.5, rate = 0.2, amp = 0.2|
		var env = LFNoise2.kr(rate).range(0.0, 1.0);
		var sig = BPF.ar(PinkNoise.ar, bpFreq, bw) * env;
		Pan2.ar(sig, LFNoise1.kr(0.4)) * amp * 6
	};

	pluck = {|freq = 300, decay = 1, coef = 0.1, amp = 0.25|
		var trig = Dust.kr(2);
		var sig = Pluck.ar(WhiteNoise.ar(0.5), trig, 1/60, 1/freq, decay, coef);
		Pan2.ar(sig, TRand.kr(-0.7, 0.7, trig)) * amp
	};

	feedback = {|freq = 100, fbAmt = 0.7, delay = 0.05, amp = 0.15|
		var sig = SinOsc.ar(freq) + LocalIn.ar(1);
		sig = DelayC.ar(sig, 0.2, delay);
		sig = (sig * fbAmt).tanh;
		LocalOut.ar(sig);
		Pan2.ar(sig, SinOsc.kr(0.2)) * amp
	};

	formant = {|fund = 80, formFreq = 600, bw = 80, amp = 0.2|
		var sig = Formant.ar(fund, formFreq, bw);
		Pan2.ar(sig, LFNoise1.kr(0.15)) * amp
	};

	dust = {|density = 40, hpf = 2000, ringTime = 0.05, amp = 0.2|
		var sig = Ringz.ar(Dust2.ar(density ! 2), hpf, ringTime);
		sig * amp
	};

	gendy = {|minFreq = 200, maxFreq = 1000, amp = 0.15|
		var sig = Gendy1.ar(minfreq: minFreq, maxfreq: maxFreq);
		Pan2.ar(sig, LFNoise0.kr(2)) * amp
	};

	// ---- build the graph ----

	g.addNode(\fm1,   fm,       (carrier: 180, ratio: 2.01, index: 4, amp: 0.15));
	g.addNode(\fm2,   fm,       (carrier: 90,  ratio: 3.0, index: 2, amp: 0.12));
	g.addNode(\saw1,  saw,      (freq: 110, cut: 800, amp: 0.15));
	g.addNode(\noise, noise,    (bpFreq: 1200, bw: 0.3, rate: 0.15, amp: 0.15));
	g.addNode(\pluck, pluck,    (freq: 220, decay: 2, amp: 0.2));
	g.addNode(\fb,    feedback, (freq: 75, fbAmt: 0.6, delay: 0.03, amp: 0.1));
	g.addNode(\form,  formant,  (fund: 65, formFreq: 400, bw: 60, amp: 0.15));
	g.addNode(\dust1, dust,     (density: 30, hpf: 3000, amp: 0.12));
	g.addNode(\gen,   gendy,    (minFreq: 100, maxFreq: 600, amp: 0.08));

	// connect: fm core with satellites
	g.connect(\fm1,   \fm2,   0.8, \variation, Dictionary[\carrier -> \carrier]);
	g.connect(\fm2,   \fm1,   0.5, \variation, Dictionary[\carrier -> \carrier]);
	g.connect(\fm1,   \saw1,  0.6, \contrast);
	g.connect(\fm2,   \noise, 0.5, \succession);
	g.connect(\saw1,  \pluck, 0.7, \succession, Dictionary[\freq -> \freq]);
	g.connect(\pluck, \fb,    0.4, \transformation);
	g.connect(\fb,    \form,  0.6, \contrast);
	g.connect(\form,  \dust1, 0.5, \succession);
	g.connect(\dust1, \gen,   0.4, \contrast);
	g.connect(\gen,   \fm1,   0.5, \variation);
	g.connect(\noise, \form,  0.3, \transformation);
	g.connect(\pluck, \fm2,   0.3, \variation);

	// two walkers
	~t1 = AcTraversal(\w1, g,
		durFunc: { rrand(3.0, 7.0) },
		fadeTime: 2,
		contrastBias: 0.7
	);
	~t2 = AcTraversal(\w2, g,
		durFunc: { rrand(6.0, 12.0) },
		fadeTime: 4,
		deactivateOnLeave: false
	);
	~t1.walk(\fm1);
	~t2.walk(\pluck);

	// master processing
	g.addProcess(\verb, {|in, room = 30, damp = 0.5, mix = 0.35|
		var verb = FreeVerb2.ar(in[0], in.last, mix, room / 100, damp);
		XFade2.ar(in, verb, mix * 2 - 1)
	});

	~g = g;
	~scope = g.scope([~t1, ~t2]);
	g.print;
}
)

// ---- add more nodes on the fly ----

// a new behaviour, wired in live
(
~g.addNode(\wobble, {|freq = 60, wobRate = 3, amp = 0.15|
	var sig = LFTri.ar(freq) * SinOsc.kr(wobRate).range(0.2, 1.0);
	Pan2.ar(sig, SinOsc.kr(0.1)) * amp
}, (freq: 80, wobRate: 4));
~g.connect(\fm1, \wobble, 0.6, \contrast);
~g.connect(\wobble, \saw1, 0.4, \succession);
)

// or grow with a custom behaviour
(
AcGrowth.preferentialAttachment(~g, \clicks,
	{|rate = 8, freq = 4000, amp = 0.1|
		var trig = Impulse.ar(rate);
		var sig = SinOsc.ar(freq) * EnvGen.ar(Env.perc(0.001, 0.01), trig);
		Pan2.ar(sig, TRand.kr(-1, 1, trig)) * amp
	},
	(rate: 12, freq: 5000, amp: 0.08),
	3
);
)

// inspect
~g.print;

// re-layout
~scope.layoutForce(120); ~scope.userView.refresh;

// stop
~scope.close; ~t1.stop; ~t2.stop; ~g.free;
