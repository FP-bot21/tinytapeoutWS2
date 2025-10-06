`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedizierte Eingänge
  output wire [7:0] uo_out,   // Dedizierte Ausgänge
  input  wire [7:0] uio_in,   // IOs: Eingangs-Pfad
  output wire [7:0] uio_out,  // IOs: Ausgangs-Pfad
  output wire [7:0] uio_oe,   // IOs: Enable-Pfad
  input  wire       ena,      // Kann ignoriert werden
  input  wire       clk,      // Takt
  input  wire       rst_n     // Reset - Low aktiv
);

  // VGA Signale
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  // Zuweisung der VGA-Ausgänge
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Ungenutzte Ausgänge auf 0 setzen
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Unterdrückung von Warnungen für ungenutzte Signale
  wire _unused_ok = &{ena, uio_in};

  // Initialisierung des hvsync_generators
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // Register zur Speicherung der Karosserieposition
  reg [9:0] car_x_start = 100;
  reg [9:0] car_x_end   = 200;
  
  // Timer zur Steuerung der Bewegungsgeschwindigkeit
  reg [15:0] move_counter = 0;
  localparam [15:0] MOVE_SPEED = 50000; // Definiert die Geschwindigkeit der Bewegung

  // Logik zur Bestimmung, ob der aktuelle Pixel im Bereich der Karosserie liegt
  wire in_car_body = (pix_x >= car_x_start && pix_x < car_x_end &&
                      pix_y >= 100 && pix_y < 130);
  
  // Logik zur Bestimmung, ob der aktuelle Pixel im Bereich der Räder liegt
  localparam [9:0] WHEEL_Y_START = 130;
  localparam [9:0] WHEEL_Y_END = 140;
  wire in_wheel_left = (pix_x >= car_x_start + 10 && pix_x < car_x_start + 20 &&
                        pix_y >= WHEEL_Y_START && pix_y < WHEEL_Y_END);
  wire in_wheel_right = (pix_x >= car_x_end - 20 && pix_x < car_x_end - 10 &&
                         pix_y >= WHEEL_Y_START && pix_y < WHEEL_Y_END);

  // Kontrolle der Bewegung des Autos basierend auf den Eingangspins
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
      car_x_start <= 100;
      car_x_end <= 200;
      move_counter <= 0;
    end else begin
      move_counter <= move_counter + 1;

      // Nur alle 'MOVE_SPEED' Taktzyklen die Position verändern
      if (move_counter >= MOVE_SPEED) begin
        move_counter <= 0;  // Reset des Zählers
        if (ui_in[0]) begin // Wenn Pin 0 auf High ist (nach rechts bewegen)
          car_x_start <= car_x_start + 1;
          car_x_end <= car_x_end + 1;
        end else if (ui_in[1]) begin // Wenn Pin 1 auf High ist (nach links bewegen)
          car_x_start <= car_x_start - 1;
          car_x_end <= car_x_end - 1;
        end
      end
    end
  end

  // Zuweisung der Farbe des Autos (rot für Karosserie und schwarz für Räder) während der aktiven Video-Phase
  assign R = (video_active && in_car_body) ? 2'b11 : 2'b00;
  assign G = 2'b00;
  assign B = (video_active && (in_wheel_left || in_wheel_right)) ? 2'b11 : 2'b00;

endmodule
