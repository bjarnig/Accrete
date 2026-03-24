AcTraversal {
	var <>id, <>graph, <>durFunc, <>fadeTime, <>contrastBias, <>deactivateOnLeave, <>maxHistory;
	var <>routine, <>history, <>currentNode, <>running;
	var <>transitions;

	*new {|id, graph, durFunc, fadeTime = 2, contrastBias = 0.5, deactivateOnLeave = true, maxHistory = 16|
		^super.newCopyArgs(
			id, graph, durFunc ?? {{ rrand(4.0, 8.0) }},
			fadeTime, contrastBias, deactivateOnLeave, maxHistory
		).init
	}

	init {
		history = List.new;
		running = false;
		transitions = IdentityDictionary.new;
		this.initDefaultTransitions;
	}

	initDefaultTransitions {

		transitions[\succession] = {|from, to, edge, trav|
			var dur = trav.fadeTime;
			to.activate(trav.graph.nodeBus, dur);
			trav.interpolateParams(from, to, edge, dur);
			if(trav.deactivateOnLeave) {
				from.deactivate(dur);
			};
			dur.wait;
		};

		transitions[\contrast] = {|from, to, edge, trav|
			var gap = trav.fadeTime * 0.25;
			if(trav.deactivateOnLeave) {
				from.deactivate(gap);
			};
			gap.wait;
			(gap * rrand(0.5, 2.0)).wait;
			to.activate(trav.graph.nodeBus, gap);
			gap.wait;
		};

		transitions[\variation] = {|from, to, edge, trav|
			var dur = trav.fadeTime * 2;
			to.activate(trav.graph.nodeBus, dur);
			trav.morphParams(from, to, edge, dur * 0.7);
			(dur * 0.3).wait;
			if(trav.deactivateOnLeave) {
				from.deactivate(dur);
			};
			dur.wait;
		};

		transitions[\transformation] = {|from, to, edge, trav|
			var dur = trav.fadeTime * 3;
			var halfDur = dur * 0.5;
			to.activate(trav.graph.nodeBus, dur);
			trav.interpolateParams(from, to, edge, dur, 40);
			if(trav.deactivateOnLeave) {
				halfDur.wait;
				from.deactivate(halfDur);
				halfDur.wait;
			} {
				dur.wait;
			};
		};
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
					if(node.active.not) {
						node.activate(graph.nodeBus, fadeTime);
					};
					graph.events.add(AcEvent(\activate, currentNode, id, (traversal: id)));
					history.add(currentNode);
					if(history.size > maxHistory) { history.removeAt(0) };

					durFunc.value(currentNode, node).wait;

					currentNode = this.chooseNext(currentNode);
					if(currentNode.isNil) {
						"AcTraversal(%): no edges from %, stopping".format(id, history.last).warn;
						running = false;
						nil
					} {
						this.doTransition(node, graph.nodes[currentNode],
							graph.edgesFrom(node.id).detect {|e| e.to == currentNode }
						);
						graph.events.add(AcEvent(\transition, currentNode, id,
							(from: node.id, type: graph.edgesFrom(node.id).detect {|e| e.to == currentNode }.type)
						));
					}
				}
			}
		}).play;
	}

	doTransition {|fromNode, toNode, edge|
		var transFn;

		if(toNode.isNil) { ^this };

		transFn = if(edge.notNil and: { edge.transition.notNil }) {
			edge.transition
		} {
			transitions[edge.type] ?? { transitions[\succession] }
		};

		transFn.value(fromNode, toNode, edge, this);
	}

	interpolateParams {|fromNode, toNode, edge, dur, steps = 20|
		var stepDur, startVals;
		if(edge.isNil or: { edge.paramMap.isNil } or: { edge.paramMap.isEmpty }) { ^this };

		stepDur = dur / steps;
		startVals = Dictionary.new;

		edge.paramMap.keysValuesDo {|srcParam, dstParam|
			startVals[dstParam] = toNode.params[dstParam];
		};

		fork {
			steps.do {|i|
				var frac = (i + 1) / steps;
				edge.paramMap.keysValuesDo {|srcParam, dstParam|
					var srcVal = fromNode.params[srcParam];
					var startVal = startVals[dstParam];
					if(srcVal.notNil and: { startVal.notNil } and: { srcVal.isNumber } and: { startVal.isNumber }) {
						toNode.set(dstParam, startVal + ((srcVal - startVal) * frac));
					};
				};
				stepDur.wait;
			};
		};
	}

	morphParams {|fromNode, toNode, edge, dur, steps = 20|
		var stepDur, startVals, sharedKeys;
		stepDur = dur / steps;

		sharedKeys = fromNode.params.keys.asArray.select {|k|
			toNode.params[k].notNil and: { fromNode.params[k].isNumber } and: { toNode.params[k].isNumber }
		};

		if(sharedKeys.isEmpty) { ^this };

		startVals = Dictionary.new;
		sharedKeys.do {|k| startVals[k] = fromNode.params[k] };

		fork {
			steps.do {|i|
				var frac = (i + 1) / steps;
				sharedKeys.do {|k|
					var target = toNode.params[k];
					var start = startVals[k];
					fromNode.set(k, start + ((target - start) * frac));
				};
				stepDur.wait;
			};
		};
	}

	chooseNext {|fromId|
		var outEdges = graph.edgesFrom(fromId);
		var weights, recencyPenalty, combined, total, roll, cumulative;
		if(outEdges.isEmpty) { ^nil };

		weights = outEdges.collect(_.weight);

		recencyPenalty = outEdges.collect {|edge|
			var idx = history.indexOf(edge.to);
			if(idx.isNil) { 1.0 } {
				var recency = (history.size - idx) / history.size;
				1.0 - (recency * contrastBias)
			}
		};

		combined = weights * recencyPenalty;
		combined = combined.max(0.01);

		total = combined.sum;
		roll = total.rand;
		cumulative = 0;
		outEdges.do {|edge, i|
			cumulative = cumulative + combined[i];
			if(roll <= cumulative) { ^edge.to };
		};

		^outEdges.last.to
	}

	stop {
		if(routine.notNil) { routine.stop };
		running = false;
		graph.events.add(AcEvent(\stopTraversal, id, nil));
	}
}