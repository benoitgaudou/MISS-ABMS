model firemen

global { 
	
	float prop_forest <- 0.7;
	
	int scenario <- 1 among: [1,2] parameter:true; // 0: without communication, 1: with communication
	int snb_fire <- 1 min:1 max:10 parameter:true;
	geometry shape <- square(3000#m);
	
	init {
		// plot (the name of the plot agent species) 
		// can also be used as the list of all the plot agents
		// length
		ask ((length(plot)*prop_forest) among plot) {
			state <- "forest";
			color <- #green;
		}

		ask snb_fire among plot {
			state <- "fire";
			color <- #red;
		}
				
		if(scenario = 1){
			create firefighter number: 10;				
 		} else {
 			create communicant_firefighter number:10;
 		}
	}	
}

grid plot height:30 width: 30 neighbors:4 schedules:plot where (each.state="fire") {
	string state <- "clear" among: ["forest","clear","fire"];
	rgb color <- #white;
	
	// Spread the fire
	reflex fireSpreading {
		ask neighbors where (each.state="forest") { state<-"fire"; color<-#red; }
	}
	
	bool isEmpty { return empty(firefighter overlapping self); }
}

species firefighter skills:[moving] {
	string status <- "patrolling" among: ["patrolling", "fighting fire"];		
	
	plot my_plot;
	
	init {
		my_plot <- one_of(plot where each.isEmpty());
		location <- my_plot.location;
	}
	
	reflex patrol when:status = "patrolling" {
		
		// Move to the next patrolling plot
		plot target_plot <- next_burning_plot_target();
		
		// If no patrol plot target, move randomly
		if target_plot=nil {
			list<plot> empty_plots <- my_plot.neighbors where each.isEmpty();  
			target_plot <- empty(empty_plots) ? my_plot : any(empty_plots);
		}
		
		// Change current plot
		my_plot <- target_plot;
		// Update actual position
		location <- my_plot.location;
		
		// If current plot is on fire then move to "fighting fire" status
		if my_plot.state="fire" {status <- "fighting fire";}
		
	}
	
	reflex extinguishFire when:status = "fighting fire" {
		
		ask my_plot {state <- "clear"; color <- #white;}
		status <- "patrolling";
		
	} 
	
	/*
	 * The action to choose a target burning plot
	 */
	plot next_burning_plot_target {
		return one_of( my_plot.neighbors where (each.state="fire") );
	}
	
	aspect circle {
		 draw circle(50#m) color: #blue;
	}	
}

species communicant_firefighter parent:firefighter {
	
	list<communicant_firefighter> colleagues  <- (communicant_firefighter - self);

	plot next_burning_plot_target {
		// Look around
		list<plot> burning_plots <- my_plot.neighbors where (each.state="fire");
		// If there is fire around go to any of them
		if not(empty(burning_plots)) { return any(burning_plots); }
		// Else ask colleagues if any fire surround them
		else { burning_plots <- colleagues accumulate (each.my_plot.neighbors where (each.state="fire")); }
		// If none return a burning plot, don't worry stop happy
		if empty(burning_plots) { return nil; }
		// If there is at least one, pick the closest ...
		plot target <- burning_plots closest_to self;
		// ... and choose the closest plot to this fire among the neighboor plots
		return my_plot.neighbors with_min_of (each distance_to target);
	}

	aspect circle {
		 draw circle(50#m) color: #purple;
	}	
}

species brigade { list<communicant_firefighter> members; }


experiment myFirstVizu type: gui {
	parameter "Scenario" var: scenario <- 1;
	
	output {
		display vizu {
			grid plot border: #black;
			species firefighter aspect: circle;		
			species communicant_firefighter aspect: circle;					
		}
	}	
}
