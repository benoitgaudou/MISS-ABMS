model firemen

global { 
	int scenario <- 1 among: [1,2]; // 0: without communication, 1: with communication
	geometry shape <- square(3000#m);
	
	init {
		// plot (the name of the plot agent species) 
		// can also be used as the list of all the plot agents
		// length
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
}

grid plot height:30 width: 30 neighbors:4 {
	string state <- "clear" among: ["forest","clear","fire"];
	rgb color <- #white;
}

species firefighter {
	string status <- "patrolling" among: ["patrolling", "fighting fire"];		
	plot my_plot;
	
	init {
		my_plot <- one_of(plot);
		location <- my_plot.location;
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
