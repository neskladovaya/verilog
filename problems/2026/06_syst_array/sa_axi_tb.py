import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

from cocotbext.axi import AxiBus, AxiSlave, AxiRam, AxiLiteMaster, AxiLiteBus

import numpy as np

WIDTH = 16
SIZE = 4
ADDR = 0x0;

class TB:
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.INFO)

        self.setup_axi_slave()
        self.setup_axil_master()

        self.matrix_a = None
        self.matrix_b = None
        self.matrix_c_rec = None
        self.matrix_c_exp = None

        self.matrix_a_addr = 0x1000
        self.matrix_b_addr = 0x2000
        self.matrix_c_addr = 0x3000


    def setup_axi_slave(self):
        self.log.info("Initializing AXI RAM...")

        self.axi_ram = AxiRam(
            AxiBus.from_prefix(self.dut, "m_axi"),
            self.dut.clk,
            self.dut.rst_n,
            reset_active_level=False,
            size=2**16
        )

        self.log.info("AXI RAM initialized")

    def setup_axil_master(self):
        self.log.info("Initializing AXIL Master...")

        self.axil = AxiLiteMaster(
            AxiLiteBus.from_prefix(self.dut, "s_axil"),
            self.dut.clk,
            self.dut.rst_n,
            reset_active_level=False
        )

        self.log.info("AXIL Master initialized")

    async def reset(self):
        self.log.info("Resetting environment...")

        self.dut.rst_n.value = 0
        await ClockCycles(self.dut.clk, 1)
        self.dut.rst_n.value = 1
        await ClockCycles(self.dut.clk, 1)

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
        await ClockCycles(self.dut.clk, 5)


    async def monitor(self, addr, rows, cols):
        byte_len = rows * cols * 2
        byte_data = self.axi_ram.read(addr, byte_len)
        matrix = self.axi2mat(byte_data, rows, cols)
        return matrix


    async def drive_b(self):
        self.matrix_b = self.seq(SIZE, SIZE)

        await self.driver(
            self.matrix_b_addr,
            self.matrix_b,
            True
        )

        resp = await self.axil.write(ADDR, self.matrix_b_addr.to_bytes(4, 'little'))

        await ClockCycles(self.dut.clk, 4 * SIZE)


    async def drive_a(self):
        self.matrix_a = self.seq(SIZE, SIZE)

        await self.driver(
            self.matrix_a_addr,
            self.matrix_a,
            False
        )

        resp = await self.axil.write(ADDR, self.matrix_a_addr.to_bytes(4, 'little'))
        resp = await self.axil.write(ADDR, self.matrix_c_addr.to_bytes(4, 'little'))

        await ClockCycles(self.dut.clk, 4 * SIZE)


    async def monitor_c(self):
        self.matrix_c_rec = await self.monitor(self.matrix_c_addr, SIZE, SIZE)


    async def predictor(self):
        self.matrix_c_exp = np.zeros((SIZE, SIZE), dtype=np.int16)
        for i in range(SIZE):
            for j in range(SIZE):
                c = 0;
                for k in range(SIZE):
                    c += self.matrix_a[i][k] * self.matrix_b[k][j]
                self.matrix_c_exp[i][j] = c


    async def comparator(self):
        await self.predictor()

        error = np.any(self.matrix_c_rec != self.matrix_c_exp)

        self.log.info("A")
        self.log.info(self.matrix_a)
        self.log.info("B")
        self.log.info(self.matrix_b)
        self.log.info("REC C")
        self.log.info(self.matrix_c_rec)
        self.log.info("EXP C")
        self.log.info(self.matrix_c_exp)

        if error:
            self.log.error("ERROR")
        else:
            self.log.info("PASS")


    async def scoreboard(self):
        await self.drive_b()

        await self.drive_a()

        await self.monitor_c()

        await self.comparator()


@cocotb.test()
async def test_matmul(dut):
    tb = TB(dut)

    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    await tb.reset()

    await tb.scoreboard()


