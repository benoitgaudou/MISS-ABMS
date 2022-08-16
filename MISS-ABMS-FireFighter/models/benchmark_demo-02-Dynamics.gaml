model firemen

global { 
	int scenario <- 2 among: [1,2]; // 0: without communication, 1: with communication
	geometry shape <- rectangle(3000#m, 3000#m);
	
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
	
	reflex diffuseFire when: (state = "fire") {
		ask (neighbors where (each.state = "forest")) {
			state <- "fire";
			color <- #red;
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
}

experiment myFirstVizu type: gui {
	output {
		display vizu {
			grid plot border: #black;
			species firefighter aspect: circle;			
			species communicant_firefighter aspect: circle;						
		}
	}	
}