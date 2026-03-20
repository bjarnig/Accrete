/*
	Star — a central drone hub with satellite textures.
	The walker always returns to the drone between satellites.
	Param mapping: the drone's freq seeds each satellite.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();

	// hub
	g.addNode(\hub, a.behaviours[\drone], (freq: 72, drift: 0.05, amp: 0.35));

	// satellites
	g.addNode(\grain,   a.behaviours[\grain],   (freq: 500, density: 20, amp: 0.2));
	g.addNode(\crackle, a.behaviours[\crackle], (chaos: 1.7, density: 30, amp: 0.15));
	g.addNode(\shimmer, a.behaviours[\shimmer], (freq: 2000, mod: 0.2, amp: 0.12));
	g.addNode(\bell,    a.behaviours[\bell],    (freq: 900, decay: 6, amp: 0.15));

	// hub → each satellite, and back
	[\grain, \crackle, \shimmer, \bell].do {|sat|
		g.connect(\hub, sat, rrand(0.5, 0.9), \succession, Dictionary[\freq -> \freq]);
		g.connect(sat, \hub, 1.0, \contrast);  // always return to hub
	};

	// walk
	~t = AcTraversal(\star, g,
		durFunc: {|id| if(id == \hub) { rrand(3.0, 5.0) } { rrand(6.0, 10.0) } },
		fadeTime: 3
	);
	~t.walk(\hub);

	~g = g;
	g.print;
}
)

// stop
~t.stop; ~g.stopAll;
