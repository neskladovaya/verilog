import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.types import LogicArray, Range

SIZE = 4

async def reset_dut(dut):
    dut.rst_n.value = 0
    await Timer(10, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

def driver(dut, vld, i_we, rdy):
    dut.i_vld.value = int(vld)
    dut.i_rdy.value = int(rdy)
    dut.i_we.value = int(i_we)
    dut.i_a.value = 0

# @cocotb.test()
# async def backpressure(dut):
#
#     cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
#
#     await reset_dut(dut)
#
#     driver(dut, vld=1, i_we=0, rdy=0)
#     for _ in range(10 * SIZE):
#         await RisingEdge(dut.clk)
#     assert dut.o_vld.value == 1

@cocotb.test()
async def idle(dut):

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())

    await reset_dut(dut)

    driver(dut, vld=0, i_we=0, rdy=1)
    for _ in range(SIZE):
        await RisingEdge(dut.clk)
    assert dut.o_vld.value == 0

