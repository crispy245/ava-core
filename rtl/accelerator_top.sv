// `include "defs.sv"
import accelerator_pkg::*;

module accelerator_top (
    output logic [31:0] apu_result,
    output logic [4:0] apu_flags_o,
    output wire apu_gnt,
    output wire apu_rvalid,
    input wire clk,
    input wire n_reset,
    input wire apu_req,
    input wire [31:0] apu_operands [2:0],
    input wire [5:0] apu_op,
    input wire [14:0] apu_flags_i
);

////////////////////////////////////////////////////////////////////////////////
// OUTPUT VARIABLE DECLARATIONS
////////////////////////////////////////////////////////////////////////////////

// CSR OUTPUTS
wire [4:0] vl;
wire [1:0] vsew;
wire [1:0] vlmul;

// DECODER OUTPUTS
wire [31:0] scalar_operand1;
wire [31:0] scalar_operand2;
wire [11:0] immediate_operand;
wire [4:0] vs1_addr;
wire [4:0] vs2_addr;
wire [4:0] vd_addr;
wire csr_write;
wire preserve_vl;
wire set_vl_max;
wire [1:0] elements_to_write;
wire [1:0] cycle_count;
wire vec_reg_write;
vreg_wb_src_t vd_data_src;
pe_arith_op_t pe_op;
pe_saturation_mode_t saturation_mode;
pe_output_mode_t output_mode;
pe_operand_t operand_select;
wire [1:0] pe_mul_us;
wire [1:0] widening;
apu_result_src_t apu_result_select;

// VLSU OUTPUTS

// VECTOR REGISTERS OUTPUTS
wire [127:0] vs1_data;
wire [127:0] vs2_data;
wire [127:0] vs3_data;

// ARITHMETIC STAGE OUTPUTS
wire [127:0] arith_output;
wire [127:0] replicated_scalar;

////////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATION
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////
// CSRs
vector_csrs vcsrs0 (
    .vl(vl),
    .vsew(vsew),
    .vlmul(vlmul),
    .clk(clk),
    .n_reset(n_reset),
    .avl_in(scalar_operand1),
    .vtype_in(immediate_operand),
    .write(csr_write),
    // .saturate_flag(),
    .preserve_vl(preserve_vl),
    .set_vl_max(set_vl_max)
);

////////////////////////////////////////
// DECODER
vector_decoder vdec0 (
    .apu_rvalid(apu_rvalid),
    .apu_gnt(apu_gnt),
    .scalar_operand1(scalar_operand1),
    .scalar_operand2(scalar_operand2),
    .immediate_operand(immediate_operand),
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vd_addr(vd_addr),
    .csr_write(csr_write),
    .preserve_vl(preserve_vl),
    .set_vl_max(set_vl_max),
    .elements_to_write(elements_to_write),
    .cycle_count(cycle_count),
    .vec_reg_write(vec_reg_write),
    .vd_data_src(vd_data_src),
    .pe_op(pe_op),
    .saturation_mode(saturation_mode),
    .output_mode(output_mode),
    .operand_select(operand_select),
    .pe_mul_us(pe_mul_us),
    .pe_widening(pe_widening),
    .apu_result_select(apu_result_select),
    .clk(clk),
    .n_reset(n_reset),
    .apu_req(apu_req),
    .apu_operands(apu_operands),
    .apu_op(apu_op),
    .apu_flags_i(apu_flags_i),
    .vl(vl)
);

////////////////////////////////////////
// VLSU

////////////////////////////////////////
// VECTOR REGISTERS
logic [127:0] vd_data;
always_comb
    case (vd_data_src)
        VREG_WB_SRC_ARITH:
            vd_data = arith_output;
        // Leave this for now until we know where RAM data will come from
        // VREG_WB_SRC_MEMORY:
        //     vd_data =
        VREG_WB_SRC_SCALAR:
            vd_data = replicated_scalar;
        default:
            vd_data = '0;
    endcase

vector_registers vreg0 (
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vs3_data(vs3_data),
    .vd_data(replicated_scalar), // Presumably this will need some muxing
    .vsew(vsew),
    .elements_to_write(elements_to_write),
    .clk(clk),
    .n_reset(n_reset),
    .write(vec_reg_write),
    .widening_op(widening[0])
);

////////////////////////////////////////
// PEs CONTAINED IN ARITHMETIC STAGE WRAPPER
arith_stage arith_stage0 (
    .arith_outputput(arith_output),
    .replicated_scalar(replicated_scalar),
    .clk(clk),
    .n_reset(n_reset),
    .vs1_data(vs1_data),
    .vs2_data(vs2_data),
    .vs3_data(vs3_data),
    .scalar_operand(scalar_operand1),
    .imm_operand(immediate_operand),
    .elements_to_write(elements_to_write),
    .cycle_count(cycle_count),
    .op(pe_op),
    .saturation_mode(saturation_mode),
    .output_mode(output_mode),
    .operand_select(operand_select),
    .widening(widening),
    .mul_us(pe_mul_us),
    .vl(vl)
);

////////////////////////////////////////////////////////////////////////////////
// RESULT SELECTION - what value to return to CPU
////////////////////////////////////////////////////////////////////////////////
always_comb
begin
    apu_result = '0;
    apu_flags_o = '0;

    case (apu_result_select)
        APU_RESULT_SRC_VL:
            apu_result = {'0, vl};
        APU_RESULT_SRC_VS2_0:
            case (vsew)
                2'd0: // 8b
                    apu_result = { {24{1'b0}}, vs2_data[7:0] };
                2'd1: // 16b
                    apu_result = { {16{1'b0}}, vs2_data[15:0] };
                2'd2:// 32b
                    apu_result = vs2_data[31:0];
            endcase
    endcase
end


endmodule