model firemen

global { 
	int scenario <- 1 among: [1,2]; // 0: without communication, 1: with communication
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
}

grid plot height:30 width: 30 neighbors:4 {
	list<plot> neighbors <- self neighbors_at 1;
	string state <- "empty";
	rgb color <- #white;
}

species firefighter {
	bool busy <- false;	
	plot my_plot;
	
	init {
		my_plot <- one_of(plot);
		location <- my_plot.location;
	}
	
	aspect circle {
		 draw circle(50#m) color: rnd_color(255);
	}
}

species communicant_firefighter parent:firefighter {
	list<communicant_firefighter> colleagues <- (communicant_firefighter - self);
}

experiment myFirstVizu type: gui {
	output {
		display vizu {
			grid plot border: #black;
			species firefighter aspect: circle;			
		}
	}	
}