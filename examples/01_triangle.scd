/*
	Triangle — 3 nodes in a cycle.
	A walker loops drone → grain → pulse → drone...
	Each edge carries a param mapping so pitch flows through the network.
*/

(
s.waitForBoot {

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();

	// three nodes
	g.addNode(\drone,  a.behaviours[\drone],  (freq: 55, drift: 0.08, amp: 0.3));
	g.addNode(\grain,  a.behaviours[\grain],  (freq: 880, density: 15, amp: 0.2));
	g.addNode(\pulse,  a.behaviours[\pulse],  (freq: 220, rate: 3, decay: 0.4, amp: 0.25));

	// cycle with param flow: freq propagates
	g.connect(\drone, \grain, 0.8, \succession, Dictionary[\freq -> \freq]);
	g.connect(\grain, \pulse, 0.6, \contrast);
	g.connect(\pulse, \drone, 0.5, \variation, Dictionary[\freq -> \freq]);

	// walk
	~t = AcTraversal(\walk, g, { rrand(5.0, 9.0) }, fadeTime: 3);
	~t.walk(\drone);

	~g = g;
	g.print;
}
)

// stop
~t.stop; ~g.stopAll;
::