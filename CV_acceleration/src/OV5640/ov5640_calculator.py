"""
OV5640 Camera Configuration Calculator
Reads Verilog configuration files and calculates timing, resolution, and clock parameters.
"""

# pylint:disable=f-string-without-interpolation, line-too-long, invalid-name

import re
import os

VERILOG_PATH = "CV_acceleration/src/OV5640/ov5640_cfg.v"


class OV5640Calculator:
    """Calculator for OV5640 camera configuration based on Verilog files"""

    def __init__(self):
        # OV5640 sensor specifications
        self.SENSOR_WIDTH = 2624
        self.SENSOR_HEIGHT = 1948

        # Important register addresses
        self.REGISTER_MAP = {
            # Clock control
            0x3034: "PLL Bit Divider",
            0x3035: "System Clock Divider",
            0x3036: "PLL Multiplier",
            0x3037: "PLL Pre/Root Divider",
            0x3108: "PCLK/SCLK Divider",
            0x3824: "DVP PCLK Divider",
            # Sensor timing
            0x3800: "X Start High",
            0x3801: "X Start Low",
            0x3802: "Y Start High",
            0x3803: "Y Start Low",
            0x3804: "X End High",
            0x3805: "X End Low",
            0x3806: "Y End High",
            0x3807: "Y End Low",
            # Output size
            0x3808: "Output Width High",
            0x3809: "Output Width Low",
            0x380A: "Output Height High",
            0x380B: "Output Height Low",
            # Timing
            0x380C: "HTS High",
            0x380D: "HTS Low",
            0x380E: "VTS High",
            0x380F: "VTS Low",
            # ISP offsets
            0x3810: "ISP X Offset High",
            0x3811: "ISP X Offset Low",
            0x3812: "ISP Y Offset High",
            0x3813: "ISP Y Offset Low",
            # Binning/Sampling
            0x3814: "X Sample Increment",
            0x3815: "Y Sample Increment",
        }

    def read_verilog_file(self, file_path):
        """Read Verilog file content"""

        # Get cwd
        cwd = os.getcwd()

        # Join with the file path
        file_path = os.path.join(cwd, file_path)

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()
        except FileNotFoundError:
            print(f"Error: File '{file_path}' not found.")
            return None

    def extract_registers_from_verilog(self, verilog_content):
        """Extract register configurations using regex"""
        registers = {}

        # Regex pattern to match register assignments
        # Matches: assign cfg_data_reg[N] = {24'hXXXXXX};
        pattern = r"assign\s+cfg_data_reg\[\d+\]\s*=\s*\{24\'h([0-9a-fA-F]{6})\}"

        matches = re.findall(pattern, verilog_content)

        for match in matches:
            # Parse the 24-bit value: IIAAAAVV (II=ID, AAAA=Address, VV=Value)
            hex_value = match.upper()

            # Extract parts
            reg_addr = int(hex_value[0:4], base=16)
            reg_value = int(hex_value[4:6], base=16)

            registers[reg_addr] = reg_value

        print(f"Extracted {len(registers)} register configurations")
        return registers

    def get_16bit_register(self, registers, high_addr, low_addr):
        """Combine two 8-bit registers into a 16-bit value"""
        high = registers.get(high_addr, 0)
        low = registers.get(low_addr, 0)
        return (high << 8) | low

    def calculate_pll_clocks(self, registers, input_clock_mhz=24):
        """Calculate PLL and pixel clocks from register values with intermediate steps"""

        # Extract register values
        pll_bit_div_reg = registers.get(0x3034, 0)
        sys_config = registers.get(0x3035, 0x21)
        pll_multiplier = registers.get(0x3036, 0)
        pll_config = registers.get(0x3037, 0)
        pclk_config = registers.get(0x3108, 0x01)
        dvp_pclk_div = registers.get(0x3824, 1)

        # Parse individual fields
        # Bit div (0x3034)
        bit_div_value = pll_bit_div_reg & 0x0F
        bit_div = 2.5 if bit_div_value == 0xA else 2.0

        # System Clock Configuration (0x3035)
        sys_div = (sys_config >> 4) & 0x0F
        mipi_div = sys_config & 0x0F

        # PLL Configuration (0x3037)
        pll_pre_div = pll_config & 0x0F
        pll_root_div_bits = (pll_config >> 4) & 0x0F
        pll_root_div = 2 if pll_root_div_bits == 1 else 1

        # PCLK Configuration (0x3108)
        pclk_div_bits = (pclk_config >> 4) & 0x0F
        pclk_div = 1 if pclk_div_bits == 0 else 2
        sclk_div = pclk_config & 0x0F

        # Calculate intermediate steps
        step1_after_multiplier = input_clock_mhz * pll_multiplier
        step2_after_bit_div = step1_after_multiplier / bit_div
        step3_after_sys_div = step2_after_bit_div / sys_div
        step4_after_mipi_div = step3_after_sys_div / mipi_div
        step5_after_pre_div = step4_after_mipi_div / pll_pre_div
        step6_after_root_div = step5_after_pre_div / pll_root_div
        step7_after_pclk_div = step6_after_root_div / pclk_div
        step8_after_sclk_div = step7_after_pclk_div / sclk_div
        pixel_clk = step8_after_sclk_div / dvp_pclk_div

        # Alternative single calculation for verification
        pixel_clk_direct = (
            input_clock_mhz
            * pll_multiplier
            / (
                bit_div
                * sys_div
                * mipi_div
                * pll_pre_div
                * pll_root_div
                * pclk_div
                * sclk_div
                * dvp_pclk_div
            )
        )

        return {
            # Input
            "input_clock_mhz": input_clock_mhz,
            # Raw register values
            "pll_bit_div_reg": pll_bit_div_reg,
            "sys_config_reg": sys_config,
            "pll_multiplier_reg": pll_multiplier,
            "pll_config_reg": pll_config,
            "pclk_config_reg": pclk_config,
            "dvp_pclk_div_reg": dvp_pclk_div,
            # Parsed divider values
            "bit_div_value": bit_div_value,
            "bit_div": bit_div,
            "sys_div": sys_div,
            "mipi_div": mipi_div,
            "pll_multiplier": pll_multiplier,
            "pll_pre_div": pll_pre_div,
            "pll_root_div_bits": pll_root_div_bits,
            "pll_root_div": pll_root_div,
            "pclk_div_bits": pclk_div_bits,
            "pclk_div": pclk_div,
            "sclk_div": sclk_div,
            "dvp_pclk_div": dvp_pclk_div,
            # Intermediate calculation steps
            "step1_after_multiplier": step1_after_multiplier,
            "step2_after_bit_div": step2_after_bit_div,
            "step3_after_sys_div": step3_after_sys_div,
            "step4_after_mipi_div": step4_after_mipi_div,
            "step5_after_pre_div": step5_after_pre_div,
            "step6_after_root_div": step6_after_root_div,
            "step7_after_pclk_div": step7_after_pclk_div,
            "step8_after_sclk_div": step8_after_sclk_div,
            # Final results
            "pixel_clk_mhz": pixel_clk,
            "pixel_clk_direct": pixel_clk_direct,
            "calculation_matches": abs(pixel_clk - pixel_clk_direct) < 0.001,
        }

    def calculate_resolution_and_binning(self, registers):
        """Calculate resolution, binning, and sensor configuration"""

        # Sensor window (cropping)
        x_start = self.get_16bit_register(registers, 0x3800, 0x3801)
        y_start = self.get_16bit_register(registers, 0x3802, 0x3803)
        x_end = self.get_16bit_register(registers, 0x3804, 0x3805)
        y_end = self.get_16bit_register(registers, 0x3806, 0x3807)

        # Output size
        output_width = self.get_16bit_register(registers, 0x3808, 0x3809)
        output_height = self.get_16bit_register(registers, 0x380A, 0x380B)

        # ISP offsets
        isp_x_offset = self.get_16bit_register(registers, 0x3810, 0x3811)
        isp_y_offset = self.get_16bit_register(registers, 0x3812, 0x3813)

        # Binning/sampling increments
        x_inc = registers.get(0x3814, 0x11)
        y_inc = registers.get(0x3815, 0x11)

        # Calculate binning ratios
        # Format: 0xXY where X and Y are the skip pattern
        x_odd_inc = (x_inc >> 4) & 0x0F
        x_even_inc = x_inc & 0x0F
        y_odd_inc = (y_inc >> 4) & 0x0F
        y_even_inc = y_inc & 0x0F

        # Total binning factor
        x_binning = x_odd_inc + x_even_inc
        y_binning = y_odd_inc + y_even_inc

        # Calculate sensor active area
        sensor_active_width = x_end - x_start + 1
        sensor_active_height = y_end - y_start + 1

        # Verify resolution calculation
        # Formula: Output = (Sensor_Active / Binning) - ISP_Offset
        expected_width = sensor_active_width / x_binning - isp_x_offset
        expected_height = sensor_active_height / y_binning - isp_y_offset - 1

        return {
            "sensor_active_width": sensor_active_width,
            "sensor_active_height": sensor_active_height,
            "output_width": output_width,
            "output_height": output_height,
            "x_binning": x_binning,
            "y_binning": y_binning,
            "isp_x_offset": isp_x_offset,
            "isp_y_offset": isp_y_offset,
            "expected_width": expected_width,
            "expected_height": expected_height,
            "width_matches": abs(expected_width - output_width) < 1,
            "height_matches": abs(expected_height - output_height) < 1,
            "x_start": x_start,
            "y_start": y_start,
            "x_end": x_end,
            "y_end": y_end,
            "x_inc_raw": x_inc,
            "y_inc_raw": y_inc,
        }

    def calculate_frame_timing(self, registers, pixel_clk_mhz):
        """Calculate frame timing and rates"""

        # Timing values
        hts = self.get_16bit_register(registers, 0x380C, 0x380D)
        vts = self.get_16bit_register(registers, 0x380E, 0x380F)

        output_width = self.get_16bit_register(registers, 0x3808, 0x3809)
        output_height = self.get_16bit_register(registers, 0x380A, 0x380B)

        # Calculate blanking
        h_blanking = hts - output_width
        v_blanking = vts - output_height

        # Calculate timing
        total_pixels_per_frame = hts * vts

        if pixel_clk_mhz > 0:
            frame_rate = (pixel_clk_mhz * 1_000_000) / total_pixels_per_frame
            line_time_us = hts / pixel_clk_mhz
            frame_time_ms = total_pixels_per_frame / (pixel_clk_mhz * 1000)
        else:
            frame_rate = line_time_us = frame_time_ms = 0

        return {
            "hts": hts,
            "vts": vts,
            "h_blanking": h_blanking,
            "v_blanking": v_blanking,
            "total_pixels_per_frame": total_pixels_per_frame,
            "frame_rate_fps": frame_rate,
            "line_time_us": line_time_us,
            "frame_time_ms": frame_time_ms,
        }

    def print_analysis(self, registers, input_clock_mhz=24):
        """Print complete analysis of the configuration"""

        print("OV5640 Configuration Analysis")
        print("=" * 60)

        # Clock analysis
        clocks = self.calculate_pll_clocks(registers, input_clock_mhz)
        print(f"\n📡 CLOCK CONFIGURATION:")
        print(f"  Input Clock:                    {clocks['input_clock_mhz']:8.1f} MHz")
        print(f"  ─────────────────────────────────────────────────")
        print(f"  Register Values:")
        print(f"    0x3034 (Bit Div):            0x{clocks['pll_bit_div_reg']:02X}")
        print(f"    0x3035 (Sys/MIPI Div):       0x{clocks['sys_config_reg']:02X}")
        print(f"    0x3036 (PLL Multiplier):     0x{clocks['pll_multiplier_reg']:02X}")
        print(f"    0x3037 (PLL Pre/Root):       0x{clocks['pll_config_reg']:02X}")
        print(f"    0x3108 (PCLK/SCLK Div):      0x{clocks['pclk_config_reg']:02X}")
        print(f"    0x3824 (DVP PCLK Div):       0x{clocks['dvp_pclk_div_reg']:02X}")
        print(f"  ─────────────────────────────────────────────────")
        print(f"  Parsed Dividers:")
        print(f"    Bit Divider:                  {clocks['bit_div']:6.1f}")
        print(f"    System Divider:               {clocks['sys_div']:6d}")
        print(f"    MIPI Divider:                 {clocks['mipi_div']:6d}")
        print(f"    PLL Multiplier:               {clocks['pll_multiplier']:6d}")
        print(f"    PLL Pre-divider:              {clocks['pll_pre_div']:6d}")
        print(f"    PLL Root Divider:             {clocks['pll_root_div']:6d}")
        print(f"    PCLK Divider:                 {clocks['pclk_div']:6d}")
        print(f"    SCLK Divider:                 {clocks['sclk_div']:6d}")
        print(f"    DVP PCLK Divider:             {clocks['dvp_pclk_div']:6d}")
        print(f"  ─────────────────────────────────────────────────")
        print(f"  Calculation Steps:")
        print(
            f"    1. After Multiplier:          {clocks['step1_after_multiplier']:8.1f} MHz"
        )
        print(
            f"    2. After Bit Div:             {clocks['step2_after_bit_div']:8.1f} MHz"
        )
        print(
            f"    3. After Sys Div:             {clocks['step3_after_sys_div']:8.1f} MHz"
        )
        print(
            f"    4. After MIPI Div:            {clocks['step4_after_mipi_div']:8.1f} MHz"
        )
        print(
            f"    5. After Pre Div:             {clocks['step5_after_pre_div']:8.1f} MHz"
        )
        print(
            f"    6. After Root Div:            {clocks['step6_after_root_div']:8.1f} MHz"
        )
        print(
            f"    7. After PCLK Div:            {clocks['step7_after_pclk_div']:8.1f} MHz"
        )
        print(
            f"    8. After SCLK Div:            {clocks['step8_after_sclk_div']:8.1f} MHz"
        )
        print(f"    9. Final Pixel Clock:         {clocks['pixel_clk_mhz']:8.1f} MHz")
        print(f"  ─────────────────────────────────────────────────")
        print(f"  Verification:")
        print(
            f"    Direct Calculation:           {clocks['pixel_clk_direct']:8.1f} MHz"
        )
        print(
            f"    Calculations Match:           {'✅' if clocks['calculation_matches'] else '❌'}"
        )

        # Resolution analysis
        resolution = self.calculate_resolution_and_binning(registers)
        print(f"\n🖼️  RESOLUTION & BINNING:")
        print(
            f"  Sensor Window:      {resolution['sensor_active_width']}×{resolution['sensor_active_height']}"
        )
        print(
            f"  Output Resolution:  {resolution['output_width']}×{resolution['output_height']}"
        )
        print(f"  X Binning:          1:{resolution['x_binning']}")
        print(f"  Y Binning:          1:{resolution['y_binning']}")
        print(f"  ISP X Offset:       {resolution['isp_x_offset']}")
        print(f"  ISP Y Offset:       {resolution['isp_y_offset']}")
        print(f"  ─────────────────────────────")
        print(f"  Expected Width:     {resolution['expected_width']:.1f}")
        print(f"  Expected Height:    {resolution['expected_height']:.1f}")
        print(f"  Width Match:        {'✅' if resolution['width_matches'] else '❌'}")
        print(f"  Height Match:       {'✅' if resolution['height_matches'] else '❌'}")

        # Timing analysis
        timing = self.calculate_frame_timing(registers, clocks["pixel_clk_mhz"])
        print(f"\n⏱️  FRAME TIMING:")
        print(f"  HTS (H Total):      {timing['hts']:8d} pixels")
        print(f"  VTS (V Total):      {timing['vts']:8d} lines")
        print(f"  H Blanking:         {timing['h_blanking']:8d} pixels")
        print(f"  V Blanking:         {timing['v_blanking']:8d} lines")
        print(f"  Total Pixels/Frame: {timing['total_pixels_per_frame']:8,d}")
        print(f"  ─────────────────────────────")
        print(f"  Frame Rate:         {timing['frame_rate_fps']:8.3f} fps")
        print(f"  Line Time:          {timing['line_time_us']:8.2f} μs")
        print(f"  Frame Time:         {timing['frame_time_ms']:8.2f} ms")

        # Show key registers
        print(f"\n🔧 KEY REGISTER VALUES:")
        key_regs = [
            0x3036,
            0x3037,
            0x3035,
            0x3108,
            0x380C,
            0x380D,
            0x380E,
            0x380F,
            0x3808,
            0x3809,
            0x380A,
            0x380B,
            0x3814,
            0x3815,
        ]

        for addr in key_regs:
            if addr in registers:
                name = self.REGISTER_MAP.get(addr, f"Register 0x{addr:04X}")
                print(f"  0x{addr:04X}: 0x{registers[addr]:02X}  ({name})")

    def analyze_verilog_file(self, file_path, input_clock_mhz=24):
        """Main function to analyze a Verilog configuration file"""

        # Read file
        verilog_content = self.read_verilog_file(file_path)
        if verilog_content is None:
            return None

        # Extract registers
        registers = self.extract_registers_from_verilog(verilog_content)
        if not registers:
            print("No register configurations found in the file.")
            return None

        # Print analysis
        self.print_analysis(registers, input_clock_mhz)

        # Return all calculated data
        clocks = self.calculate_pll_clocks(registers, input_clock_mhz)
        resolution = self.calculate_resolution_and_binning(registers)
        timing = self.calculate_frame_timing(registers, clocks["pixel_clk_mhz"])

        return {
            "registers": registers,
            "clocks": clocks,
            "resolution": resolution,
            "timing": timing,
        }


if __name__ == "__main__":
    input_clock = 24.0

    calculator = OV5640Calculator()
    result = calculator.analyze_verilog_file(VERILOG_PATH, input_clock)
