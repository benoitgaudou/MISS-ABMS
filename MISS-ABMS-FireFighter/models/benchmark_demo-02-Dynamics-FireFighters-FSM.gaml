model firemen

global { 
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
				
		create firefighter number: 10;				
	}
	
	reflex stop when: empty(plot where (each.state = 'fire')) {
		write "" + cycle;
		do pause;
	}
}

grid plot height:30 width: 30 neighbors:8 schedules: (plot where (each.state = 'fire')) {
	list<plot> neighbors <- self neighbors_at 1;
	string state <- "empty";
	rgb color <- #white;

	reflex diffuseFire when: (state = "fire") {
		ask (neighbors where (each.state = "forest")) {
			state <- "fire" ;
			color <- #red ;
		}
	}
}

species firefighter control: fsm {
	bool busy <- false;	
	plot my_plot;
	
	init {
		my_plot <- one_of(plot);
		location <- my_plot.location;
	}
	
	state patrolling initial: true {
		list<plot> burning_plots <-  my_plot.neighbors where (each.state = "fire"); 
		
		if(empty(burning_plots)) {
			my_plot <- one_of(my_plot.neighbors); 
		} else {
			my_plot <- one_of(burning_plots);
		}
		location <- my_plot.location;		
		
		transition to: extinguishing when: (my_plot.state = "fire") ;
	}
	
	state extinguishing {	
		ask my_plot {
			state <- "empty";
			color <- #lightblue;
		}
		
		transition to: patrolling when: (my_plot.state != "fire");		
	}
	
	aspect circle {
		 draw circle(50#m) color: #blue;
	}
}

experiment myFirstVizu type: gui {
	output {
		display vizu {
			grid plot border: #black;
			species firefighter aspect: circle;	
		}
	}	
}