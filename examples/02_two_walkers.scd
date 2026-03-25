/*
	Two Walkers — polyphonic traversal.
	A 5-node ring with two independent walkers starting at opposite ends.
	One walks slowly, the other quickly. They overlap and diverge.
*/

(

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();

	g.addNode(\invdem,  a.behaviours[\invdem],  (wfmult: 0.2, seqmult: 10, amp: 0.35));
	g.addNode(\shimmer, a.behaviours[\shimmer], (drive: 22, modLo: 55, modHi: 180, lpfFreq: 2200, amp: 0.12));
	g.addNode(\breath,  a.behaviours[\breath],  (mod: 380, mf: 0.28, amp: 0.35));
	g.addNode(\bell,    a.behaviours[\bell],    (bfmin: 500, bfmax: 2200, freq: 12, amp: 0.15));
	g.addNode(\rumble,  a.behaviours[\rumble],  (rate: 11, trigMin: 350, trigMax: 900, freq: 32, amp: 0.3));

	[\invdem, \shimmer, \breath, \bell, \rumble].do {|from, i|
		var ids = [\invdem, \shimmer, \breath, \bell, \rumble];
		var to = ids.wrapAt(i + 1);
		g.connect(from, to, rrand(0.4, 0.9), [\succession, \contrast, \variation].choose);
		g.connect(to, from, rrand(0.2, 0.5), \variation);
	};

	~slow = AcTraversal(\slow, g,
		durFunc: { rrand(8.0, 14.0) },
		fadeTime: 5,
		deactivateOnLeave: false
	);

	~fast = AcTraversal(\fast, g,
		durFunc: { rrand(2.0, 4.0) },
		fadeTime: 1.5,
		contrastBias: 0.8
	);

	~slow.walk(\invdem);
	~fast.walk(\bell);

	~g = g;
	g.print;

)

// stop
~slow.stop; ~fast.stop; ~g.stopAll;
