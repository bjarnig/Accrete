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

	// default transitions per edge type

	initDefaultTransitions {

		// succession: smooth crossfade with gradual param interpolation
		transitions[\succession] = {|from, to, edge, trav|
			var dur = trav.fadeTime;
			// start new node fading in
			to.activate(trav.graph.nodeBus, dur);
			// interpolate params over the fade duration
			trav.interpolateParams(from, to, edge, dur);
			// fade out old node alongside
			if(trav.deactivateOnLeave) {
				from.deactivate(dur);
			};
			// wait for crossfade to complete
			dur.wait;
		};

		// contrast: quick cut, brief silence, then new node
		transitions[\contrast] = {|from, to, edge, trav|
			var gap = trav.fadeTime * 0.25;
			// cut the old node fast
			if(trav.deactivateOnLeave) {
				from.deactivate(gap);
			};
			// silence gap
			gap.wait;
			(gap * rrand(0.5, 2.0)).wait;
			// new node enters abruptly
			to.activate(trav.graph.nodeBus, gap);
			gap.wait;
		};

		// variation: long overlap — old node morphs params, both ring together
		transitions[\variation] = {|from, to, edge, trav|
			var dur = trav.fadeTime * 2;
			// activate new alongside old
			to.activate(trav.graph.nodeBus, dur);
			// morph old node's params toward new node's values
			trav.morphParams(from, to, edge, dur * 0.7);
			// keep both alive for the overlap
			(dur * 0.3).wait;
			// then fade old
			if(trav.deactivateOnLeave) {
				from.deactivate(dur);
			};
			dur.wait;
		};

		// transformation: long simultaneous crossfade with full param sweep
		transitions[\transformation] = {|from, to, edge, trav|
			var dur = trav.fadeTime * 3;
			var halfDur = dur * 0.5;
			// new node fades in slowly
			to.activate(trav.graph.nodeBus, dur);
			// sweep mapped params from source to target over the full duration
			trav.interpolateParams(from, to, edge, dur, 40);
			// old node fades out over second half
			if(trav.deactivateOnLeave) {
				halfDur.wait;
				from.deactivate(halfDur);
				halfDur.wait;
			} {
				dur.wait;
			};
		};
	}

	// walking

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
					// activate first node directly (no transition on entry)
					if(node.active.not) {
						node.activate(graph.nodeBus, fadeTime);
					};
					graph.events.add(AcEvent(\activate, currentNode, id, (traversal: id)));
					history.add(currentNode);
					if(history.size > maxHistory) { history.removeAt(0) };

					// dwell at current node
					durFunc.value(currentNode, node).wait;

					// choose next
					currentNode = this.chooseNext(currentNode);
					if(currentNode.isNil) {
						"AcTraversal(%): no edges from %, stopping".format(id, history.last).warn;
						running = false;
						nil
					} {
						// execute transition
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

		// priority: edge-specific transition > type default > simple fallback
		transFn = if(edge.notNil and: { edge.transition.notNil }) {
			edge.transition
		} {
			transitions[edge.type] ?? { transitions[\succession] }
		};

		transFn.value(fromNode, toNode, edge, this);
	}

	// parameter interpolation

	// interpolateParams: apply paramMap from edge, interpolating over duration
	// source param value → target param, gradually over `steps` increments
	interpolateParams {|fromNode, toNode, edge, dur, steps = 20|
		var stepDur, startVals;
		if(edge.isNil or: { edge.paramMap.isNil } or: { edge.paramMap.isEmpty }) { ^this };

		stepDur = dur / steps;
		startVals = Dictionary.new;

		// capture start values on the target node
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

	// morphParams: morph the OLD node's params toward the NEW node's values
	// creates an evolving "goodbye" — the departing node drifts toward the incoming one
	morphParams {|fromNode, toNode, edge, dur, steps = 20|
		var stepDur, startVals, sharedKeys;
		stepDur = dur / steps;

		// find params that both nodes share
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

	// edge selection

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

	// lifecycle

	stop {
		if(routine.notNil) { routine.stop };
		running = false;
		graph.events.add(AcEvent(\stopTraversal, id, nil));
	}
}