model Firespread

global {
	
	// INPUTS
	float communicating <- 1.0;
	
	float proportion_of_forest <- 0.5;
	int number_of_firefighters <- 12;
	int number_of_groups <- 1 parameter:true min:1 max:6;
	
	// OUTPUTS
	int forest_saved;
	int cycle_end;
	
	// OTHER ATTRIBUTES OF THE MODEL
	
	list<rgb> color_of_group <- [#pink,#springgreen,#royalblue,#gray,#darkmagenta,#peru];
	
	string FIRE <- "fire";
	string CLEAR <- "clear";
	string FOREST <- "forest";
	
	string BUSY <- "firefighting";
	
	geometry shape <- square(3000#m);

	// Initialisation of the simulation
	init {
		
		// Set forest plots
		ask ((length(plot) * proportion_of_forest) among plot) {
			state <- FOREST;
			color <- #green;
		} 

		// Set the fire plot	
		ask any(plot) {
			state <- FIRE;
			color <- #red;
		}
		
		loop times:number_of_firefighters {
			if flip(communicating) {
				create communicant_firefighter {
					my_plot <- any(plot where (each.iam_empty));
					location <- my_plot.location;
				}
			} else {
				create firefighter {
					my_plot <- any(plot where (each.iam_empty));
					location <- my_plot.location;
				} 
			}
		}
		
		create brigade number:number_of_groups;
		int brigade_id <- 0;
		ask communicant_firefighter {
			crew <- brigade[brigade_id];
			crew.colleagues <+ self;
			brigade_id <- brigade_id = number_of_groups-1 ? 0 : brigade_id + 1;
		}
			
	}
	
	action outputs {
		forest_saved <- round(plot count (each.state=FOREST) / length(plot) * proportion_of_forest);
		cycle_end <- cycle;
	}
}

grid plot height: 30 width: 30 neighbors: 8  
		schedules: plot where(each.state = FIRE) 	
	{
	string state <- CLEAR among: [CLEAR,FOREST,FIRE];
	bool future_onFire <- false;
	
	rgb color <- #white;
	
	bool iam_empty -> empty(firefighter overlapping self);

	// Fire spreading solution 1: reflex in plot agents + scheduling
	// Spread the fire
	reflex fireSpreading {
		ask neighbors where (each.state=FOREST) { 
			state<-FIRE; 
			color<-#red;
		}
	}

}

species firefighter {
	brigade crew;
	
	string status <- "patrolling" among:["patrolling",BUSY];
	rgb color <- #blue;
	
	plot my_plot;
	
	reflex patrolling {
		status <- "patrolling";
		plot destination;
		list<plot> burning_plots_around <- my_plot.neighbors where (each.state=FIRE);
		
		if empty(burning_plots_around) {
			destination <- next_move();
		} else {
			destination <- any(burning_plots_around);
		}
		
		if not(destination = nil) {
			my_plot <- destination;
			location <- destination.location;
		}
	}
	
	reflex firefighting {
		if my_plot.state=FIRE {
			status <- BUSY;
			my_plot.state <- CLEAR;
			my_plot.color <- #white; 
		}
		if plot none_matches (each.state=FIRE) {ask world {do outputs;}}
	}
	
	/*
	 * When there is no fire, I move to my next target
	 */
	plot next_move {
		return any(my_plot.neighbors where (each.iam_empty));
	}
	
	aspect default {
		draw circle(50) color:color;
	}
}

species communicant_firefighter parent:firefighter {
	bool busy -> status=BUSY;
	
	plot next_move {
		list busy_colleagues <- (crew.colleagues-self) where (each.busy);
		// There is busy colleague
		if not(empty(busy_colleagues)) {
			firefighter closest_one <- busy_colleagues closest_to self;
			return closest_one.my_plot;
		} else { // No busy colleagues
			return any(my_plot.neighbors where (each.iam_empty));
		}
	}
	
	aspect default {
		draw circle(50) color:color_of_group[int(crew)];
	}
}

species brigade {
	list<communicant_firefighter> colleagues;
}

experiment simulation type: gui {	
	output {
		display d {
			grid plot border: #black;
			species firefighter;
			species communicant_firefighter;
		}
	}
}

experiment yousaidstochastic type:batch until:plot none_matches (each.state="fire") repeat:200 {
	method exploration;
	reflex saveoutputs {
		ask simulations { save [int(self),plot count (each.state="forest"),cycle_end] to:"Results/batch.csv" type:csv rewrite:false; }
	}
}

experiment myFirstAnalysis type:batch until:plot none_matches (each.state="fire") repeat:40 {
	
	parameter teams var:number_of_groups among:[1,2,3,4,6,8];
	
	method exploration;
	
	permanent { 
		display team background: #white {
		    chart "Plain forest" type: series x_serie_labels:[1,2,3,4,6] x_label:"Number of teams"{
		        data "Forest" value: mean(simulations collect (each.plot count (each.state="forest")))  
		        	y_err_values:standard_deviation(simulations collect (each.plot count (each.state="forest")))/sqrt(10);
		    }
	    }
	} 	
}

experiment sobol type:batch until:plot none_matches (each.state="fire") {
	//parameter teams var:nbb min:1 max:6;
	parameter comm var:communicating min:0.0 max:1.0;
	parameter nbfirefighters var:number_of_firefighters min:6 max:36;
	parameter nbgroups var:number_of_groups min:1 max:6;
	parameter forest var:proportion_of_forest min:0.4 max:0.9;
	method sobol outputs:["forest_saved","cycle_end"] sample:100 report:"Results/sobol_comm.txt" results:"Results/sobol_raw_comm.csv";
}

experiment Hill_Climbing type: batch keep_seed: true repeat: 40 until:plot none_matches (each.state="fire") {
	parameter comm var:communicating min:0.0 max:1.0 step:0.1;
	parameter nbfirefighters var:number_of_firefighters min:6 max:36 step:3;
	parameter nbgroups var:number_of_groups min:1 max:6 step:1;
	method hill_climbing init_solution:map(["communicating"::0.5, "number_of_firefighters":: 12, "number_of_groups"::2])  maximize: forest_saved aggregation: "avr";
}
