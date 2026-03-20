AcGrowth {

	*preferentialAttachment {|graph, id, behaviour, params, numEdges = 2, type = \succession|
		var node, candidates, degrees, total, chosen;
		node = graph.addNode(id, behaviour, params);
		graph.events.add(AcEvent(\growth, id, \preferentialAttachment));

		candidates = graph.nodes.keys.asArray.reject {|k| k == id };
		if(candidates.isEmpty) { ^node };

		degrees = candidates.collect {|k| graph.degree(k).max(1) };
		total = degrees.sum;

		// select targets weighted by degree
		chosen = Set.new;
		numEdges.min(candidates.size).do {
			var roll = total.rand, cumulative = 0;
			candidates.do {|k, i|
				if(chosen.includes(k).not) {
					cumulative = cumulative + degrees[i];
					if(roll <= cumulative and: { chosen.includes(k).not }) {
						chosen.add(k);
						graph.connect(id, k, rrand(0.3, 1.0), type);
						graph.connect(k, id, rrand(0.1, 0.5), type);
					};
				};
			};
		};

		^node
	}

	*randomAttachment {|graph, id, behaviour, params, numEdges = 2, type = \succession|
		var node, candidates, targets;
		node = graph.addNode(id, behaviour, params);
		graph.events.add(AcEvent(\growth, id, \randomAttachment));

		candidates = graph.nodes.keys.asArray.reject {|k| k == id };
		targets = candidates.scramble.keep(numEdges.min(candidates.size));
		targets.do {|k|
			graph.connect(id, k, rrand(0.3, 1.0), type);
		};

		^node
	}

	*smallWorldRewire {|graph, probability = 0.1|
		var rewired = 0;
		graph.edges.do {|edge|
			if(probability.coin) {
				var candidates = graph.nodes.keys.asArray.reject {|k|
					(k == edge.from) or: (k == edge.to)
				};
				if(candidates.notEmpty) {
					edge.to = candidates.choose;
					rewired = rewired + 1;
				};
			};
		};
		graph.events.add(AcEvent(\growth, \graph, \smallWorldRewire, (rewired: rewired)));
		^rewired
	}

	*decayEdges {|graph, dt = 1.0|
		var removed = 0;
		graph.edges.do {|edge| edge.decay(dt) };
		removed = graph.edges.count {|e| e.weight <= 0 };
		graph.edges = graph.edges.reject {|e| e.weight <= 0 };
		if(removed > 0) {
			graph.events.add(AcEvent(\decay, \graph, \decayEdges, (removed: removed)));
		};
		^removed
	}
}