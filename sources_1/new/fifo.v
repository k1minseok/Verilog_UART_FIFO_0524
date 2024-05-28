module fifo #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input clk,
    input reset,

    input                   wr_en,
    output                  full,
    input  [DATA_WIDTH-1:0] wdata,

    input                   rd_en,
    output                  empty,
    output [DATA_WIDTH-1:0] rdata
);

    // wire w_full;
    wire [ADDR_WIDTH-1:0] w_waddr, w_raddr;

    register_file #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)  // 3bit address==2^3개 메모리 공간, 8bit data
    ) U_RegFile (
        .clk  (clk),
        .reset(reset),
        .wr_en(wr_en & ~full),
        .waddr(w_waddr),
        .wdata(wdata),
        // .rd_en(rd_en & ~empty),
        .raddr(w_raddr),

        .rdata(rdata)
    );

    fifo_control_unit #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_FIFO_CU (
        .clk  (clk),
        .reset(reset),

        // wrte
        .wr_en(wr_en),
        .full (full),
        .waddr(w_waddr),

        // read
        .rd_en(rd_en),
        .empty(empty),
        .raddr(w_raddr)
    );

endmodule


module register_file #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8  // 3bit address==2^3개 메모리 공간, 8bit data
) (
    input                  clk,
    input                  reset,
    input                  wr_en,
    // input                  rd_en,
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,
    input [ADDR_WIDTH-1:0] raddr,

    output [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            mem[0] <= 0;
            mem[1] <= 0;
            mem[2] <= 0;
            mem[3] <= 0;
            mem[4] <= 0;
            mem[5] <= 0;
            mem[6] <= 0;
            mem[7] <= 0;
            mem[8] <= 0;
            mem[9] <= 0;
            mem[10] <= 0;
            mem[11] <= 0;
            mem[12] <= 0;
            mem[13] <= 0;
            mem[14] <= 0;
            mem[15] <= 0;
        end else begin
            if (wr_en) mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr];
    // assign rdata = rd_en ? mem[raddr] : 8'bz;   // read enable 1이면 출력, 아니면 High Impedence

endmodule


module fifo_control_unit #(
    parameter ADDR_WIDTH = 3
) (
    input clk,
    input reset,

    // wrte
    input                   wr_en,
    output                  full,
    output [ADDR_WIDTH-1:0] waddr,

    // read
    input rd_en,
    output empty,
    output [ADDR_WIDTH-1:0] raddr
);

    reg [ADDR_WIDTH-1:0] wr_ptr_reg, wr_ptr_next;
    reg [ADDR_WIDTH-1:0] rd_ptr_reg, rd_ptr_next;
    reg full_reg, full_next, empty_reg, empty_next;


    assign waddr = wr_ptr_reg;
    assign raddr = rd_ptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            full_reg   <= 1'b0;
            empty_reg  <= 1'b0;
        end else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            full_reg   <= full_next;
            empty_reg  <= empty_next;
        end
    end

    always @(*) begin
        wr_ptr_next = wr_ptr_reg;
        rd_ptr_next = rd_ptr_reg;
        full_next   = full_reg;
        empty_next  = empty_reg;

        case ({
            wr_en, rd_en
        })
            2'b01: begin  // read
                if (!empty_reg) begin
                    full_next   = 1'b0;  // read이면 full = 0
                    rd_ptr_next = rd_ptr_reg + 1;
                    if (rd_ptr_next == wr_ptr_reg) begin
                        empty_next = 1'b1;  // 모두 읽었으면 empty
                    end
                end
            end

            2'b10: begin  // write
                if (!full_reg) begin
                    empty_next  = 1'b0;  // write이면 empty = 0
                    wr_ptr_next = wr_ptr_reg + 1;
                    if (wr_ptr_next == rd_ptr_reg) begin
                        full_next = 1'b1;  // 모두 썼으면 full
                    end
                end
            end

            2'b11: begin  // write, read
                if (empty_reg) begin  // 비어있으면 더이상 진행 X
                    wr_ptr_next = wr_ptr_reg;
                    rd_ptr_next = rd_ptr_reg;
                end else begin  // 비어 있지 않으면 각 포인터 +1
                    wr_ptr_next = wr_ptr_reg + 1;
                    rd_ptr_next = rd_ptr_reg + 1;
                end
            end
        endcase
    end
endmodule