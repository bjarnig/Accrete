AcTraversal {
	var <>id, <>graph, <>durFunc, <>fadeTime, <>contrastBias, <>deactivateOnLeave, <>maxHistory;
	var <>routine, <>history, <>currentNode, <>running;

	*new {|id, graph, durFunc, fadeTime = 2, contrastBias = 0.5, deactivateOnLeave = true, maxHistory = 16|
		^super.newCopyArgs(
			id, graph, durFunc ?? {{ rrand(4.0, 8.0) }},
			fadeTime, contrastBias, deactivateOnLeave, maxHistory
		).init
	}

	init {
		history = List.new;
		running = false;
	}

	walk {|startId|
		var node;
		if(running) { this.stop };
		running = true;
		routine = Routine({
			currentNode = startId;
			loop {
				node = graph.nodes[currentNode];
				if(node.isNil) {
					"AcTraversal(%): node % not found, stopping".format(id, currentNode).warn;
					running = false;
					nil
				} {
					// activate current node — route to graph bus if routing is set up
					node.activate(graph.nodeBus, fadeTime);
					graph.events.add(AcEvent(\activate, currentNode, id, (traversal: id)));
					history.add(currentNode);
					if(history.size > maxHistory) { history.removeAt(0) };

					// wait
					durFunc.value(currentNode, node).wait;

					// choose next
					currentNode = this.chooseNext(currentNode);
					if(currentNode.isNil) {
						"AcTraversal(%): no edges from %, stopping".format(id, history.last).warn;
						running = false;
						nil
					} {
						// deactivate previous if configured
						if(deactivateOnLeave) {
							node.deactivate(fadeTime);
							graph.events.add(AcEvent(\deactivate, node.id, id));
						};

						// apply param map from edge
						this.applyParamMap(history.last, currentNode);
					}
				}
			}
		}).play;
	}

	chooseNext {|fromId|
		var outEdges = graph.edgesFrom(fromId);
		var weights, recencyPenalty, combined, total, roll, cumulative;
		if(outEdges.isEmpty) { ^nil };

		weights = outEdges.collect(_.weight);

		// modulate weights by recency — recently visited nodes get lower weight
		recencyPenalty = outEdges.collect {|edge|
			var idx = history.indexOf(edge.to);
			if(idx.isNil) { 1.0 } {
				var recency = (history.size - idx) / history.size;
				1.0 - (recency * contrastBias)
			}
		};

		combined = weights * recencyPenalty;
		combined = combined.max(0.01); // floor to avoid zero

		// weighted random selection
		total = combined.sum;
		roll = total.rand;
		cumulative = 0;
		outEdges.do {|edge, i|
			cumulative = cumulative + combined[i];
			if(roll <= cumulative) { ^edge.to };
		};

		^outEdges.last.to
	}

	applyParamMap {|fromId, toId|
		var edge = graph.edgesFrom(fromId).detect {|e| e.to == toId };
		var fromNode, toNode;
		if(edge.notNil and: { edge.paramMap.notNil }) {
			fromNode = graph.nodes[fromId];
			toNode = graph.nodes[toId];
			edge.paramMap.keysValuesDo {|srcParam, dstParam|
				var val = fromNode.params[srcParam];
				if(val.notNil) {
					toNode.set(dstParam, val);
				};
			};
		};
	}

	stop {
		if(routine.notNil) { routine.stop };
		running = false;
		graph.events.add(AcEvent(\stopTraversal, id, nil));
	}
}