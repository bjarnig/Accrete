AcScope {
	var <>graph, <>traversals, <>window, <>userView, <>routine;
	var <>nodePositions, <>refreshRate, <>width, <>height, <>margin;
	var <>nodeRadius, <>dragNode, <>dragOffset;

	// color palette
	classvar <>colorInactive, <>colorActive, <>colorEdge, <>colorTraversal, <>colorText, <>colorBg;

	*initClass {
		colorBg = Color.new255(23, 27, 33);           // #171b21
		colorInactive = Color.new255(110, 120, 145);
		colorActive = Color.new255(140, 225, 180);
		colorEdge = Color.new255(80, 88, 100);
		colorTraversal = Color.new255(255, 200, 80);
		colorText = Color.new255(220, 225, 235);
	}

	*new {|graph, traversals, width = 700, height = 700, refreshRate = 10|
		^super.newCopyArgs(
			graph,
			traversals ?? { [] },
			nil, nil, nil,
			IdentityDictionary.new,
			refreshRate, width, height, 60
		).init
	}

	init {
		nodeRadius = 20;
		this.layoutCircular;
	}

	// ---- layouts ----

	layoutCircular {
		var keys = graph.nodes.keys.asArray.sort;
		var cx = width * 0.5, cy = height * 0.5;
		var r = (width.min(height) * 0.5) - margin - nodeRadius;
		keys.do {|key, i|
			var angle = (i / keys.size) * 2pi - 0.5pi;
			nodePositions[key] = Point(
				cx + (r * cos(angle)),
				cy + (r * sin(angle))
			);
		};
	}

	layoutForce {|iterations = 80, repulsion = 50000, attraction = 0.01, damping = 0.9|
		var keys = graph.nodes.keys.asArray;
		var velocities = IdentityDictionary.new;
		var cx = width * 0.5, cy = height * 0.5;

		// seed positions randomly if not already placed
		keys.do {|key|
			if(nodePositions[key].isNil) {
				nodePositions[key] = Point(
					cx + rrand(-100.0, 100.0),
					cy + rrand(-100.0, 100.0)
				);
			};
			velocities[key] = Point(0, 0);
		};

		iterations.do {
			// repulsion between all node pairs
			keys.do {|a, i|
				keys.do {|b, j|
					if(j > i) {
						var pa = nodePositions[a], pb = nodePositions[b];
						var dx = pa.x - pb.x, dy = pa.y - pb.y;
						var dist = (dx.squared + dy.squared).max(1).sqrt;
						var force = repulsion / dist.squared;
						var fx = (dx / dist) * force;
						var fy = (dy / dist) * force;
						velocities[a] = Point(velocities[a].x + fx, velocities[a].y + fy);
						velocities[b] = Point(velocities[b].x - fx, velocities[b].y - fy);
					};
				};
			};

			// attraction along edges
			graph.edges.do {|edge|
				var pa = nodePositions[edge.from], pb = nodePositions[edge.to];
				if(pa.notNil and: { pb.notNil }) {
					var dx = pb.x - pa.x, dy = pb.y - pa.y;
					var dist = (dx.squared + dy.squared).max(1).sqrt;
					var force = attraction * dist * edge.weight;
					var fx = (dx / dist) * force;
					var fy = (dy / dist) * force;
					velocities[edge.from] = Point(
						velocities[edge.from].x + fx,
						velocities[edge.from].y + fy
					);
					velocities[edge.to] = Point(
						velocities[edge.to].x - fx,
						velocities[edge.to].y - fy
					);
				};
			};

			// gravity toward center
			keys.do {|key|
				var p = nodePositions[key];
				var dx = cx - p.x, dy = cy - p.y;
				velocities[key] = Point(
					velocities[key].x + (dx * 0.001),
					velocities[key].y + (dy * 0.001)
				);
			};

			// apply velocities
			keys.do {|key|
				var p = nodePositions[key], v = velocities[key];
				nodePositions[key] = Point(
					(p.x + v.x).clip(margin, width - margin),
					(p.y + v.y).clip(margin, height - margin)
				);
				velocities[key] = Point(v.x * damping, v.y * damping);
			};
		};
	}

	// place new nodes that have no position yet
	layoutNew {
		var unplaced = graph.nodes.keys.asArray.select {|k| nodePositions[k].isNil };
		if(unplaced.notEmpty) {
			unplaced.do {|key|
				// place near a neighbor if possible, else center
				var nb = graph.neighbors(key);
				var placed = nb.select {|n| nodePositions[n].notNil };
				if(placed.notEmpty) {
					var avg = placed.collect {|n| nodePositions[n] };
					var cx = avg.collect(_.x).mean + rrand(-40.0, 40.0);
					var cy = avg.collect(_.y).mean + rrand(-40.0, 40.0);
					nodePositions[key] = Point(
						cx.clip(margin, width - margin),
						cy.clip(margin, height - margin)
					);
				} {
					nodePositions[key] = Point(
						width * 0.5 + rrand(-80.0, 80.0),
						height * 0.5 + rrand(-80.0, 80.0)
					);
				};
			};
			// run a few force iterations to settle
			this.layoutForce(30);
		};
	}

	// ---- drawing ----

	open {
		if(window.notNil and: { window.isClosed.not }) { window.front; ^this };

		window = Window("AcScope", Rect(200, 200, width, height))
			.background_(colorBg)
			.onClose_({ this.stopRefresh });

		userView = UserView(window, Rect(0, 0, width, height))
			.background_(colorBg)
			.drawFunc_({|view| this.draw(view) })
			.mouseDownAction_({|view, x, y|
				this.onMouseDown(x, y);
			})
			.mouseMoveAction_({|view, x, y|
				this.onMouseDrag(x, y);
			})
			.mouseUpAction_({|view, x, y|
				dragNode = nil;
			});

		window.front;
		this.startRefresh;
	}

	draw {|view|
		this.layoutNew;
		this.drawEdges;
		this.drawTraversalPaths;
		this.drawNodes;
		this.drawInfo;
	}

	drawEdges {
		graph.edges.do {|edge|
			var pa = nodePositions[edge.from], pb = nodePositions[edge.to];
			if(pa.notNil and: { pb.notNil }) {
				var alpha = edge.weight.linlin(0, 1, 0.15, 0.7);
				var penW = edge.weight.linlin(0, 1, 0.5, 3.0);
				var edgeColor = this.edgeTypeColor(edge.type).alpha_(alpha);
				var mx, my, dx, dy, nx, ny, arrowLen, ax, ay;

				Pen.strokeColor = edgeColor;
				Pen.width = penW;
				Pen.moveTo(pa);
				Pen.lineTo(pb);
				Pen.stroke;

				// arrowhead
				dx = pb.x - pa.x;
				dy = pb.y - pa.y;
				mx = (dx.squared + dy.squared).sqrt.max(0.001);
				nx = dx / mx; ny = dy / mx;
				arrowLen = 8;
				ax = pb.x - (nx * (nodeRadius + 4));
				ay = pb.y - (ny * (nodeRadius + 4));

				Pen.fillColor = edgeColor;
				Pen.moveTo(Point(ax, ay));
				Pen.lineTo(Point(
					ax - (nx * arrowLen) + (ny * arrowLen * 0.4),
					ay - (ny * arrowLen) - (nx * arrowLen * 0.4)
				));
				Pen.lineTo(Point(
					ax - (nx * arrowLen) - (ny * arrowLen * 0.4),
					ay - (ny * arrowLen) + (nx * arrowLen * 0.4)
				));
				Pen.fill;
			};
		};
	}

	edgeTypeColor {|type|
		^switch(type,
			\succession,      Color.new255(120, 165, 210),
			\contrast,        Color.new255(210, 120, 120),
			\variation,       Color.new255(120, 210, 145),
			\transformation,  Color.new255(210, 185, 95),
			colorEdge
		)
	}

	drawTraversalPaths {
		traversals.do {|trav, i|
			if(trav.running and: { trav.currentNode.notNil }) {
				var pos = nodePositions[trav.currentNode];
				if(pos.notNil) {
					var pulse = (Main.elapsedTime * 3).sin.linlin(-1, 1, 0.4, 1.0);
					var r = nodeRadius + 8 + (i * 6);
					Pen.strokeColor = colorTraversal.alpha_(pulse);
					Pen.width = 2;
					Pen.addArc(pos, r, 0, 2pi);
					Pen.stroke;

					// label
					Pen.color = colorTraversal.alpha_(0.8);
					Pen.font = Font("Helvetica", 9);
					Pen.stringAtPoint(trav.id.asString, Point(pos.x + r + 2, pos.y - 5));
				};
			};
		};
	}

	drawNodes {
		graph.nodes.keysValuesDo {|key, node|
			var pos = nodePositions[key];
			if(pos.notNil) {
				var col, glow;

				if(node.active) {
					// active: bright, with glow proportional to activation count
					glow = node.activationCount.linlin(0, 10, 0.3, 0.8).min(0.8);
					col = colorActive;
					Pen.fillColor = col.alpha_(glow * 0.3);
					Pen.addArc(pos, nodeRadius + 6, 0, 2pi);
					Pen.fill;
				} {
					col = colorInactive;
				};

				// node circle
				Pen.fillColor = col;
				Pen.addArc(pos, nodeRadius, 0, 2pi);
				Pen.fill;

				// degree ring
				Pen.strokeColor = col.alpha_(0.4);
				Pen.width = graph.degree(key).linlin(0, 10, 0.5, 4.0).min(4);
				Pen.addArc(pos, nodeRadius, 0, 2pi);
				Pen.stroke;

				// label
				Pen.color = colorText;
				Pen.font = Font("Helvetica", 11, true);
				// center text roughly
				Pen.stringCenteredIn(
					key.asString,
					Rect(pos.x - nodeRadius, pos.y - 6, nodeRadius * 2, 12)
				);
			};
		};
	}

	drawInfo {
		var y = 8, str;
		Pen.font = Font("Helvetica", 10);
		Pen.color = colorText.alpha_(0.5);
		str = "% nodes  % edges  % active".format(
			graph.nodes.size, graph.edges.size, graph.activeNodes.size
		);
		Pen.stringAtPoint(str, Point(8, y));
	}

	// ---- interaction ----

	onMouseDown {|x, y|
		var click = Point(x, y);
		graph.nodes.keysValuesDo {|key, node|
			var pos = nodePositions[key];
			if(pos.notNil) {
				if(click.dist(pos) < nodeRadius) {
					dragNode = key;
					dragOffset = Point(pos.x - x, pos.y - y);
				};
			};
		};
	}

	onMouseDrag {|x, y|
		if(dragNode.notNil) {
			nodePositions[dragNode] = Point(
				(x + dragOffset.x).clip(margin, width - margin),
				(y + dragOffset.y).clip(margin, height - margin)
			);
			if(userView.notNil) { userView.refresh };
		};
	}

	// ---- refresh ----

	startRefresh {
		this.stopRefresh;
		routine = Routine({
			loop {
				{
					if(userView.notNil and: { window.notNil and: { window.isClosed.not } }) {
						userView.refresh;
					} {
						routine.stop;
					};
				}.defer;
				(1 / refreshRate).wait;
			}
		}).play(AppClock);
	}

	stopRefresh {
		if(routine.notNil) { routine.stop; routine = nil };
	}

	close {
		this.stopRefresh;
		if(window.notNil and: { window.isClosed.not }) { window.close };
	}
}