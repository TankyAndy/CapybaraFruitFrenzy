module finalproject(SW,KEY, CLOCK_50,LEDR,HEX0,HEX1,HEX2, HEX3, HEX4,HEX5,VGA_R,VGA_G,VGA_B,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_CLK,PS2_CLK,PS2_DAT);
   input CLOCK_50;
   input [2:0] SW;
	inout PS2_CLK;
	inout PS2_DAT;
	input [3:0] KEY;
	output [6:0] HEX0,HEX1, HEX2, HEX3, HEX4,HEX5;
   output reg [9:0] LEDR;
	output [7:0] VGA_R;
   output [7:0] VGA_G;
   output [7:0] VGA_B;
   output VGA_HS;
   output VGA_VS;
   output VGA_BLANK_N;
   output VGA_SYNC_N;
   output VGA_CLK;
   reg [25:0] count;
   reg [25:0] countUser;
   reg [10:0] xEdit [0:7];
   reg [10:0] yEdit [0:7];
	reg [10:0] xUser;
	reg [10:0] yUser;

   reg [3:0] health;
	reg [3:0] score;
	reg [2:0] colour;
	wire [2:0] fruitColour;
	assign fruitColour = 3'b100; 
	reg plot;
   integer i;

   reg reset;
   reg [1:0] state;
   reg [9:0] variance[0:7];
   reg [9:0] variationy [0:7];
	reg [10:0] xDiff;
   reg [10:0] yDiff;

   reg [19:0] debounce_counter; 
   reg key_stable; 

   localparam START = 2'b01, SHOW_GAME = 2'b10;
    
    // define dimensions of the screen
   parameter X_WIDTH  = 160;
   parameter Y_HEIGHT = 120;

	// define coordinates of the background
   reg [7:0] xBackground;
   reg [6:0] yBackground;

    // define rom signals
   wire [2:0] rom_data; 

    // define rom vga coordinates
   wire [14:0] rom_address; 

    // Game state parameters
   parameter GAME_START = 2'b00, GAME_ON = 2'b01, GAME_OVER = 2'b10;       
	parameter CLEAR = 2'b00, DRAW = 2'b01;

   reg [1:0] drawState; // FSM states for drawing objects
   reg [10:0] xPlot, yPlot;
	reg [9:0] x;     
   reg [9:0] y;    
   reg [3:0] current; // Keep track of which fruit we're drawing
	 
	 // Internal Wires
	wire [7:0] ps2_key_data;
	wire ps2_key_pressed;
	reg [7:0] last_data_received;

	// Internal Registers
	reg [7:0] x_change;  // Stores X movement
	reg [7:0] y_change;  // Stores Y movement
	reg xSign;
	reg ySign;
	reg [1:0] byte_count;  // Tracks which byte is being processed


	seg7_binaryToHex sc(score, HEX1);
	seg7_binaryToHex hp(health, HEX0);
   seg7_binaryToHex st(state, HEX3); 
   assign HEX2 = 0; 
	 
	vga_adapter VGA (
    .resetn(1), 
    .clock(CLOCK_50),
    .x(xPlot),
    .y(yPlot),
    .colour(colour),
    .plot(plot), // Signal to plot the pixel
    .VGA_R(VGA_R), 
    .VGA_G(VGA_G), 
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK_N(VGA_BLANK_N),
    .VGA_SYNC_N(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK)
	 );

   defparam VGA.RESOLUTION = "160x120";
   defparam VGA.MONOCHROME = "FALSE";
   defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
   // default background (login screen)
   defparam VGA.BACKGROUND_IMAGE = "projectloginscreen.mif"; 

	// PS/2 Controller
	PS2_Controller PS2 (
    // Inputs
    .CLOCK_50              (CLOCK_50),
    .reset                 (~KEY[0]),

    // Bidirectionals
    .PS2_CLK               (PS2_CLK),
    .PS2_DAT               (PS2_DAT),

    // Outputs
    .received_data         (ps2_key_data),
    .received_data_en      (ps2_key_pressed)
	 );

	 // Key debouncing logic
    always @(posedge CLOCK_50) begin 
		if (~KEY[1]) begin 
        if (debounce_counter < 20'd50000) begin 
				debounce_counter <= debounce_counter + 1; 
        end else begin 
            key_stable <= 1; 
        end 
      end else begin 
         debounce_counter <= 0; 
         key_stable <= 0; 
      end 
    end 

    // Main Game FSM (GAME_START, GAME_ON, GAME_OVER)
    always @(posedge CLOCK_50) begin

		if (~KEY[1]) begin
      // HARD RESET: Reinitialize all variables and states
			state <= GAME_START;
			health <= 3'b101; 
			score <= 4'b0;    
			count <= 26'b0;   
			LEDR <= 10'b0;    
			drawState <= CLEAR; 

        // Reset fruit positions and movements
			for (i = 0; i < 8; i = i + 1) begin
				xEdit[i] <= 40 + i * 10; 
				variance[i] <= 5 + (i * 10);
				yEdit[i] <= 0 + variance[i];    
			end
       end else begin 
			case(state) 
				
				GAME_START: begin 
					// IDLE, waiting for the user to play the game
                
					for (i = 0; i < 8; i = i + 1) begin
						variationy[i] <= 5 + (i * 10);
						xEdit[i] <= 40 + i * 10; //in real game, x[i] <= i * 30 to distribute across x
						yEdit[i] <= 0 + variance[i]; //410 - variationy[i];		 
					end

					reset <= 1;
					health <= 3'b101;
					score <= 4'b0;
					count <= 26'b0;
					LEDR[8:1] <= 9'b0;
					LEDR[0] <= 1;

					if(~SW[0])begin //SW[0] to start game. 
						state <= GAME_START;
					end else begin
						state <= GAME_ON;
					end

				end

            GAME_ON: begin
                reset <= 0;
                state <= GAME_ON;
                if (count == 50000000 - 1) begin // Execute once 1 second has passed
							count <= 26'b0;
							LEDR[8:6] <= 4'b0;
							LEDR[0] <= 0;
							LEDR[1] <= 1;
							LEDR[4:2] <= 3'b0;

							for (i = 0; i < 8; i = i + 1) begin // Loop through each fruit

                        if((xUser < xEdit[i] + 5) && (xUser > xEdit[i] - 5) && (yUser < yEdit[i] + 5) && (yUser > yEdit[i] - 5)) begin
                                variance[i] <= -variance[i];
                                yEdit[i] <= 0;
                                xEdit[i] <= xEdit[i] + variance[i];
										  score <= score + 1;
                                LEDR[3] <= 1;
										  
                        end else if (yEdit[i] > Y_HEIGHT - 10) begin // If the fruit hits the ground
                            //reset position to the top at a different x coord.
										variance[i] <= -variance[i];
										yEdit[i] <= 0;
										xEdit[i] <= xEdit[i] + -variance[i];
										health <= health - 1;
										LEDR[8:6] <= 4'b1111;

                        end else if (health == 0) begin//if health = 0 game over.
                              state <= GAME_OVER;
							end else begin
                            //normal falling fruit behavior
                            xEdit[i] <= xEdit[i];
                            yEdit[i] <= yEdit[i] + 1;
                            LEDR[5] <= ~LEDR[5];
                     end
					 
					end
                     
			    end
                     
				count <= count + 1;

            case (drawState)
					CLEAR: begin
						colour <= rom_data; // Draw the background image
						if (xBackground < X_WIDTH - 1)
							xBackground <= xBackground + 1;
						else if (yBackground < Y_HEIGHT - 1) begin
							xBackground <= 0;
							yBackground <= yBackground + 1;
						end else begin
							xBackground <= 0;
							yBackground <= 0;
							drawState <= DRAW;
							current <= 0;
						end
                xPlot <= xBackground;
                yPlot <= yBackground;
                plot <= 1'b1;
            end

            DRAW: begin
                case (current)
                // Draw fruits (0-7)
                0,3,6: begin
                colour <= 3'b100;
                // Draw 3x3 square for each fruit
                if (x < 3 && y < 3) begin
                    xPlot <= xEdit[current] + x - 1;
                    yPlot <= yEdit[current] + y - 1;
                    plot <= 1'b1;
                    if (x == 2 && y == 2) begin
                        x <= 0;
                        y <= 0;
                        current <= current + 1;
                    end else if (x == 2) begin
                        x <= 0;
                        y <= y + 1;
                    end else begin
                        x <= x + 1;
                    end
                end
                end

                1,4,7: begin
                    colour <= 3'b110;
                    // Draw 3x3 square for each fruit
                    if (x < 3 && y < 3) begin
                        xPlot <= xEdit[current] + x - 1;
                        yPlot <= yEdit[current] + y - 1;
                        plot <= 1'b1;
                        if (x == 2 && y == 2) begin
                            x <= 0;
                            y <= 0;
                            current <= current + 1;
                        end else if (x == 2) begin
                            x <= 0;
                            y <= y + 1;
                        end else begin
                            x <= x + 1;
                        end
                    end
                end

                2,5: begin
                    colour <= 3'b101;
                    // Draw 3x3 square for each fruit
                    if (x < 3 && y < 3) begin
                        xPlot <= xEdit[current] + x - 1;
                        yPlot <= yEdit[current] + y - 1;
                        plot <= 1'b1;
                        if (x == 2 && y == 2) begin
                            x <= 0;
                            y <= 0;
                            current <= current + 1;
                        end else if (x == 2) begin
                            x <= 0;
                            y <= y + 1;
                        end else begin
                            x <= x + 1;
                        end
                    end
                end

                // Draw cross (8)
                8: begin
                    colour <= 3'b100;
                    if (x < 7) begin // Draw vertical line
                        xPlot <= xUser;
                        yPlot <= yUser - 3 + x;
                        plot <= 1'b1;
                        x <= x + 1;
                    end else if (y < 7) begin // Draw horizontal line
                        xPlot <= xUser - 3 + y;
                        yPlot <= yUser;
                        plot <= 1'b1;
                        y <= y + 1;
                    end else begin
                        x <= 0;
                        y <= 0;
                        current <= current + 1;
                    end
                end

                default: begin
                    drawState <= CLEAR;
                    current <= 0;
                    x <= 0;
                    y <= 0;
                end
            endcase
            end
        endcase

        end // End of GAME_ON state 

        GAME_OVER: begin
            state <= GAME_OVER;
            LEDR[8:3] <= 7'b0;
            LEDR[2] <= 1;
            LEDR[1:0] <= 2'b0;
            if(~KEY[1]) begin //KEY[1] to reset the game
                state <= GAME_START;
            end
        end 
        endcase // End of Game States case statement  
    end // end of else statement     
					 
end

always @(posedge CLOCK_50) begin

    // Movement delay counter
    if (reset) begin
        countUser <= 0;
        xUser <= X_WIDTH / 2; // Start in the middle of the screen
        yUser <= Y_HEIGHT - 10; // Start at the bottom

    end else begin
        if (ps2_key_pressed == 1'b1) begin
            last_data_received <= ps2_key_data;
        end
        if (countUser == 1000000) begin // Adjust the value to control movement speed
            countUser <= 0; // Reset the counter
            // Check for KEY presses
            if (last_data_received == 8'h75 && yUser > 0) begin
                yUser <= yUser - 1; // Move up
            end
				
            if (last_data_received == 8'h6B && xUser > 0) begin
                xUser <= xUser - 1; // Move left
            end

            if (last_data_received == 8'h74 && xUser < X_WIDTH - 1) begin
                xUser <= xUser + 1; // Move right
            end

            if (last_data_received == 8'h72 && yUser < Y_HEIGHT - 1) begin
                yUser <= yUser + 1; // Move down
            end

        end else begin

            countUser <= countUser + 1; // Increment the delay counter

        end

    end

end

Hexadecimal_To_Seven_Segment Segment0 (
	// Inputs
	.hex_number			(last_data_received[3:0]),

	// Bidirectional

	// Outputs
	.seven_seg_display	(HEX4)
);

Hexadecimal_To_Seven_Segment Segment1 (
	// Inputs
	.hex_number			(last_data_received[7:4]),

	// Bidirectional

	// Outputs
	.seven_seg_display	(HEX5)
);


 assign rom_address = (yBackground * X_WIDTH) + xBackground; 

//! inst rom
drawCapyBack rom_inst (
    .address(rom_address),
    .clock(CLOCK_50),
    .q(rom_data)
);

endmodule

module seg7_binaryToHex(S, Display); 
    input [3:0]S; 
    output reg [6:0]Display; 

    always@ (*) begin 

        case (S)
            4'h0: Display = 7'b1000000; 
            4'h1: Display = 7'b1111001; 
            4'h2: Display = 7'b0100100; 
            4'h3: Display = 7'b0110000; 
            4'h4: Display = 7'b0011001; 
            4'h5: Display = 7'b0010010; 
            4'h6: Display = 7'b0000010; 
            4'h7: Display = 7'b1111000; 
            4'h8: Display = 7'b0000000; 
            4'h9: Display = 7'b0011000; 
            4'hA: Display = 7'b0001000; 
            4'hB: Display = 7'b0000011; 
            4'hC: Display = 7'b1000111; 
            4'hD: Display = 7'b0100001; 
            4'hE: Display = 7'b0000110; 
            4'hF: Display = 7'b0001110; 
            // default??

        endcase
    end 

endmodule
