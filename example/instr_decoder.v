import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import subprocess
import os
 
# ─── Main Test ─────────────────────────────────────────────────────────────
@cocotb.test()
async def test_mini_cpu(dut):
    """Full CPU test — PC fetches from instr_ram, data RAM tracked"""
 
    # Step 1: Run opcode_gen.py to generate program.mem
    dut._log.info("Running opcode_gen.py to generate program.mem...")
    subprocess.run(["python3", "opcode_gen.py"], check=True)
    dut._log.info("program.mem generated successfully")
 
    # Step 2: Start clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
 
    # Step 3: Reset
    dut.rst.value = 1
    await Timer(20, units="ns")
    dut.rst.value = 0
    await RisingEdge(dut.clk)
 
    dut._log.info("=" * 65)
    dut._log.info(f"{'Cycle':<7} {'PC':<5} {'Instr':>10}  {'Opcode':<12} {'RAM addr':<10} {'RAM data'}")
    dut._log.info("=" * 65)
 
    # Opcode name lookup
    opcode_names = {
        0b0000: "NOP",
        0b0001: "MAC",
        0b0010: "LOAD_RAM",
        0b0011: "STORE_RAM",
        0b0100: "LOAD_REG",
        0b0101: "STORE_REG",
    }
 
    # Step 4: Run for enough cycles to execute all instructions
    num_instructions = 9  # same as program length in opcode_gen.py
    for _ in range(num_instructions + 2):  # +2 for pipeline delay
        await RisingEdge(dut.clk)
 
        cycle   = dut.cycle_count.value.integer
        pc      = dut.pc.value.integer
        instr   = dut.u_instr_ram.instr_out.value.integer
        opcode  = (instr >> 4) & 0xF
        rs2     = instr & 0x3
        op_name = opcode_names.get(opcode, "???")
 
        # RAM info
        ram_addr = rs2
        ram_data = dut.u_ram.rd_data.value.integer
        ram_wr   = dut.u_decoder.ram_wr_en.value.integer
 
        ram_str = f"addr={ram_addr} data={ram_data}"
        if ram_wr:
            ram_str += " ← WRITE"
 
        dut._log.info(
            f"Cycle {cycle:<4} PC={pc:<4} instr={instr:08b}  {op_name:<12} {ram_str}"
        )
 
    dut._log.info("=" * 65)
    dut._log.info(f"Total cycles: {dut.cycle_count.value.integer}")
    dut._log.info("===== Simulation Complete =====")
