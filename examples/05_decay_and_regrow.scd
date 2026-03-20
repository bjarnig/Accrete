/*
	Decay & Regrow — edges have decay rates and weaken over time.
	A maintenance routine periodically decays edges and grows new ones,
	so the network slowly reshapes itself while a walker traverses it.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var behaviourPool;

	// initial densely connected graph
	g.addNode(\drone,   a.behaviours[\drone],   (freq: 65, amp: 0.3));
	g.addNode(\grain,   a.behaviours[\grain],   (freq: 700, density: 14, amp: 0.2));
	g.addNode(\pulse,   a.behaviours[\pulse],   (freq: 150, rate: 6, amp: 0.2));
	g.addNode(\breath,  a.behaviours[\breath],  (freq: 500, bw: 200, amp: 0.2));

	// fully connected with decay rates
	[\drone, \grain, \pulse, \breath].do {|from|
		[\drone, \grain, \pulse, \breath].do {|to|
			if(from != to) {
				g.connect(from, to, rrand(0.4, 1.0), \succession, nil, rrand(0.02, 0.08));
			};
		};
	};

	"Initial state:".postln;
	g.print;

	// walker
	~t = AcTraversal(\walker, g,
		durFunc: { rrand(4.0, 8.0) },
		fadeTime: 2
	);
	~t.walk(\drone);

	// behaviours to pick from when regrowing
	behaviourPool = [
		[\shimmer, a.behaviours[\shimmer], (freq: 2500, amp: 0.12)],
		[\bell,    a.behaviours[\bell],    (freq: 800, amp: 0.15)],
		[\crackle, a.behaviours[\crackle], (chaos: 1.7, amp: 0.15)],
		[\rumble,  a.behaviours[\rumble],  (freq: 30, amp: 0.25)],
	];

	// maintenance loop
	~maintenance = Routine({
		var cycle = 0;
		loop {
			rrand(10.0, 18.0).wait;
			cycle = cycle + 1;

			// decay all edges
			"--- Cycle %: decaying edges...".format(cycle).postln;
			AcGrowth.decayEdges(g, rrand(1.0, 3.0));
			"    % edges remain".format(g.edges.size).postln;

			// if edges are getting sparse, add a new node
			if(g.edges.size < (g.nodes.size) and: { behaviourPool.notEmpty }) {
				var spec = behaviourPool.removeAt(0);
				"    Adding new node: %".format(spec[0]).postln;
				AcGrowth.preferentialAttachment(g, spec[0], spec[1], spec[2], 2);
			};

			// reinforce a random surviving edge
			if(g.edges.notEmpty) {
				var edge = g.edges.choose;
				edge.weight = (edge.weight + rrand(0.1, 0.3)).min(1.0);
				"    Reinforced: % -> % (w: %)".format(edge.from, edge.to, edge.weight.round(0.01)).postln;
			};
		}
	}).play;

	~g = g;
}
)

// inspect
~g.print;
~g.eventLog(20);

// stop
~maintenance.stop; ~t.stop; ~g.stopAll;
