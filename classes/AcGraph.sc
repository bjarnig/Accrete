AcGraph {
	var <>nodes, <>edges, <>events;
	var <>bus, <>masterKey, <>channels, <>out, <>processors, <>nextSlot;

	*new {|channels = 2, out = 0|
		^super.newCopyArgs(
			IdentityDictionary.new, List.new, List.new,
			nil, nil, channels, out, IdentityDictionary.new, 10
		)
	}

	// ---- routing ----

	initRouting {|masterName|
		masterKey = masterName ?? { ("ac_master_" ++ this.identityHash.abs).asSymbol };
		bus = Bus.audio(Server.default, channels);
		Ndef(masterKey).reshaping = \elastic;
		Ndef(masterKey)[0] = { InFeedback.ar(bus, channels) };
		Ndef(masterKey).play(out, channels);
		events.add(AcEvent(\initRouting, masterKey, nil, (bus: bus.index, out: out)));
		"AcGraph: routing via bus % -> Ndef(%) -> out %".format(bus.index, masterKey, out).postln;
	}

	addProcess {|name, func|
		var slot;
		if(masterKey.isNil) { this.initRouting };
		slot = nextSlot;
		nextSlot = nextSlot + 10;
		Ndef(masterKey)[slot] = \filter -> func;
		processors[name] = (slot: slot, func: func);
		events.add(AcEvent(\addProcess, name, nil, (slot: slot)));
		"AcGraph: added process '%' at slot %".format(name, slot).postln;
	}

	removeProcess {|name|
		var info = processors[name];
		if(info.notNil) {
			Ndef(masterKey)[info[\slot]] = nil;
			processors.removeAt(name);
			events.add(AcEvent(\removeProcess, name, nil));
			"AcGraph: removed process '%'".format(name).postln;
		};
	}

	setProcess {|name ... args|
		if(masterKey.notNil) {
			Ndef(masterKey).set(*args);
		};
	}

	// the output bus index that nodes should play to
	nodeBus {
		^if(bus.notNil) { bus.index } { out }
	}

	// ---- nodes ----

	addNode {|id, behaviour, params, nodeChannels|
		var node = AcNode(id, behaviour, params, nodeChannels ?? { channels });
		nodes[id] = node;
		events.add(AcEvent(\addNode, id, nil, (behaviour: behaviour)));
		^node
	}

	removeNode {|id|
		var node = nodes[id];
		if(node.notNil) {
			if(node.active) { node.deactivate };
			nodes.removeAt(id);
			edges = edges.reject {|e| (e.from == id) or: (e.to == id) };
			events.add(AcEvent(\removeNode, id, nil));
		};
	}

	// ---- edges ----

	connect {|from, to, weight = 1.0, type = \succession, paramMap, decayRate = 0.0|
		var edge = AcEdge(from, to, weight, type, paramMap, decayRate);
		edges.add(edge);
		events.add(AcEvent(\connect, from, nil, (to: to, weight: weight, type: type)));
		^edge
	}

	disconnect {|from, to|
		edges = edges.reject {|e| (e.from == from) and: (e.to == to) };
		events.add(AcEvent(\disconnect, from, nil, (to: to)));
	}

	edgesFrom {|id|
		^edges.select {|e| e.from == id }
	}

	edgesTo {|id|
		^edges.select {|e| e.to == id }
	}

	// ---- queries ----

	degree {|id|
		^(this.edgesFrom(id).size + this.edgesTo(id).size)
	}

	neighbors {|id|
		var outN = this.edgesFrom(id).collect(_.to);
		var inN = this.edgesTo(id).collect(_.from);
		^(outN ++ inN).asSet.asArray
	}

	activeNodes {
		^nodes.select {|n| n.active }
	}

	// ---- lifecycle ----

	stopAll {|fadeTime = 2|
		nodes.do {|node|
			if(node.active) { node.deactivate(fadeTime) };
		};
		events.add(AcEvent(\stopAll, \graph, nil));
	}

	freeRouting {
		if(masterKey.notNil) {
			Ndef(masterKey).stop;
			Ndef(masterKey).clear;
		};
		if(bus.notNil) { bus.free; bus = nil };
		processors.clear;
		nextSlot = 10;
	}

	free {|fadeTime = 2|
		this.stopAll(fadeTime);
		this.freeRouting;
	}

	// ---- display ----

	print {
		"--- AcGraph ---".postln;
		if(bus.notNil) {
			("Routing: bus % -> Ndef(%) -> out %".format(bus.index, masterKey, out)).postln;
			if(processors.notEmpty) {
				("Processors (" ++ processors.size ++ "):").postln;
				processors.keysValuesDo {|name, info|
					("  " ++ name ++ " [slot " ++ info[\slot] ++ "]").postln;
				};
			};
		};
		("Nodes (" ++ nodes.size ++ "):").postln;
		nodes.keysValuesDo {|key, node|
			("  " ++ node).postln;
		};
		("Edges (" ++ edges.size ++ "):").postln;
		edges.do {|edge|
			("  " ++ edge).postln;
		};
		("Events: " ++ events.size).postln;
	}

	eventLog {|count = 10|
		var recent = events.last(count.min(events.size));
		"--- Event Log (last %) ---".format(recent.size).postln;
		recent.do {|ev| ("  " ++ ev).postln };
	}

	// ---- visualization ----

	scope {|traversals, width = 700, height = 700|
		var s = AcScope(this, traversals, width, height);
		s.open;
		^s
	}

	dot {|name = "AcGraph"|
		var lines = List.new;
		lines.add("digraph" + name + "{");
		lines.add("  bgcolor=\"#19191e\";");
		lines.add("  node [shape=circle, style=filled, fontcolor=\"#c8cdd7\", fontsize=11, fontname=\"Helvetica\"];");
		lines.add("  edge [fontsize=9, fontname=\"Helvetica\"];");
		lines.add("");
		nodes.keysValuesDo {|key, node|
			var color = if(node.active) { "\"#78c8a0\"" } { "\"#505a6e\"" };
			var penwidth = node.activationCount.linlin(0, 10, 1, 3).min(3);
			lines.add("  % [fillcolor=%, penwidth=%];".format(key, color, penwidth));
		};
		lines.add("");
		edges.do {|edge|
			var color = switch(edge.type,
				\succession,     "\"#648cb4\"",
				\contrast,       "\"#b46464\"",
				\variation,      "\"#64b478\"",
				\transformation, "\"#b4a050\"",
				"\"#3c4150\""
			);
			var penwidth = edge.weight.linlin(0, 1, 0.5, 3.0);
			lines.add("  % -> % [color=%, penwidth=%, label=\"%\"];".format(
				edge.from, edge.to, color, penwidth.round(0.1), edge.weight.round(0.01)
			));
		};
		lines.add("}");
		^lines.join("\n")
	}

	saveDot {|path, name = "AcGraph"|
		var str = this.dot(name);
		File.use(path, "w", {|f| f.write(str) });
		"DOT saved to: %".format(path).postln;
	}
}