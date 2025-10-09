`default_nettype none

module tt_um_vga_example(
    input wire [7:0] ui_in,    // Dedizierte Eingänge
    output wire [7:0] uo_out,  // Dedizierte Ausgänge
    input wire [7:0] uio_in,   // IOs: Eingangs-Pfad
    output wire [7:0] uio_out, // IOs: Ausgangs-Pfad
    output wire [7:0] uio_oe,  // IOs: Enable-Pfad (aktiv High: 0=Eingang, 1=Ausgang)
    input wire ena,            // Immer 1, solange das Design mit Strom versorgt ist - kann ignoriert werden
    input wire clk,            // Takt
    input wire rst_n           // Reset_n - Low = Reset
);

    // VGA-Signale
    wire hsync;
    wire vsync;
    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // TinyVGA PMOD
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Ungenutzte Ausgänge auf 0 setzen
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Unterdrücke Warnungen für ungenutzte Signale
    wire _unused_ok = &{ena, uio_in};

    // VGA-Signal Generierung
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // Zustände für die Bewegung der gestrichelten Linie
    reg [9:0] scroll_offset; // Offset für die gestrichelte Linie
    wire is_dashed = (((pix_y + scroll_offset) % 32) < 16) && (pix_x >= 310 && pix_x < 330); 

    // Zustände für die Bewegung des Autos
    reg [9:0] car_position = 480; // Startposition des Autos
    wire is_car = (pix_x >= car_position && pix_x < car_position + 80) && (pix_y >= 240 && pix_y < 360); 

    // Bewegungssteuerung der gestrichelten Linie mit vsync in umgekehrte Richtung
    always @(posedge vsync or negedge rst_n) begin
        if (!rst_n) begin
            scroll_offset <= 0;
        end else if (ui_in[0]) begin
            scroll_offset <= scroll_offset - 1; // Vertikale Bewegung der gesamten Linie nach oben
        end

        // Auto bewegt sich nach links oder rechts basierend auf den Pins
        if (ui_in[1] && (car_position > 0)) begin
            car_position <= car_position - 1; // Nach links bewegen
        end else if (ui_in[2] && (car_position < 640 - 80)) begin
            car_position <= car_position + 1; // Nach rechts bewegen
        end
    end

    // Linien Positionen
    wire is_line = (pix_x < 20) || (pix_x >= 620); // Links und rechts: 20 Pixel breite Linien

    // Farbzuweisungen
    assign R = video_active ? (is_line || is_dashed || is_car ? 2'b11 : 2'b10) : 2'b00;
    assign G = video_active ? (is_line || is_dashed || is_car ? 2'b11 : 2'b10) : 2'b00;
    assign B = video_active ? (is_line || is_dashed || is_car ? 2'b11 : 2'b10) : 2'b00;

endmodule
