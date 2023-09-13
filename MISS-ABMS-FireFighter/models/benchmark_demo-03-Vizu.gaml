model firemen

global { 
	int scenario <- 2 among: [1,2]; // 0: without communication, 1: with communication
	geometry shape <- rectangle(3000#m, 3000#m);
	
	float rateForest <- (plot count(each.state = "forest"))/ length(plot)
		update: (plot count(each.state = "forest"))/ length(plot);
	
	init {
		ask ((length(plot)/2) among plot) {
			state <- "forest";
			color <- #green;
		}

		ask one_of(plot) {
			state <- "fire";
			color <- #red;
		}
				
		if(scenario = 1){
			create firefighter number: 10;				
 		} else {
 			create communicant_firefighter number:10;
 		}
	}
	
	reflex stop when: empty(plot where (each.state = 'fire')) {
		write "" + cycle;
		do pause;
	}
}

grid plot height:30 width: 30 neighbors:8 schedules: (plot where (each.state = "fire")){
	list<plot> neighbors <- self neighbors_at 1;
	string state <- "empty";
	rgb color <- #white;			
	
	int h <- rnd(200);
	
	reflex diffuseFire when: (state = "fire") {
		ask (neighbors where (each.state = "forest")) {
			state <- "fire";
			color <- #red;
		}
	}
	
	aspect viewGif {
		if(state = "forest") {
			draw shape color: #green border: #black;
		} else if (state = "fire") {
			draw image_file("../includes/fire2.gif") size: shape.width;
		}
	}	
	
	aspect view3D {
		if(state = "forest") {
			draw cylinder(50#m, h) color: #green;
		} else if (state = "fire") {
			draw square(50#m) depth: h color: #red;
		}
	}
}

species firefighter {
	bool busy <- false;	
	plot my_plot;
	
	init {
		my_plot <- one_of(plot);
		location <- my_plot.location;
	}
	
	reflex patrolling {
		list<plot> burning_plots <- (my_plot.neighbors where (each.state = "fire"));
		
		if empty(burning_plots) {
			my_plot <- one_of(my_plot.neighbors);
		} else {
			my_plot <- one_of(burning_plots);
		}
		
		location <- my_plot.location;
	}
	
	reflex extinguishing when: my_plot.state = "fire"{
		ask my_plot {
			state <- "empty";
			color <- #lightblue;
		}
	}
	
	aspect circle {
		 draw circle(50#m) color: #blue;
	}
	
	aspect triangle {
		draw triangle(50#m) color: #purple;
	}

	aspect sorted {
		draw circle(50#m) 
			at: (empty(my_plot.neighbors where(each.state = "fire") )? 
				{50+int(self)*50,50} : 
				{500-int(self)*50,800} ) 
			color: #darkblue;
	}
	
	aspect view3D {
		draw pyramid(100#m) color: #blue;
		draw sphere(25#m) at: {location.x,location.y,100#m} color: #blue;
	}
}

species communicant_firefighter parent:firefighter {
	list<communicant_firefighter> colleagues <- (communicant_firefighter - self);
	
	reflex patrolling {
		list<plot> burning_plots <- (my_plot.neighbors where (each.state = "fire"));

		if(empty(burning_plots)) {
			busy <- false;
			list<communicant_firefighter> c_needing_help <- colleagues where (each.busy = true);
			
			if(empty(c_needing_help)) {
				my_plot <- one_of(my_plot.neighbors);
			} else {
				// find the closest ff
				communicant_firefighter cff <- c_needing_help with_min_of (each distance_to self);
				//find the plot in neigh the closest to it
				my_plot <- my_plot.neighbors closest_to cff;				
			}
		} else {
			busy <- true;
			my_plot <- one_of(burning_plots);			
		}
		location <- my_plot.location;		
	}
	aspect circle {
		 draw circle(50#m) color: #darkblue;
	}	
	
	aspect sorted {
		draw circle(50#m) at: ((busy)? {50+int(self)*50,50} : {500-int(self)*50,800}) color: #darkblue;
	}
}

experiment vlVizu type: gui {
	parameter "Scenario number" var: scenario <- 1;
	
	output {
		display vizu {
			grid plot border: #black;
			species firefighter aspect: circle;			
			species communicant_firefighter aspect: circle;						
		}
		
		display vizuTriangle {
			species plot aspect: viewGif;
			species firefighter aspect: triangle;			
			species communicant_firefighter aspect: triangle;						
		}
		
		display vueSorted {
			species firefighter aspect: sorted;						
			species communicant_firefighter aspect: sorted;
		}
		
		display my_plot {
			chart "my_first_chart" type: series {
				data "rate of clear plots" value: (plot count (each.state = "empty"))/length(plot) color: #blue;
				data "rate of fire plots" value: (plot count (each.state = "fire"))/length(plot) color: #red;
				data "rate of forest plots" value: (plot count (each.state = "forest"))/length(plot) color: #green;				
			}
		}
		
		display my_pie {
			chart "my_first_pie" type: pie {
				data "rate of clear plots" value: (plot count (each.state = "empty"))/length(plot) color: #blue;
				data "rate of fire plots" value: (plot count (each.state = "fire"))/length(plot) color: #red;
				data "rate of forest plots" value: (plot count (each.state = "forest"))/length(plot) color: #green;								
			}
		}
	}	
}

experiment funVizu type: gui {	
	output {
		display vizu type: opengl {
			species plot aspect: view3D;
			species firefighter aspect: view3D;			
			species communicant_firefighter aspect: view3D;						
		}
		
	}	
}

experiment expWithoutParam type: gui {
	output {
		display vizuTriangle {
			grid plot border: #green;
			species communicant_firefighter aspect: triangle;						
		}
	}		
}

experiment explo type: batch until: empty(plot where (each.state = 'fire')) repeat: 10 {
	parameter "scenario" var: scenario;
	
	method exploration;
	
	int cpt <- 0;
	action _step_ {
		// scenario, replication, rateForest, cycle
		write "OK";
		save [scenario, cpt mod 10, rateForest, cycle] to: "firefighter.csv" type:"csv";
		cpt <- cpt + 1;
	}
	
	permanent {
		display forest {
			chart "forest" type: series {
				data "rate of forest plots" value: rateForest color: #green;				
			}
		}
		display step {
			chart "step" type: series {
				data "rate of forest plots" value: cycle color: #green;				
			}
		}
	}
}



