/*
	Triangle — 3 nodes in a cycle.
	A walker loops invdem → vpay → pulse → invdem...
	Each edge carries a param mapping so pitch flows through the network.
*/

(

	var a = Accrete(thisProcess.interpreter);
	var g = AcGraph();

	g.addNode(\invdem, a.behaviours[\invdem], (wfmult: 0.2, seqmult: 10, amp: 0.5));
	g.addNode(\vpay,   a.behaviours[\vpay],   (freq: 10, fmod: 10, ffrom: 20, fto: 2250, index: 0.8, amp: 0.2));
	g.addNode(\pulse,  a.behaviours[\pulse],  (freq: 6, fmod: 400, ffrom: 24, fto: 140, index: 0.9, amp: 0.25));

	g.connect(\invdem, \vpay, 0.8, \succession);
	g.connect(\vpay, \pulse, 0.6, \succession, Dictionary[\freq -> \freq]);
	g.connect(\pulse, \invdem, 0.5, \succession);

	~t = AcTraversal(\walk, g, { rrand(5.0, 9.0) }, fadeTime: 3);
	~t.walk(\invdem);

	~g = g;
	g.print;

)

// stop
~t.stop; ~g.stopAll;
