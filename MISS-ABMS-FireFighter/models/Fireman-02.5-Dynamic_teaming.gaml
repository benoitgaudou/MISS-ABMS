model firemen

global { 
	
	float prop_forest <- 0.7 parameter:true;
	
	string scenario <- "individual" among: ["individual","communicating","teaming"] parameter:true; 
	int snb_fire <- 1 min:1 max:10 parameter:true;
	
	int nbf <- 10 min:4 max:50 parameter:true;
	int nbb <- 2 min:2 max:10 parameter:true;
	
	list<rgb> brigade_colors <- [#purple,#lime,#cyan,#slategray,#darkred,#peru,#plum,#gold,#pink,#black];
	
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
		
		switch scenario {
			match "communicating" {
				create communicant_firefighter number:nbf;
 				create brigade with:[members::list(communicant_firefighter)];
 				ask communicant_firefighter { crew <- first(brigade); }
			}
			match "teaming" {
				create communicant_firefighter number:nbf;
	 			create brigade number:min([nbb,nbf]) {color <- brigade_colors[int(self)]; }
	 			
	 			int brigade_id <- 0;
	 			ask communicant_firefighter {
	 				self.crew <- brigade[brigade_id];
	 				self.crew.members <+ self;
	 				brigade_id <- brigade_id = length(brigade) - 1 ? 0 : brigade_id+1;
	 			}
			}
			default {
				create firefighter number: nbf;
			}
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
	
	brigade crew;

	plot next_burning_plot_target {
		// Look around
		list<plot> burning_plots <- my_plot.neighbors where (each.state="fire");
		// If there is fire around go to any of them
		if not(empty(burning_plots)) { return any(burning_plots); }
		// Else ask collueages for know fire plots
		else { burning_plots <- crew.get_burning_places(); }
		// If none return no burning plot
		if empty(burning_plots) { return nil; }
		// If there is one, pick the closest ...
		plot target <- burning_plots closest_to self;
		// ... and choose the neighbore plots closest to it
		return my_plot.neighbors with_min_of (each distance_to target);
	}

	aspect circle {
		 draw circle(50#m) color: crew.color;
	}	
}

species brigade { 
	list<communicant_firefighter> members <- [];
	rgb color <- first(brigade_colors);
	list<plot> get_burning_places {
		return members accumulate (each.my_plot.neighbors where (each.state="fire"));
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
