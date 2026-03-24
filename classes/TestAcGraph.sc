TestAcGraph : UnitTest {

	var graph, dummyFunc;

	setUp {
		graph = AcGraph();
		dummyFunc = { Silent.ar };
	}

	test_event_creation {
		var ev = AcEvent(\test, \target, \cause, (foo: 1));
		this.assertEquals(ev.type, \test, "event type");
		this.assertEquals(ev.target, \target, "event target");
		this.assertEquals(ev.cause, \cause, "event cause");
		this.assert(ev.timestamp > 0, "event has timestamp");
		this.assertEquals(ev.data[\foo], 1, "event data");
	}

	test_edge_creation {
		var e = AcEdge(\a, \b, 0.7, \contrast, Dictionary[\freq -> \freq], 0.1);
		this.assertEquals(e.from, \a, "edge from");
		this.assertEquals(e.to, \b, "edge to");
		this.assertFloatEquals(e.weight, 0.7, "edge weight");
		this.assertEquals(e.type, \contrast, "edge type");
		this.assertEquals(e.paramMap[\freq], \freq, "edge paramMap");
		this.assertFloatEquals(e.decayRate, 0.1, "edge decayRate");
	}

	test_edge_defaults {
		var e = AcEdge(\a, \b);
		this.assertFloatEquals(e.weight, 1.0, "default weight");
		this.assertEquals(e.type, \succession, "default type");
		this.assertFloatEquals(e.decayRate, 0.0, "default decayRate");
	}

	test_edge_decay {
		var e = AcEdge(\a, \b, 1.0, \succession, nil, 0.3);
		e.decay(1.0);
		this.assertFloatEquals(e.weight, 0.7, "weight after decay");
		e.decay(5.0);
		this.assertFloatEquals(e.weight, 0.0, "weight floors at 0");
	}

	test_node_creation {
		var n = AcNode(\test, dummyFunc, (freq: 440));
		this.assertEquals(n.id, \test, "node id");
		this.assertEquals(n.params[\freq], 440, "node params");
		this.assertEquals(n.channels, 2, "default channels");
		this.assertEquals(n.activationCount, 0, "initial activation count");
		this.assertEquals(n.active, false, "initially inactive");
	}

	test_node_set_while_inactive {
		var n = AcNode(\test, dummyFunc, (freq: 440));
		n.set(\freq, 880);
		this.assertEquals(n.params[\freq], 880, "param updated while inactive");
	}

	test_addNode {
		var node = graph.addNode(\n1, dummyFunc, (freq: 60));
		this.assertEquals(graph.nodes.size, 1, "graph has 1 node");
		this.assertEquals(graph.nodes[\n1].id, \n1, "node id matches");
		this.assert(graph.events.size > 0, "event logged");
		this.assertEquals(graph.events.last.type, \addNode, "addNode event");
	}

	test_addNode_multiple {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.addNode(\n3, dummyFunc);
		this.assertEquals(graph.nodes.size, 3, "graph has 3 nodes");
	}

	test_removeNode {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.connect(\n1, \n2);
		graph.removeNode(\n1);
		this.assertEquals(graph.nodes.size, 1, "node removed");
		this.assertEquals(graph.edges.size, 0, "edges involving removed node cleaned up");
	}

	test_removeNode_nonexistent {
		graph.removeNode(\doesNotExist);
		this.assertEquals(graph.nodes.size, 0, "no crash on removing nonexistent node");
	}

	test_connect {
		var edge;
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		edge = graph.connect(\n1, \n2, 0.7, \contrast);
		this.assertEquals(graph.edges.size, 1, "one edge");
		this.assertEquals(edge.from, \n1, "edge from");
		this.assertEquals(edge.to, \n2, "edge to");
		this.assertFloatEquals(edge.weight, 0.7, "edge weight");
		this.assertEquals(edge.type, \contrast, "edge type");
	}

	test_connect_with_paramMap {
		var pm;
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		pm = Dictionary[\freq -> \rate];
		graph.connect(\n1, \n2, 0.5, \transformation, pm);
		this.assertEquals(graph.edges[0].paramMap[\freq], \rate, "paramMap preserved");
	}

	test_disconnect {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.connect(\n1, \n2);
		graph.connect(\n2, \n1);
		graph.disconnect(\n1, \n2);
		this.assertEquals(graph.edges.size, 1, "one edge removed");
		this.assertEquals(graph.edges[0].from, \n2, "correct edge remains");
	}

	test_edgesFrom {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.addNode(\n3, dummyFunc);
		graph.connect(\n1, \n2);
		graph.connect(\n1, \n3);
		graph.connect(\n2, \n3);
		this.assertEquals(graph.edgesFrom(\n1).size, 2, "n1 has 2 outgoing edges");
		this.assertEquals(graph.edgesFrom(\n2).size, 1, "n2 has 1 outgoing edge");
		this.assertEquals(graph.edgesFrom(\n3).size, 0, "n3 has 0 outgoing edges");
	}

	test_edgesTo {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.addNode(\n3, dummyFunc);
		graph.connect(\n1, \n3);
		graph.connect(\n2, \n3);
		this.assertEquals(graph.edgesTo(\n3).size, 2, "n3 has 2 incoming edges");
		this.assertEquals(graph.edgesTo(\n1).size, 0, "n1 has 0 incoming edges");
	}

	test_degree {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.addNode(\n3, dummyFunc);
		graph.connect(\n1, \n2);
		graph.connect(\n2, \n3);
		graph.connect(\n3, \n1);
		this.assertEquals(graph.degree(\n1), 2, "n1 degree = 2 (1 out + 1 in)");
		this.assertEquals(graph.degree(\n2), 2, "n2 degree = 2");
	}

	test_neighbors {
		var nb;
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.addNode(\n3, dummyFunc);
		graph.connect(\n1, \n2);
		graph.connect(\n3, \n1);
		nb = graph.neighbors(\n1);
		this.assertEquals(nb.size, 2, "n1 has 2 neighbors");
		this.assert(nb.includesEqual(\n2), "n2 is neighbor of n1");
		this.assert(nb.includesEqual(\n3), "n3 is neighbor of n1");
	}

	test_eventLog_records_all_operations {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.connect(\n1, \n2);
		graph.disconnect(\n1, \n2);
		graph.removeNode(\n2);
		this.assertEquals(graph.events.size, 5, "all operations logged");
	}

	test_eventLog_types {
		var types;
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.connect(\n1, \n2);
		types = graph.events.collect(_.type);
		this.assert(types.includesEqual(\addNode), "has addNode event");
		this.assert(types.includesEqual(\connect), "has connect event");
	}

	test_triangle_graph {
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.addNode(\c, dummyFunc);
		graph.connect(\a, \b, 0.7, \succession);
		graph.connect(\b, \c, 0.5, \contrast);
		graph.connect(\c, \a, 0.3, \variation);
		this.assertEquals(graph.nodes.size, 3, "triangle has 3 nodes");
		this.assertEquals(graph.edges.size, 3, "triangle has 3 edges");
		this.assertEquals(graph.neighbors(\a).size, 2, "each node has 2 neighbors");
		this.assertEquals(graph.neighbors(\b).size, 2, "each node has 2 neighbors");
		this.assertEquals(graph.neighbors(\c).size, 2, "each node has 2 neighbors");
	}

	test_star_graph {
		graph.addNode(\center, dummyFunc);
		5.do {|i|
			var id = ("leaf" ++ i).asSymbol;
			graph.addNode(id, dummyFunc);
			graph.connect(\center, id);
		};
		this.assertEquals(graph.nodes.size, 6, "star has 6 nodes");
		this.assertEquals(graph.edges.size, 5, "star has 5 edges");
		this.assertEquals(graph.degree(\center), 5, "center degree = 5");
	}

	test_chain_graph {
		var ids = [\a, \b, \c, \d, \e];
		ids.do {|id| graph.addNode(id, dummyFunc) };
		(ids.size - 1).do {|i|
			graph.connect(ids[i], ids[i + 1], 1.0 - (i * 0.2));
		};
		this.assertEquals(graph.edges.size, 4, "chain has n-1 edges");
		this.assertFloatEquals(graph.edges[0].weight, 1.0, "first edge weight");
		this.assertFloatEquals(graph.edges[3].weight, 0.4, "last edge weight");
	}

	test_bidirectional_edges {
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.connect(\a, \b, 0.8);
		graph.connect(\b, \a, 0.3);
		this.assertEquals(graph.edges.size, 2, "two directed edges");
		this.assertEquals(graph.edgesFrom(\a).size, 1, "a->b");
		this.assertEquals(graph.edgesFrom(\b).size, 1, "b->a");
		this.assertFloatEquals(graph.edgesFrom(\a)[0].weight, 0.8, "a->b weight");
		this.assertFloatEquals(graph.edgesFrom(\b)[0].weight, 0.3, "b->a weight");
	}
}

TestAcGrowth : UnitTest {

	var graph, dummyFunc;

	setUp {
		graph = AcGraph();
		dummyFunc = { Silent.ar };
	}

	test_preferentialAttachment_empty_graph {
		var node = AcGrowth.preferentialAttachment(graph, \first, dummyFunc);
		this.assertEquals(graph.nodes.size, 1, "one node added");
		this.assertEquals(graph.edges.size, 0, "no edges on empty graph");
	}

	test_preferentialAttachment_connects {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		graph.connect(\n1, \n2);
		AcGrowth.preferentialAttachment(graph, \n3, dummyFunc, nil, 2);
		this.assertEquals(graph.nodes.size, 3, "3 nodes total");
		this.assert(graph.edges.size > 1, "new edges created");
	}

	test_preferentialAttachment_prefers_high_degree {
		var hubEdgesBefore, hubEdgesAfter;
		graph.addNode(\hub, dummyFunc);
		5.do {|i|
			var id = ("spoke" ++ i).asSymbol;
			graph.addNode(id, dummyFunc);
			graph.connect(\hub, id);
			graph.connect(id, \hub);
		};
		hubEdgesBefore = graph.degree(\hub);
		10.do {|i|
			AcGrowth.preferentialAttachment(graph, ("new" ++ i).asSymbol, dummyFunc, nil, 1);
		};
		hubEdgesAfter = graph.degree(\hub);
		this.assert(hubEdgesAfter > hubEdgesBefore, "hub gained edges via preferential attachment");
	}

	test_randomAttachment {
		graph.addNode(\n1, dummyFunc);
		graph.addNode(\n2, dummyFunc);
		AcGrowth.randomAttachment(graph, \n3, dummyFunc, nil, 2);
		this.assertEquals(graph.nodes.size, 3, "3 nodes");
		this.assert(graph.edges.size >= 2, "at least 2 new edges");
	}

	test_randomAttachment_respects_numEdges {
		var newEdges;
		5.do {|i| graph.addNode(("n" ++ i).asSymbol, dummyFunc) };
		AcGrowth.randomAttachment(graph, \new, dummyFunc, nil, 3);
		newEdges = graph.edgesFrom(\new);
		this.assertEquals(newEdges.size, 3, "exactly numEdges edges created");
	}

	test_smallWorldRewire {
		var ids, originalTargets, newTargets;
		ids = (0..4).collect {|i| ("n" ++ i).asSymbol };
		ids.do {|id| graph.addNode(id, dummyFunc) };
		ids.size.do {|i|
			graph.connect(ids[i], ids[(i + 1) % ids.size]);
		};
		originalTargets = graph.edges.collect(_.to);
		AcGrowth.smallWorldRewire(graph, 1.0);
		newTargets = graph.edges.collect(_.to);
		this.assertEquals(graph.edges.size, 5, "same number of edges");
		this.assert(newTargets != originalTargets, "some edges rewired");
	}

	test_decayEdges {
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.addNode(\c, dummyFunc);
		graph.connect(\a, \b, 0.5, \succession, nil, 0.3);
		graph.connect(\b, \c, 1.0, \succession, nil, 0.0);
		AcGrowth.decayEdges(graph, 2.0);
		this.assertEquals(graph.edges.size, 1, "decayed edge removed");
		this.assertEquals(graph.edges[0].from, \b, "surviving edge is b->c");
	}

	test_growth_logs_events {
		var growthEvents;
		AcGrowth.preferentialAttachment(graph, \n1, dummyFunc);
		growthEvents = graph.events.select {|e| e.type == \growth };
		this.assert(growthEvents.size > 0, "growth events logged");
	}
}

TestAcTraversal : UnitTest {

	var graph, dummyFunc;

	setUp {
		graph = AcGraph();
		dummyFunc = { Silent.ar };
	}

	test_traversal_creation {
		var t = AcTraversal(\t1, graph, { 1.0 });
		this.assertEquals(t.id, \t1, "traversal id");
		this.assertEquals(t.running, false, "not running initially");
		this.assertEquals(t.history.size, 0, "empty history");
	}

	test_chooseNext_returns_nil_for_no_edges {
		var t, next;
		graph.addNode(\solo, dummyFunc);
		t = AcTraversal(\t1, graph);
		next = t.chooseNext(\solo);
		this.assertEquals(next, nil, "nil when no outgoing edges");
	}

	test_chooseNext_returns_valid_neighbor {
		var t, next;
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.addNode(\c, dummyFunc);
		graph.connect(\a, \b, 0.5);
		graph.connect(\a, \c, 0.5);
		t = AcTraversal(\t1, graph);
		next = t.chooseNext(\a);
		this.assert([\b, \c].includesEqual(next), "chooses a valid neighbor");
	}

	test_chooseNext_respects_weights {
		var t, counts;
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.addNode(\c, dummyFunc);
		graph.connect(\a, \b, 100.0);
		graph.connect(\a, \c, 0.001);
		t = AcTraversal(\t1, graph);
		counts = Dictionary[\b -> 0, \c -> 0];
		100.do {
			var next;
			next = t.chooseNext(\a);
			counts[next] = counts[next] + 1;
		};
		this.assert(counts[\b] > 80, "heavily weighted edge chosen most often");
	}

	test_chooseNext_recency_bias {
		var t, counts;
		graph.addNode(\a, dummyFunc);
		graph.addNode(\b, dummyFunc);
		graph.addNode(\c, dummyFunc);
		graph.connect(\a, \b, 0.5);
		graph.connect(\a, \c, 0.5);
		t = AcTraversal(\t1, graph, contrastBias: 0.9);
		10.do { t.history.add(\b) };
		counts = Dictionary[\b -> 0, \c -> 0];
		100.do {
			var next;
			next = t.chooseNext(\a);
			counts[next] = counts[next] + 1;
		};
		this.assert(counts[\c] > counts[\b], "recently visited node chosen less often");
	}

	test_applyParamMap {
		var t;
		graph.addNode(\a, dummyFunc, (freq: 440));
		graph.addNode(\b, dummyFunc, (rate: 0));
		graph.connect(\a, \b, 1.0, \succession, Dictionary[\freq -> \rate]);
		t = AcTraversal(\t1, graph);
		t.applyParamMap(\a, \b);
		this.assertEquals(graph.nodes[\b].params[\rate], 440, "param mapped from a.freq to b.rate");
	}

	test_maxHistory_limit {
		var t;
		graph.addNode(\a, dummyFunc);
		t = AcTraversal(\t1, graph, maxHistory: 4);
		10.do {|i| t.history.add(("n" ++ i).asSymbol) };
		while { t.history.size > t.maxHistory } { t.history.removeAt(0) };
		this.assertEquals(t.history.size, 4, "history capped at maxHistory");
	}

	test_multiple_traversals_independent {
		var t1, t2;
		t1 = AcTraversal(\walk1, graph, { 1.0 });
		t2 = AcTraversal(\walk2, graph, { 2.0 });
		t1.history.add(\a);
		t2.history.add(\b);
		this.assert(t1.history[0] != t2.history[0], "traversals have independent histories");
	}
}