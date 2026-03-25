/*
	Star — a central vpay hub with satellite textures.
	The walker always returns to the hub between satellites.
	Param mapping: the hub's freq seeds each satellite.
*/

(

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();

	g.addNode(\hub, a.behaviours[\vpay], (freq: 14, fmod: 10, ffrom: 20, fto: 2250, index: 0.8, amp: 0.25));

	g.addNode(\invdem,  a.behaviours[\invdem],  (wfmult: 0.2, seqmult: 10, amp: 0.4));
	g.addNode(\crackle, a.behaviours[\crackle], (dustRate: 100, crackle: 0.88, timeUp: 5, timeDown: 9, amp: 0.15));
	g.addNode(\shimmer, a.behaviours[\shimmer], (drive: 20, modLo: 48, modHi: 160, lpfFreq: 1800, amp: 0.12));
	g.addNode(\bell,    a.behaviours[\bell],    (bfmin: 450, bfmax: 2000, freq: 11, amp: 0.15));

	[\invdem, \crackle, \shimmer, \bell].do {|sat|
		var pmap = case
			{ sat == \bell } { Dictionary[\freq -> \freq] }
			{ sat == \shimmer } { Dictionary[\freq -> \drive] }
			{ true } { nil };
		g.connect(\hub, sat, rrand(0.5, 0.9), \succession, pmap);
		g.connect(sat, \hub, 1.0, \contrast);
	};

	~t = AcTraversal(\star, g,
		durFunc: {|id| if(id == \hub) { rrand(3.0, 5.0) } { rrand(6.0, 10.0) } },
		fadeTime: 3
	);

	~t.walk(\hub);

	~g = g;
	g.print;

)

// stop
~t.stop; ~g.stopAll;
