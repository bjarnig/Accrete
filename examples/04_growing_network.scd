/*
	Growing Network — starts with a 3-node seed and rapidly grows to 50+ nodes
	via preferential attachment. Multiple walkers roam the expanding graph.
	AcScope shows the network evolving live. Nodes are quiet (low amp) so
	many can coexist.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var behaviourPool, typePool, walkers;

	// behaviour templates — low amp so dozens can overlap safely
	behaviourPool = [
		[\drone,   { a.behaviours[\drone] },   { (freq: exprand(30, 200), drift: rrand(0.05, 0.3), amp: rrand(0.02, 0.06)) }],
		[\grain,   { a.behaviours[\grain] },   { (freq: exprand(200, 4000), density: rrand(4, 30), dur: rrand(0.02, 0.1), amp: rrand(0.02, 0.05)) }],
		[\pulse,   { a.behaviours[\pulse] },   { (freq: exprand(60, 800), rate: rrand(1, 12), decay: rrand(0.05, 0.5), amp: rrand(0.02, 0.05)) }],
		[\shimmer, { a.behaviours[\shimmer] }, { (freq: exprand(800, 6000), mod: rrand(0.05, 0.5), feedback: rrand(0.3, 0.7), amp: rrand(0.01, 0.04)) }],
		[\rumble,  { a.behaviours[\rumble] },  { (freq: exprand(15, 60), chaos: rrand(1.2, 1.8), amp: rrand(0.03, 0.06)) }],
		[\breath,  { a.behaviours[\breath] },  { (freq: exprand(100, 3000), bw: rrand(50, 500), rate: rrand(0.05, 0.4), amp: rrand(0.02, 0.05)) }],
		[\bell,    { a.behaviours[\bell] },    { (freq: exprand(200, 4000), decay: rrand(1, 8), amp: rrand(0.01, 0.04)) }],
		[\crackle, { a.behaviours[\crackle] }, { (chaos: rrand(1.2, 1.95), density: rrand(5, 40), hpf: exprand(500, 8000), amp: rrand(0.02, 0.05)) }],
	];

	typePool = [\succession, \contrast, \variation, \transformation];

	// seed: 3 connected nodes
	3.do {|i|
		var spec = behaviourPool.choose;
		var id = ("s" ++ i).asSymbol;
		g.addNode(id, spec[1].value, spec[2].value);
	};
	g.connect(\s0, \s1, 0.7, \succession);
	g.connect(\s1, \s2, 0.6, \contrast);
	g.connect(\s2, \s0, 0.5, \variation);

	// 3 walkers — fast, medium, slow
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

	// scope
	~scope = g.scope(walkers, 900, 900);
	~scope.nodeRadius = 12;

	// rapid growth: a new node every 1-3 seconds, up to 50 nodes
	~grower = Routine({
		var count = 3; // already have 3 seeds

		while { count < 50 } {
			var spec = behaviourPool.choose;
			var id = ("n" ++ count).asSymbol;
			var numEdges = rrand(1, 3).asInteger;

			rrand(1.0, 3.0).wait;

			AcGrowth.preferentialAttachment(g, id, spec[1].value, spec[2].value, numEdges);

			// occasionally add extra cross-links for density
			if(0.3.coin and: { g.nodes.size > 5 }) {
				var keys = g.nodes.keys.asArray;
				var a = keys.choose, b = keys.choose;
				if(a != b) {
					g.connect(a, b, rrand(0.2, 0.8), typePool.choose);
				};
			};

			count = count + 1;

			// print milestone every 10
			if(count % 10 == 0) {
				"--- % nodes, % edges ---".format(g.nodes.size, g.edges.size).postln;
			};
		};

		"--- Growth complete: % nodes, % edges ---".format(g.nodes.size, g.edges.size).postln;

		// optional: keep adding slowly after initial burst
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
}
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
