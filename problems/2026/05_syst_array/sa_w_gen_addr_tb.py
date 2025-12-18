import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiRam

import numpy as np

WIDTH = 16
SIZE = 4

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.INFO)

        self.setup_axi_slave()

        self.matrix_a = None
        self.matrix_b = None
        self.matrix_c_rec = None
        self.matrix_c_exp = None

        self.test_data_a = None
        self.test_data_b = None

    def setup_axi_slave(self):
        self.log.info("initializing AXI RAM...")

        self.axi_ram = AxiRam(
            AxiBus.from_prefix(self.dut, "m_axi"),
            self.dut.clk,
            self.dut.rst_n,
            reset_active_level=False,
            size=2**16
        )

        self.log.info("AXI RAM initialized")

    async def reset(self):
        self.log.info("Resetting environment...")

        self.dut.rst_n.value = 0

        self.dut.i_addr_gen_en.value = 0
        self.dut.addr_a.value = 0x1000
        self.dut.addr_b.value = 0x2000
        self.dut.addr_c.value = 0x3000

        await ClockCycles(self.dut.clk, 1)
        self.dut.rst_n.value = 1

        self.log.info("Reset complete")

    def seq(self, rows, cols):
        matrix = np.zeros((rows, cols), dtype=np.uint16)
        for i in range(rows):
            for j in range(cols):
                matrix[i][j] = i * cols + j + 1
        return matrix

    def mat2axi(self, matrix, i_we):
        rows, cols = matrix.shape
        byte_data = bytearray()

        for i in range(cols):
            for j in range(rows):
                if (i_we):
                    byte_data.extend(matrix[j][i].tobytes())
                else:
                    byte_data.extend(matrix[i][j].tobytes())
        return bytes(byte_data)

    def axi2mat(self, byte_data, rows, cols):
        matrix = np.zeros((rows, cols), dtype=np.uint16)

        for i in range(rows):
            for j in range(cols):
                idx = (i * cols + j) * 2
                if idx + 1 < len(byte_data):
                    matrix[i][SIZE-j-1] = int.from_bytes(byte_data[idx:idx+2], 'little')

        return matrix

    async def driver(self, addr, matrix, i_we):
        byte_data = self.mat2axi(matrix, i_we)
        self.axi_ram.write(addr, byte_data)

    async def monitor(self, addr, rows, cols):
        byte_len = rows * cols * 2
        byte_data = self.axi_ram.read(addr, byte_len)
        matrix = self.axi2mat(byte_data, rows, cols)
        return matrix

    async def drive_b(self):
        self.test_data_b = self.seq(SIZE, SIZE)
        self.dut.i_we.value = 1

        await self.driver(
            self.dut.addr_b.value.integer,
            self.test_data_b,
            True
        )

        self.dut.i_addr_gen_en.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.i_addr_gen_en.value = 0

        return True

    async def drive_a(self):
        self.test_data_a = self.seq(SIZE, SIZE)
        self.dut.i_we.value = 0

        await self.driver(
            self.dut.addr_a.value.integer,
            self.test_data_a,
            False
        )

        self.dut.i_addr_gen_en.value = 1
        await RisingEdge(self.dut.clk)
        self.dut.i_addr_gen_en.value = 0

        return True

    async def monitor_c(self):
        await ClockCycles(self.dut.clk, SIZE*SIZE-2)

        self.matrix_c_rec = await self.monitor(
            self.dut.addr_c.value.integer,
            SIZE,
            SIZE
        )

        return True

    async def predictor(self):
        self.matrix_c_exp = np.zeros((SIZE, SIZE), dtype=np.int16)
        for i in range(SIZE):
            for j in range(SIZE):
                c = 0;
                for k in range(SIZE):
                    c += self.test_data_a[i][k] * self.test_data_b[k][j]
                self.matrix_c_exp[i][j] = c

    async def comparator(self):

        await self.predictor()

        error = np.any(self.matrix_c_rec != self.matrix_c_exp)

        self.log.info("A")
        self.log.info(self.test_data_a)
        self.log.info("B")
        self.log.info(self.test_data_b)
        self.log.info("REC C")
        self.log.info(self.matrix_c_rec)
        self.log.info("EXP C")
        self.log.info(self.matrix_c_exp)

        if error:
            self.log.error("ERROR")
        else:
            self.log.info("PASS")

    async def scoreboard(self):
        await ClockCycles(self.dut.clk, 10)

        await self.drive_b(start)

        await ClockCycles(self.dut.clk, SIZE+1)

        await self.drive_a()

        await ClockCycles(self.dut.clk, SIZE*SIZE-2)

        await self.monitor_c()

        await self.comparator()

@cocotb.test()
async def test_matmul(dut):
    tb = TB(dut)

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    await tb.scoreboard(0)

