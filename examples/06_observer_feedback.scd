/*
	Observer Feedback — an observer watches a drone's amplitude
	and grows/modifies the network in response.
	When the drone is loud, new connections form. When quiet, edges decay.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var spareNodes;

	g.addNode(\drone,  a.behaviours[\drone],  (freq: 55, drift: 0.15, amp: 0.35));
	g.addNode(\grain,  a.behaviours[\grain],  (freq: 600, density: 10, amp: 0.2));
	g.addNode(\pulse,  a.behaviours[\pulse],  (freq: 120, rate: 3, amp: 0.2));

	g.connect(\drone, \grain, 0.6, \succession);
	g.connect(\grain, \pulse, 0.5, \contrast);
	g.connect(\pulse, \drone, 0.4, \variation);

	// walker
	~t = AcTraversal(\walk, g,
		durFunc: { rrand(5.0, 9.0) },
		fadeTime: 3
	);
	~t.walk(\drone);

	// nodes to add when triggered
	spareNodes = List[
		[\shimmer, a.behaviours[\shimmer], (freq: 2800, amp: 0.12)],
		[\bell,    a.behaviours[\bell],    (freq: 1100, amp: 0.15)],
		[\rumble,  a.behaviours[\rumble],  (freq: 25, amp: 0.25)],
	];

	// observer: watches drone amplitude
	~obs = AcObserver(\ampWatch, g, \drone, a.observers[\features][\amplitude], {|vals, graph, obs|
		var amp = vals[0];
		if(amp > 0.3) {
			// loud → maybe grow
			if(spareNodes.notEmpty and: { 0.02.coin }) {
				var spec = spareNodes.removeAt(0);
				"Observer triggered growth: adding %".format(spec[0]).postln;
				AcGrowth.preferentialAttachment(graph, spec[0], spec[1], spec[2]);
			};
		} {
			// quiet → decay
			if(0.05.coin) {
				AcGrowth.decayEdges(graph, 0.5);
			};
		};
	});
	~obs.start;

	~g = g;
	g.print;
}
)

// inspect
~g.print;
~g.eventLog(20);

// stop
~obs.stop; ~t.stop; ~g.stopAll;
