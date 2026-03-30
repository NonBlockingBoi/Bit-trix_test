import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_lti_execution(dut):
    """Testbench to run the LTI CPU and extract the cycle count."""
    
    # 1. Initialize the 10ns Clock (100 MHz)
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # 2. Apply Reset
    dut._log.info("Applying Reset...")
    dut.rst.value = 1
    await Timer(20, units="ns")
    dut.rst.value = 0
    dut._log.info("Reset lifted. CPU Execution Started!")

    # 3. Monitor Execution
    max_cycles = 5000  # Timeout safeguard
    
    # We poll the 'halted' register inside your top module. 
    # Once your assembly program hits the HLT (1111) instruction, this goes high.
    while dut.halted.value == 0:
        await RisingEdge(dut.clk)
        
        # Prevent infinite loops if assembly is bugged
        if dut.cycle_count.value > max_cycles:
            dut._log.error(f"TIMEOUT: Exceeded {max_cycles} cycles!")
            break

    # 4. Execution Finished - Generate Trace and Metrics
    await RisingEdge(dut.clk) # Wait one more cycle for stability
    
    total_cycles = dut.cycle_count.value.integer
    
    dut._log.info("=================================================")
    dut._log.info("         BIT-TRIX EXECUTION COMPLETE             ")
    dut._log.info("=================================================")
    dut._log.info(f" TOTAL LATENCY:     {total_cycles} Clock Cycles")
    dut._log.info("=================================================")
    
    # Dump final register states for the "Execution Trace" deliverable
    try:
        r0 = dut.regs[0].value.integer
        r1 = dut.regs[1].value.integer
        r2 = dut.regs[2].value.integer
        r3 = dut.regs[3].value.integer
        dut._log.info(f" FINAL REGISTERS:   R0={r0}, R1={r1}, R2={r2}, R3={r3}")
    except Exception as e:
        dut._log.info(" (Could not read internal registers, check wave dump)")
        
    dut._log.info(" Check dump.vcd in GTKWave for full hardware trace.")
    dut._log.info("=================================================")
