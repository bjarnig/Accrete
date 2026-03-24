AcObserver {
	var <>id, <>graph, <>nodeId, <>feature, <>action;
	var <>oscFunc, <>analysisKey, <>running;

	*new {|id, graph, nodeId, feature, action|
		^super.newCopyArgs(id, graph, nodeId, feature, action).init
	}

	init {
		running = false;
		analysisKey = ("ac_obs_" ++ id).asSymbol;
	}

	start {
		var replyPath = ("/" ++ analysisKey).asSymbol;
		var node = graph.nodes[nodeId];

		if(node.isNil) {
			"AcObserver(%): node % not found".format(id, nodeId).warn;
			^this
		};

		Ndef(analysisKey, {
			var sig = Ndef(nodeId).ar;
			var values = SynthDef.wrap(feature, prependArgs: [sig]);
			SendReply.kr(Impulse.kr(10), replyPath, values);
			Silent.ar;
		}).play;

		oscFunc = OSCFunc({|msg|
			var values = msg[3..];
			action.value(values, graph, this);
		}, replyPath);

		running = true;
		graph.events.add(AcEvent(\observerStart, nodeId, id));
	}

	stop {
		if(oscFunc.notNil) { oscFunc.free; oscFunc = nil };
		Ndef(analysisKey).stop;
		Ndef(analysisKey).clear;
		running = false;
		graph.events.add(AcEvent(\observerStop, nodeId, id));
	}
}