model firemen

global { 
	
	float prop_forest <- 1.0;
	
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
		
		list<plot> burning_plots <- my_plot.neighbors where (each.state="fire");
		// If no fire on sight move toward any neighboring places
		if empty(burning_plots) { my_plot <- one_of(my_plot.neighbors where each.isEmpty()); }
		// Else move toward fire on sight
		else { my_plot <- one_of(burning_plots); }
		
		// Update current position
		location <- my_plot.location;
		// If current position is on fire then move to "fighting fire" status
		if my_plot.state="fire" {status <- "fighting fire";}
		
	}
	
	reflex extinguishFire when:status = "fighting fire" {
		
		ask my_plot {state <- "clear"; color <- #white;}
		status <- "patrolling";
		
	} 
	
	aspect circle {
		 draw circle(50#m) color: #blue;
	}	
}

species communicant_firefighter parent:firefighter {
	list<communicant_firefighter> colleagues  <- (communicant_firefighter - self);

	aspect circle {
		 draw circle(50#m) color: #purple;
	}	
}

species brigade {
	list<firefighter> members <- list(firefighter);
}


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
