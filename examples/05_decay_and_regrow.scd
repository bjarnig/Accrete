/*
	Decay & Regrow — edges have decay rates and weaken over time.
	A maintenance routine periodically decays edges and grows new ones,
	so the network slowly reshapes itself while a walker traverses it.
*/

(
	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var behaviourPool;

	g.addNode(\invdem,  a.behaviours[\invdem],  (wfmult: 0.2, seqmult: 10, amp: 0.4));
	g.addNode(\vpay,    a.behaviours[\vpay],    (freq: 12, fmod: 10, ffrom: 20, fto: 2250, index: 0.8, amp: 0.2));
	g.addNode(\pulse,   a.behaviours[\pulse],   (freq: 7, fmod: 320, ffrom: 18, fto: 90, amp: 0.2));
	g.addNode(\breath,  a.behaviours[\breath],  (mod: 320, mf: 0.3, amp: 0.38));

	[\invdem, \vpay, \pulse, \breath].do {|from|
		[\invdem, \vpay, \pulse, \breath].do {|to|
			if(from != to) {
				g.connect(from, to, rrand(0.4, 1.0), \succession, nil, rrand(0.02, 0.08));
			};
		};
	};

	"Initial state:".postln;
	g.print;

	~t = AcTraversal(\walker, g,
		durFunc: { rrand(4.0, 8.0) },
		fadeTime: 2
	);
	~t.walk(\invdem);

	behaviourPool = [
		[\shimmer, a.behaviours[\shimmer], (drive: 24, modLo: 50, modHi: 200, lpfFreq: 2400, amp: 0.12)],
		[\bell,    a.behaviours[\bell],    (bfmin: 400, bfmax: 1800, freq: 10, amp: 0.15)],
		[\crackle, a.behaviours[\crackle], (dustRate: 110, crackle: 0.85, amp: 0.15)],
		[\rumble,  a.behaviours[\rumble],  (rate: 12, trigMin: 380, trigMax: 950, freq: 28, amp: 0.25)],
	];

	~maintenance = Routine({
		var cycle = 0;
		loop {
			rrand(10.0, 18.0).wait;
			cycle = cycle + 1;

			"--- Cycle %: decaying edges...".format(cycle).postln;
			AcGrowth.decayEdges(g, rrand(1.0, 3.0));
			"    % edges remain".format(g.edges.size).postln;

			if(g.edges.size < (g.nodes.size) and: { behaviourPool.notEmpty }) {
				var spec = behaviourPool.removeAt(0);
				"    Adding new node: %".format(spec[0]).postln;
				AcGrowth.preferentialAttachment(g, spec[0], spec[1], spec[2], 2);
			};

			if(g.edges.notEmpty) {
				var edge = g.edges.choose;
				edge.weight = (edge.weight + rrand(0.1, 0.3)).min(1.0);
				"    Reinforced: % -> % (w: %)".format(edge.from, edge.to, edge.weight.round(0.01)).postln;
			};
		}
	}).play;

	~g = g;
)

// inspect
~g.print;
~g.eventLog(20);

// stop
~maintenance.stop; ~t.stop; ~g.stopAll;
