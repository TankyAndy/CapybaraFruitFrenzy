module finalproject(SW,KEY, CLOCK_50,LEDR,HEX0,HEX1,VGA_R,VGA_G,VGA_B,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_CLK,PS2_CLK,PS2_DAT,);
    input CLOCK_50;
    input [2:0] SW;
	 inout PS2_CLK;
	 inout PS2_DAT;
	 input [3:0] KEY;
	 output [6:0] HEX0, HEX1;
    output reg [9:0] LEDR;
	 output [7:0] VGA_R;
    output [7:0] VGA_G;
    output [7:0] VGA_B;
    output VGA_HS;
    output VGA_VS;
    output VGA_BLANK_N;
    output VGA_SYNC_N;
    output VGA_CLK;

    //wire [87:0] x;
    //wire [87:0] y;
    //wire [7:0] s;
    reg [25:0] count;
    reg [10:0] xEdit [0:7];
    reg [10:0] yEdit [0:7];
	 reg [10:0] boundOne;
    reg [10:0] boundOneLow;
	 reg [10:0] boundTwo;
    reg [10:0] boundTwoLow;
	 reg [10:0] xUser;
	 reg [10:0] yUser;
	 reg clicked;
    reg [7:0] sEdit;
    reg [2:0] health;
	 reg [3:0] score;
//    reg [9:0] yThreshold;
	 reg [7:0] colour;
	 wire [2:0] fruitColour;
	 assign fruitColour = 3'b100; 
	 wire [7:0] backgroundColour;
     reg drawBackground;
     reg printOn;
	 reg plot;
    integer i;
	 integer k;
    reg reset;
    reg [1:0] state;
    reg [9:0] variance[0:7];
    reg [9:0] variationy [0:7];
	 reg [10:0] xDiff;
    reg [10:0] yDiff;
    reg collision;



    // BACKGROUND STUFFF BACKGROUND STUFF BACKGROUND STUFF

localparam START       = 2'b01,
           SHOW_GAME = 2'b10;
 
parameter X_WIDTH  = 160;
parameter Y_HEIGHT = 120;

//def next states and howevermany bgs
reg [1:0] current_state, next_state;

reg [7:0] xBackground;
reg [6:0] yBackground;

// rom signals
wire [2:0] rom_data; 
// rom vga coordinates (19,200)
wire [14:0] rom_address; 

    // BACKGROUND STUFFF BACKGROUND STUFF BACKGROUND STUFF


    //the variance variable is a constant. basically, whenever the fruit
    //reaches the y threshhold or the fruit is "removed" it resets to the
    //top of the screen. the x coordinate has to + variance so it appears
    //in a different spot. variance needs to be the opposite sign every time. 
    //so when the fruit resets once, i add 20. when it resets again, i add -20.

    //CONTROLS:
    //SW[0] = 0 -> GAME_START
    //SW[0] = 1 -> GAME_ON

    //SW[1] = 1 -> remove fruit

    //SW[2] = 1 -> go back to GAME_START

    //INDICATORS
    //LEDR 0 and rest 0 -> state1 which is GAME_START
    //LEDR 1 and rest 0 -> state2 which is GAME_ON
        //LEDR 9-6 -> fruit hit ground
        //LEDR 5 -> blinking means fruit falling
        //LEDR 3 -> success remove fruit
    //LEDR 2 and rest 0 -> state3 which is GAME_OVER

    parameter GAME_START = 2'b00, GAME_ON = 2'b01, GAME_OVER = 2'b10;       
	 parameter CLEAR = 2'b00, DRAW = 2'b01;

    reg [1:0] drawState;
    reg [10:0] xPlot, yPlot;
	 reg [9:0] x;     // Counts up to 640 (screen width)
    reg [9:0] y;     // Counts up to 480 (screen height)
    reg [3:0] current; // Keep track of which fruit we're drawing
    //fruits fruit_instances (CLOCK_50, reset, xEdit, yEdit, sEdit, x, y, s);
	 
	 // Internal Wires
	 wire        [7:0]   ps2_key_data;
	 wire                ps2_key_pressed;

	// Internal Registers
	 reg         [7:0]   x_change;  // Stores X movement
	 reg         [7:0]   y_change;  // Stores Y movement
	 reg xSign;
	 reg ySign;
	 reg         [1:0]   byte_count;  // Tracks which byte is being processed


	 seg7_binaryToHex sc(score, HEX1);
	 seg7_binaryToHex hp(health, HEX0);
	 
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
    // def bg
    defparam VGA.BACKGROUND_IMAGE = "projectloginscreen.mif"; 
	 
	 
	 // PS/2 Controller
	 PS2_Controller#(.INITIALIZE_MOUSE(1)) PS2 (
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


    always @(posedge CLOCK_50) begin

	 
	 
        if(SW[0] == 0)begin
            state <= GAME_START;
        end

        case(state)

            GAME_START: begin
                
                for (i = 0; i < 8; i = i + 1) begin
				variationy[i] <= 5 + (i * 10);
                xEdit[i] <= 40 + i * 10; //in real game, x[i] <= i * 30 to distribute across x
                yEdit[i] <= 0; //410 - variationy[i];
					 
            end

        x_change <= 0;
        y_change <= 0;
		  xSign <= 0;
		  ySign <= 0;
		  clicked <= 0;
        byte_count <= 0;
        LEDR[9] <= 0;
                reset <= 1;
					 xUser <= X_WIDTH - 60;
					 yUser <= Y_HEIGHT - 80;
                health <= 3'b101;
					 score <= 4'b0;
                count <= 26'b0;
                LEDR[8:1] <= 9'b0;
                LEDR[0] <= 1;
					 //drawState <= CLEAR;
					 xDiff <= 0;
					 yDiff <= 0;
                     printOn <= 1;

                if(SW[0] == 0)begin //SW[0] to start game. 
                    state <= GAME_START;
                end else begin
                    state <= GAME_ON;
                end
            end

            GAME_ON: begin
                reset <= 0;
                state <= GAME_ON;
                if (count == 10000 - 1) begin //1 second just to test.
						  count <= 26'b0;
                    LEDR[8:6] <= 4'b0;
                    LEDR[0] <= 0;
                    LEDR[1] <= 1;
                    LEDR[4:2] <= 3'b0;
						

                    for (i = 0; i < 8; i = i + 1) begin // Loop through each fruit
						  
						  /*
						  if(xUser > xEdit[i]) begin
								xDiff <= xUser - xEdit[i];
						  end else begin
								yDiff <= xEdit[i] - xUser;
						  end
						  
						  if(yUser > yEdit[i]) begin
								yDiff <= yUser - yEdit[i];
						  end else begin
								yDiff <= yEdit[i] - yUser;
						  end
						  */
						  
						  //boundOne <= xEdit[i] + 50;
						  
						  //boundOneLow <= xEdit[i] - 50;
						  
						  //boundTwo <= yEdit[i] + 50;
						  
						  //boundTwoLow <= yEdit[i] - 50;
						  
							//LEDR[7] <= (xUser >= xEdit[i] - 40 && xUser <= xEdit[i] + 40);
							//LEDR[8] <= (yUser >= yEdit[i] - 40 && yUser <= yEdit[i] + 40);
							//LEDR[6] <= clicked;
						
                        collision <= (yUser < yEdit[1]);
                        if((clicked) && (xUser < xEdit[i] + 10) && (xUser > xEdit[i] - 10) && (yUser < yEdit[i] + 10) && (yUser > yEdit[i] - 10)) begin
                                //clicked && (xUser < boundOne) && (xUser > boundOneLow) && (yUser < boundTwo) && (yUser > boundTwoLow)
								//(clicked) && (xDiff < 20) && (yDiff < 20)
								//(clicked) && (xUser < xEdit[i] + 10) && (xUser > xEdit[i] - 10) && (yUser < yEdit[i] + 10) && (yUser > yEdit[i] - 10)
                                variance[i] <= -variance[i];
                                yEdit[i] <= 0;
                                xEdit[i] <= xEdit[i] + variance[i];
								score <= score + 1;
                                LEDR[3] <= 1;

                        end

                        if (yEdit[i] > Y_HEIGHT - 10) begin // If the fruit hits the ground
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
                              //if(printOn)begin
                     
					 end
                     
					 count <= count + 1;




            end

            GAME_OVER: begin
                state <= GAME_OVER;
                LEDR[8:3] <= 7'b0;
                LEDR[2] <= 1;
                LEDR[1:0] <= 2'b0;
                if(SW[2] == 1)begin //SW[2] to reset game
                    state <= GAME_START;
                end
         end 

        endcase
        
        case (drawState)
        CLEAR: begin
            colour <= rom_data;
            //drawBackground <= 1;
            //if (drawBackground) begin
            if (xBackground < X_WIDTH - 1)
                // move to the next pixel in x direction
                xBackground <= xBackground + 1;
            else if (yBackground < Y_HEIGHT - 1) begin
                xBackground <= 0;                                 
                yBackground <= yBackground + 1;                             
            end else begin
               // reset to 0 at the end
                xBackground <= 0; 
                yBackground <= 0;
                drawState <= DRAW;
            end
            xPlot <= xBackground;
            yPlot <= yBackground;
            plot <= 1'b1;
        //end
				end
        DRAW: begin
            //drawBackground <= 0;
            if (current < 8) begin
                colour <= fruitColour;
                xPlot <= xEdit[current];
                yPlot <= yEdit[current];
                plot <= 1'b1;
                current <= current + 1;
            end else if (current == 8) begin
            colour <= fruitColour;
            xPlot <= xUser;
            yPlot <= yUser;
            plot <= 1'b1;
            current <= 0;
            drawState <= CLEAR;
            end
				end
        endcase




        if (ps2_key_pressed) begin
        // Check if this is start of packet (bit 3 should be 1 in byte 0)
        if (byte_count == 0) begin
            if (ps2_key_data[3] == 1'b1) begin  // Verify it's really byte 0
                // Store button states
                clicked <= ps2_key_data[0];
					 LEDR[9] <= ps2_key_data[0];
					 xSign <= ps2_key_data[4];
					 ySign <= ps2_key_data[5];
                byte_count <= byte_count + 1;
            end
            // If not byte 0, stay at byte_count 0
        end
        else if (byte_count == 1) begin
            if(xSign <= 1)begin
					x_change <= ps2_key_data;
				end else begin
					x_change <= -ps2_key_data;
				end
            byte_count <= byte_count + 1;
        end
        else if (byte_count == 2) begin
				if(ySign <= 1)begin
					y_change <= ps2_key_data;
				end else begin
					y_change <= -ps2_key_data;
				end
            byte_count <= 0;
				
				xUser <= xUser + x_change;
				yUser <= yUser - y_change;
				
				//if (xUser > 639) xUser <= 639;
				//if (xUser < 0) xUser <= 0;
				//if (yUser > 479) yUser <= 479;
				//if (yUser < 0) yUser <= 0;
        end
    end






    end
	 

 assign rom_address = (yBackground * X_WIDTH) + xBackground; 

//! inst rom
drawCover rom_inst (
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
