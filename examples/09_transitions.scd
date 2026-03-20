/*
	Transitions — each edge type produces a different sonic handoff.

	- succession:      smooth crossfade, params interpolate gradually
	- contrast:        quick cut, brief silence, abrupt entry
	- variation:       long overlap, old node morphs toward new
	- transformation:  slow simultaneous sweep, params drift over long duration

	Also demonstrates custom per-edge transitions.
*/

(
s.waitForBoot {

	var g, t;

	g = AcGraph(2, 0);
	g.initRouting(\master);

	// nodes with shared param names so interpolation is audible
	g.addNode(\low, {|freq = 60, amp = 0.3, cut = 400|
		LPF.ar(Saw.ar([freq, freq * 1.003]), cut) * amp
	}, (freq: 60, amp: 0.3, cut: 400));

	g.addNode(\mid, {|freq = 300, amp = 0.25, cut = 2000|
		LPF.ar(Pulse.ar([freq, freq * 0.998], 0.4), cut) * amp
	}, (freq: 300, amp: 0.25, cut: 2000));

	g.addNode(\high, {|freq = 1200, amp = 0.15, cut = 6000|
		LPF.ar(SinOsc.ar([freq, freq * 1.005]) + Crackle.ar(1.5, 0.1), cut) * amp
	}, (freq: 1200, amp: 0.15, cut: 6000));

	g.addNode(\noise, {|freq = 800, amp = 0.2, cut = 3000|
		LPF.ar(BPF.ar(PinkNoise.ar, freq, 0.3), cut) * amp * 5
	}, (freq: 800, amp: 0.2, cut: 3000));

	g.addNode(\fm, {|freq = 200, amp = 0.2, cut = 4000, index = 3|
		LPF.ar(PMOsc.ar([freq, freq * 1.002], freq * 2.01, index), cut) * amp
	}, (freq: 200, amp: 0.2, cut: 4000, index: 3));

	// each edge uses a different transition type, with param mapping
	g.connect(\low,   \mid,   0.8, \succession,      Dictionary[\freq -> \freq, \cut -> \cut]);
	g.connect(\mid,   \high,  0.7, \contrast);
	g.connect(\high,  \noise, 0.6, \variation,        Dictionary[\freq -> \freq]);
	g.connect(\noise, \fm,    0.5, \transformation,   Dictionary[\freq -> \freq, \cut -> \cut]);
	g.connect(\fm,    \low,   0.7, \succession,       Dictionary[\freq -> \freq]);

	// add some cross-links with different types
	g.connect(\low,   \noise, 0.3, \variation,        Dictionary[\freq -> \freq]);
	g.connect(\high,  \fm,    0.3, \transformation,   Dictionary[\freq -> \freq]);
	g.connect(\mid,   \low,   0.4, \contrast);

	// a longer fade time makes transitions more audible
	t = AcTraversal(\walk, g,
		durFunc: { rrand(6.0, 10.0) },
		fadeTime: 4,
		contrastBias: 0.4
	);
	t.walk(\low);

	// light reverb on master
	g.addProcess(\verb, {|in, mix = 0.25, room = 20, damp = 0.5|
		FreeVerb2.ar(in[0], in.last, mix, room / 100, damp)
	});

	~g = g;
	~t = t;
	~scope = g.scope([t]);
	g.print;
}
)

// ---- custom per-edge transition ----
// override one edge with a stutter effect
(
var edge = ~g.edgesFrom(\mid).detect {|e| e.to == \high };
edge.transition = {|from, to, edge, trav|
	var gap = 0.15;
	// rapid stutter: cut and restart the old node 4 times
	4.do {
		from.deactivate(0.05);
		gap.wait;
		from.activate(trav.graph.nodeBus, 0.05);
		gap.wait;
	};
	from.deactivate(0.3);
	0.3.wait;
	to.activate(trav.graph.nodeBus, 0.5);
	0.5.wait;
};
)

// ---- custom transition type ----
// add a new type to the walker's transition dictionary
(
~t.transitions[\glitch] = {|from, to, edge, trav|
	var dur = trav.fadeTime;
	// activate new immediately
	to.activate(trav.graph.nodeBus, 0.1);
	// rapidly alternate params between old and new values
	fork {
		(dur / 0.1).asInteger.do {
			if(0.5.coin) {
				to.params.keysValuesDo {|k, v|
					var alt = from.params[k];
					if(alt.notNil and: { alt.isNumber }) { to.set(k, alt) };
				};
			} {
				to.params.keysValuesDo {|k, v|
					if(v.isNumber) { to.set(k, v) };
				};
			};
			0.1.wait;
		};
	};
	if(trav.deactivateOnLeave) { from.deactivate(dur * 0.5) };
	dur.wait;
};

// use it: set an edge to use \glitch type
~g.connect(\fm, \mid, 0.5, \glitch);
)

// inspect
~g.print;
~g.eventLog(20);

// stop
~scope.close; ~t.stop; ~g.free;
