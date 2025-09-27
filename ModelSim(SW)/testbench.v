`timescale 1ns / 1ps

module testbench ();

    parameter CLOCK_PERIOD = 10; // Clock period (in ns)

    reg [2:0] SW;
    reg CLOCK_50; 
    wire [9:0] LEDR;
    wire [6:0] HEX0;
    wire [6:0] HEX1;

    // Clock Generator with proper delay
    always begin
        #((CLOCK_PERIOD) / 2) CLOCK_50 = ~CLOCK_50; // Toggle CLOCK_50 every half period
    end

    initial begin
        // Initialize inputs
        CLOCK_50 = 1'b0;  // Start with clock low
        SW = 3'b000;

        // Apply initial conditions for testing
        
    end // initial

    finalproject U1 (SW, CLOCK_50, LEDR, HEX0, HEX1);

endmodule