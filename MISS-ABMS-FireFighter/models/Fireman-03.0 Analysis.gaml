/**
* Name: Fireman030Analysis
* Based on the internal empty template. 
* Author: kevinchapuis
* Tags: 
*/


model Fireman030Analysis

import "Fireman-02.6b-Exploration.gaml"

global {
	
	string res_file <- "Results/batch.csv";
	list<int> forest_saved_res <- [];
	list<int> cycle_end_res <- [];
	
	list<int> stoch_size <- [5,10,25,50,100,200];
	list<int> ferror <- [];
	list<int> cerror <- [];
	
	init {
		matrix data <- matrix(csv_file(res_file));
		loop i from: 1 to: data.rows -1 {
			forest_saved_res <+ int(data[1,i]);
			cycle_end_res <+ int(data[2,i]); 
		}	
		
		loop s over:stoch_size {
			list<int> subres <- s among forest_saved_res;
			ferror <+ standard_deviation(subres) / sqrt(s);
			list<int> subres2 <- s among cycle_end_res;
			cerror <+ standard_deviation(subres) / sqrt(s);
		}
	}
	
}

experiment viz_stoch {
	output {
		display mydisp {
			chart "Stochasticity" type: xy {
				loop s over:stoch_size {
					data "forest "+s value:[s,ferror[stoch_size index_of s]] color:#green;
					data "cycle"+s value:[s,cerror[stoch_size index_of s]] color:#blue;
				}
			}
		}
	}
}