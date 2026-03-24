/*
	Averse Network — buffer-playback patterns from Averse.States.24
	converted into network behaviours.

	Each node is a Pbind pattern that triggers buffer samples.
	The walker moves through different rhythmic textures.

	Requirements:
	  - Perc sample folders (hpa/, hpb/, hpc/, hpd/, ... hpk/)
	    at the bufferPath below
	  - Bjorklund quark for t12 (optional — remove t12 if not installed)
*/

(
s.waitForBoot {

	// ---- EDIT THIS PATH to point to your perc samples ----
	var bufferPath = "/Users/bjarni/Library/Application Support/SuperCollider/Extensions/Accrete/examples/perc";

	var a, g;

	a = Accrete(thisProcess.interpreter);

	// load buffers + averse behaviours (must be inside s.waitForBoot for s.sync)
	fork {
		a.loadAverse(thisProcess.interpreter, bufferPath);
		s.sync;

		"Available averse behaviours: %".format(a.averseNames).postln;

		// ---- build the network ----
		g = AcGraph(2, 0);
		g.initRouting(\averse);

		// all averse behaviours
		g.addNode(\r01,  a.averse[\r01]);   // seg sweep c+d
		g.addNode(\r02,  a.averse[\r02]);   // brown drift c+d
		g.addNode(\r03,  a.averse[\r03]);   // triple brownian b+c
		g.addNode(\r04,  a.averse[\r04]);   // stutter-scramble b+d+c
		g.addNode(\s05,  a.averse[\s05]);   // gapped amplitude c
		g.addNode(\s06,  a.averse[\s06]);   // dense b+c
		g.addNode(\s07,  a.averse[\s07]);   // time-scaled b+c
		g.addNode(\s08,  a.averse[\s08]);   // shuffled micro-timing
		g.addNode(\t09,  a.averse[\t09]);   // tight micro-timing
		g.addNode(\t10,  a.averse[\t10]);   // seg sweep c+d short release
		g.addNode(\t11,  a.averse[\t11]);   // finite state machine b
		g.addNode(\t12,  a.averse[\t12]);   // euclidean rhythms h
		g.addNode(\q01,  a.averse[\q01]);   // rapid-fire stutter
		g.addNode(\q02,  a.averse[\q02]);   // d-set random mixed
		g.addNode(\q03,  a.averse[\q03]);   // envelope sweep
		g.addNode(\q04,  a.averse[\q04]);   // indexed stutter-brown
		g.addNode(\r01b, a.averse[\r01b]);  // single buffer seg
		g.addNode(\r02b, a.averse[\r02b]);  // single buffer brown
		g.addNode(\r03b, a.averse[\r03b]);  // single buffer triple brown
		g.addNode(\l19,  a.averse[\l19]);   // legacy envelope-driven

		// dense connectivity — every node has several paths out
		// main ring
		[\r01, \r02, \r03, \r04, \s05, \s06, \s07, \s08,
		 \t09, \t10, \t11, \t12, \q01, \q02, \q03, \q04,
		 \r01b, \r02b, \r03b, \l19].do {|from, i|
			var ids = [\r01, \r02, \r03, \r04, \s05, \s06, \s07, \s08,
				\t09, \t10, \t11, \t12, \q01, \q02, \q03, \q04,
				\r01b, \r02b, \r03b, \l19];
			var types = [\succession, \contrast, \variation, \transformation];
			var next = ids.wrapAt(i + 1);
			g.connect(from, next, rrand(0.5, 0.9), types.wrapAt(i));
		};

		// cross-links: each node gets 2-3 random shortcuts
		g.nodes.keys.do {|from|
			var others = g.nodes.keys.asArray.reject {|k| k == from };
			var types = [\succession, \contrast, \variation, \transformation];
			rrand(2, 3).do {
				g.connect(from, others.choose, rrand(0.2, 0.7), types.choose);
			};
		};

		// two fast walkers + one medium
		~t1 = AcTraversal(\fast1, g,
			durFunc: { rrand(1.0, 3.0) },
			fadeTime: 1,
			contrastBias: 0.7
		);
		~t2 = AcTraversal(\fast2, g,
			durFunc: { rrand(1.0, 2.5) },
			fadeTime: 1,
			contrastBias: 0.6,
			deactivateOnLeave: false
		);
		~t3 = AcTraversal(\mid, g,
			durFunc: { rrand(1.5, 3.0) },
			fadeTime: 1.5,
			deactivateOnLeave: false
		);
		~t1.walk(\r01);
		~t2.walk(\s08);
		~t3.walk(\q01);

		// light processing on the master bus
		g.addProcess(\verb, {|in, mix = 0.2, room = 15, damp = 0.6|
			FreeVerb2.ar(in[0], in.last, mix, room / 100, damp)
		});

		~g = g;
		{ ~scope = g.scope([~t1, ~t2, ~t3], 900, 900); ~scope.nodeRadius = 12 }.defer;
		g.print;
	};
}
)

// inspect
~g.print;
~g.eventLog(20);

// re-layout
~scope.layoutForce(150); ~scope.userView.refresh;

// stop
~scope.close; ~t1.stop; ~t2.stop; ~t3.stop; ~g.free;
