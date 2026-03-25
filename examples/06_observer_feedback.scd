/*
	Observer Feedback — an observer watches invdem's amplitude
	and grows/modifies the network in response.
	When invdem is loud, new connections form. When quiet, edges decay.
*/

(
	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();
	var spareNodes;

	g.addNode(\invdem, a.behaviours[\invdem], (wfmult: 0.2, seqmult: 10, amp: 0.45));
	g.addNode(\vpay,   a.behaviours[\vpay],   (freq: 12, fmod: 10, ffrom: 20, fto: 2250, index: 0.8, amp: 0.2));
	g.addNode(\pulse,  a.behaviours[\pulse],  (freq: 5, fmod: 360, ffrom: 20, fto: 100, amp: 0.2));

	g.connect(\invdem, \vpay, 0.6, \succession);
	g.connect(\vpay, \pulse, 0.5, \contrast);
	g.connect(\pulse, \invdem, 0.4, \variation);

	~t = AcTraversal(\walk, g,
		durFunc: { rrand(5.0, 9.0) },
		fadeTime: 3
	);
	~t.walk(\invdem);

	spareNodes = List[
		[\shimmer, a.behaviours[\shimmer], (drive: 26, modLo: 52, modHi: 220, lpfFreq: 2600, amp: 0.12)],
		[\bell,    a.behaviours[\bell],    (bfmin: 480, bfmax: 2400, freq: 9, amp: 0.15)],
		[\rumble,  a.behaviours[\rumble],  (rate: 13, trigMin: 320, trigMax: 880, freq: 26, amp: 0.25)],
	];

	~obs = AcObserver(\ampWatch, g, \invdem, a.observers[\features][\amplitude], {|vals, graph, obs|
		var amp = vals[0];
		if(amp > 0.3) {
			if(spareNodes.notEmpty and: { 0.02.coin }) {
				var spec = spareNodes.removeAt(0);
				"Observer triggered growth: adding %".format(spec[0]).postln;
				AcGrowth.preferentialAttachment(graph, spec[0], spec[1], spec[2]);
			};
		} {
			if(0.05.coin) {
				AcGrowth.decayEdges(graph, 0.5);
			};
		};
	});
	~obs.start;

	~g = g;
	g.print;
)

// inspect
~g.print;
~g.eventLog(20);

// stop
~obs.stop; ~t.stop; ~g.stopAll;
