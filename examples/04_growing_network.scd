/*
	Growing Network — starts with a 3-node seed and rapidly grows to 50+ nodes
	via preferential attachment. Multiple walkers roam the expanding graph.
	AcScope shows the network evolving live. Nodes are quiet (low amp) so
	many can coexist.
*/

(
	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var behaviourPool, typePool, walkers;

	behaviourPool = [
		[\invdem,  { a.behaviours[\invdem] },  { (wfmult: exprand(0.05, 0.8), seqmult: rrand(3, 30), amp: rrand(0.1, 0.4)) }],
		[\vpay,    { a.behaviours[\vpay] },    { (freq: exprand(4, 40), fmod: exprand(2, 60), ffrom: rrand(10, 200), fto: rrand(400, 4000), index: rrand(0.3, 2.0), amp: rrand(0.04, 0.15)) }],
		[\pulse,   { a.behaviours[\pulse] },   { (freq: exprand(2, 24), fmod: exprand(80, 900), ffrom: rrand(8, 80), fto: rrand(40, 400), index: rrand(0.4, 1.4), amp: rrand(0.02, 0.05)) }],
		[\shimmer, { a.behaviours[\shimmer] }, { (drive: rrand(12, 40), modLo: rrand(30, 90), modHi: rrand(90, 350), lpfFreq: exprand(400, 6000), amp: rrand(0.04, 0.12)) }],
		[\rumble,  { a.behaviours[\rumble] },  { (rate: rrand(4, 22), trigMin: rrand(120, 800), trigMax: rrand(400, 2500), freq: exprand(12, 55), amp: rrand(0.03, 0.06)) }],
		[\breath,  { a.behaviours[\breath] },  { (mod: exprand(80, 900), mf: rrand(0.15, 0.45), amp: rrand(0.25, 0.55), from: rrand(1, 6), to: rrand(8, 35)) }],
		[\bell,    { a.behaviours[\bell] },    { (bfmin: exprand(200, 1200), bfmax: exprand(800, 4000), freq: exprand(4, 28), bw: rrand(6, 22), amp: rrand(0.15, 0.45)) }],
		[\crackle, { a.behaviours[\crackle] }, { (dustRate: rrand(40, 220), crackle: rrand(0.75, 1.85), timeUp: rrand(2, 14), timeDown: rrand(3, 16), amp: rrand(0.02, 0.05)) }],
	];

	typePool = [\succession, \contrast, \variation, \transformation];

	3.do {|i|
		var spec = behaviourPool.choose;
		var id = ("s" ++ i).asSymbol;
		g.addNode(id, spec[1].value, spec[2].value);
	};
	g.connect(\s0, \s1, 0.7, \succession);
	g.connect(\s1, \s2, 0.6, \contrast);
	g.connect(\s2, \s0, 0.5, \variation);

	walkers = [
		AcTraversal(\fast, g, { rrand(1.5, 3.0) }, fadeTime: 1, contrastBias: 0.8),
		AcTraversal(\mid,  g, { rrand(3.0, 6.0) }, fadeTime: 2, contrastBias: 0.5,
			deactivateOnLeave: false),
		AcTraversal(\slow, g, { rrand(6.0, 12.0) }, fadeTime: 4, contrastBias: 0.3,
			deactivateOnLeave: false),
	];
	walkers[0].walk(\s0);
	walkers[1].walk(\s1);
	walkers[2].walk(\s2);

	~scope = g.scope(walkers, 900, 900);
	~scope.nodeRadius = 12;

	~grower = Routine({
		var count = 3;

		while { count < 50 } {
			var spec = behaviourPool.choose;
			var id = ("n" ++ count).asSymbol;
			var numEdges = rrand(1, 3).asInteger;

			rrand(1.0, 3.0).wait;

			AcGrowth.preferentialAttachment(g, id, spec[1].value, spec[2].value, numEdges);

			if(0.3.coin and: { g.nodes.size > 5 }) {
				var keys = g.nodes.keys.asArray;
				var a = keys.choose, b = keys.choose;
				if(a != b) {
					g.connect(a, b, rrand(0.2, 0.8), typePool.choose);
				};
			};

			count = count + 1;

			if(count % 10 == 0) {
				"--- % nodes, % edges ---".format(g.nodes.size, g.edges.size).postln;
			};
		};

		"--- Growth complete: % nodes, % edges ---".format(g.nodes.size, g.edges.size).postln;

		loop {
			rrand(8.0, 15.0).wait;
			if(g.nodes.size < 80) {
				var spec = behaviourPool.choose;
				var id = ("x" ++ 1000.rand).asSymbol;
				AcGrowth.preferentialAttachment(g, id, spec[1].value, spec[2].value, rrand(1, 3).asInteger);
				"--- late addition: % (% nodes) ---".format(id, g.nodes.size).postln;
			};
		};
	}).play;

	~g = g;
	~walkers = walkers;
)

// inspect
~g.print;
~g.eventLog(20);

// re-layout force-directed (good once graph is large)
~scope.layoutForce(150); ~scope.userView.refresh;

// export DOT
~g.saveDot("~/Desktop/accrete_graph.dot".standardizePath);

// stop
~scope.close; ~grower.stop; ~walkers.do(_.stop); ~g.stopAll;


// ---- adding custom behaviours at runtime ----

// any UGen function works as a behaviour — just pass it directly to addNode
(
	~g.addNode(\mysaw, {|freq = 220, width = 0.5, amp = 0.2|
		var sig = VarSaw.ar([freq, freq * 1.003], 0, width);
		LPF.ar(sig, freq * 4) * amp
	}, (freq: 110, amp: 0.15));

	~g.connect(\s0, \mysaw, 0.6, \succession);
)

// a feedback FM node
(
	~g.addNode(\fbfm, {|freq = 80, fb = 1.2, cutoff = 3000, amp = 0.15|
		var sig = SinOscFB.ar([freq, freq * 1.5], fb);
		LPF.ar(sig, cutoff) * amp
	}, (freq: 60, fb: 0.8, amp: 0.12));

	~g.connect(\mysaw, \fbfm, 0.7, \contrast);
)

// a filtered noise texture
(
	~g.addNode(\wash, {|density = 40, bpFreq = 800, bpRq = 0.3, amp = 0.1|
		var src = Dust2.ar([density, density * 1.1]);
		BPF.ar(src, bpFreq, bpRq) * amp / bpRq
	}, (density: 30, bpFreq: 1200, amp: 0.08));

	~g.connect(\fbfm, \wash, 0.5, \variation);
	~g.connect(\wash, \s0, 0.4, \succession);
)

// update params on a running node
~g.nodes[\mysaw].set(\freq, 330);
~g.nodes[\wash].set(\bpFreq, 2400);
