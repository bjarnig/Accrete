/*
	Processing Chain — graph-level Ndef processors.
	All nodes route through a private bus. Processors stack on
	the master Ndef using slot-based filtering. Add, tweak, and
	remove processors live without touching the graph.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);

	// graph with routing: all nodes → bus → master Ndef → out 0
	var g = AcGraph(2, 0);
	g.initRouting(\master);

	// build a small network
	g.addNode(\drone,   a.behaviours[\drone],   (freq: 55, drift: 0.1, amp: 0.3));
	g.addNode(\grain,   a.behaviours[\grain],   (freq: 900, density: 14, amp: 0.2));
	g.addNode(\pulse,   a.behaviours[\pulse],   (freq: 150, rate: 5, decay: 0.3, amp: 0.25));
	g.addNode(\shimmer, a.behaviours[\shimmer], (freq: 2800, mod: 0.15, feedback: 0.5, amp: 0.15));
	g.addNode(\bell,    a.behaviours[\bell],    (freq: 1200, decay: 5, amp: 0.15));

	g.connect(\drone, \grain, 0.7, \succession);
	g.connect(\grain, \pulse, 0.5, \contrast);
	g.connect(\pulse, \shimmer, 0.6, \variation);
	g.connect(\shimmer, \bell, 0.4, \transformation);
	g.connect(\bell, \drone, 0.5, \succession);

	// walker
	~t = AcTraversal(\walk, g,
		durFunc: { rrand(4.0, 8.0) },
		fadeTime: 3,
		deactivateOnLeave: false  // layer up
	);
	~t.walk(\drone);

	// --- add processors one by one ---

	// reverb: the whole graph gets a wash
	g.addProcess(\verb, a.processing[\verb]);
	g.setProcess(\verb, \room, 40, \damp, 0.4, \mix, 0.4);

	// gentle fold distortion
	g.addProcess(\fold, a.processing[\fold]);
	g.setProcess(\fold, \foldFreq, 12, \amount, 0.3);

	~g = g;
	~scope = g.scope([~t]);
	g.print;
}
)

// ---- live tweaking (evaluate these one at a time) ----

// change reverb wetness
~g.setProcess(\verb, \mix, 0.7, \room, 80);

// add a frequency shifter
(
var a = Accrete(thisProcess.interpreter);
~g.addProcess(\shift, a.processing[\shift]);
~g.setProcess(\shift, \shiftFreq, 50, \mod, 0.3);
)

// add bit crusher
(
var a = Accrete(thisProcess.interpreter);
~g.addProcess(\crush, a.processing[\crush]);
~g.setProcess(\crush, \bits, 10, \rate, 12000);
)

// add delay
(
var a = Accrete(thisProcess.interpreter);
~g.addProcess(\delay, a.processing[\delay]);
~g.setProcess(\delay, \delayTime, 0.35, \feedback, 0.45);
)

// remove the fold
~g.removeProcess(\fold);

// remove everything except reverb
~g.removeProcess(\shift);
~g.removeProcess(\crush);
~g.removeProcess(\delay);

// see what's running
~g.print;

// add your own processor inline
~g.addProcess(\custom, {|in, rate = 3, depth = 0.4|
	in * SinOsc.kr(rate).range(1 - depth, 1)  // tremolo
});
~g.setProcess(\custom, \rate, 5, \depth, 0.6);

// remove it
~g.removeProcess(\custom);

// stop
~scope.close; ~t.stop; ~g.free;
