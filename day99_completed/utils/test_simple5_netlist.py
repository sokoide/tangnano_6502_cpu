#!/usr/bin/env python3
"""Check a Gowin 9K post-PNR functional netlist against simple5's RAM writes.

This forces the synthesized memory/pixel clocks, resets and VSYNC, so it checks
combinational/sequential netlist function, not PLL, reset synchronizers, LCD
timing, gate delays, or physical-board operation. It requires Gowin's current
flat ``.vo`` hierarchy and stops if the required probes cannot be identified.
The temporary LUT replacement avoids Verilator's expensive recursive MUX LUT
simulation and changes no vendor or generated source in place.
"""

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PRIM_DEFAULT = ROOT / "deps/gw1n/prim_sim.v"


def must(pattern: str, source: str, label: str) -> re.Match[str]:
    found = re.search(pattern, source, re.MULTILINE | re.DOTALL)
    if not found:
        raise ValueError(f"unsupported netlist: missing {label}")
    return found


def probe(net: str, source: str) -> str:
    net = net.strip()
    # Bit-select of a declared bus, e.g. `\u_core/din [0]`: an escaped
    # identifier followed by an index (Gowin keeps the bus intact in .vo).
    sel = re.fullmatch(r"(\\\S+) \[(\d+)\]", net)
    if sel:
        base = sel.group(1)
        if not re.search(r"(?:^|\n)wire(?:\s+\[[^\]]+\])?\s+" + re.escape(base) + r"\s*;", source):
            raise ValueError(f"unsupported netlist: undeclared probe {net}")
        return f"dut.{base} [{sel.group(2)}]"
    if net.startswith("\\"):
        # Escaped Verilog identifiers require a terminating space.
        if not re.search(r"(?:^|\n)wire(?:\s+\[[^\]]+\])?\s+" + re.escape(net) + r"\s*;", source):
            raise ValueError(f"unsupported netlist: undeclared probe {net}")
        return f"dut.{net} "
    if not re.fullmatch(r"[a-zA-Z_][a-zA-Z_0-9]*", net):
        raise ValueError(f"unsupported netlist: invalid probe {net}")
    if not re.search(r"(?:^|\n)wire(?:\s+\[[^\]]+\])?\s+" + re.escape(net) + r"\s*;", source):
        raise ValueError(f"unsupported netlist: undeclared probe {net}")
    return f"dut.{net}"


def instance_ports(source: str, index: int) -> dict[str, str]:
    name = rf"\\u_core/ram_inst/vendor\.ram_inst/sdpb_inst_{index}\s+"
    body = must(rf"SDPB\s+{name}\(\s*(.*?)\s*\);", source, f"SDPB {index}").group(1)
    ports = {}
    for key in ("CLKA", "CEA", "DI"):
        ports[key] = must(rf"\.{key}\((.*?)\)", body, f"SDPB {index}.{key}").group(1).strip()
    return ports


def make_prim_copy(original: str) -> str:
    for n in range(1, 9):
        inputs = ", ".join(f"I{i}" for i in range(n))
        replacement = (
            f"module LUT{n}(output F, input {inputs});\n"
            f"parameter [{(1 << n) - 1}:0] INIT = 0;\n"
            f"assign F = INIT[{{{', '.join(f'I{i}' for i in reversed(range(n)))}}}];\n"
            "endmodule\n"
        )
        original, count = re.subn(
            rf"module LUT{n}\s*\(.*?endmodule\s*//\s*lut{n}\b",
            lambda _: replacement,
            original,
            count=1,
            flags=re.DOTALL | re.IGNORECASE,
        )
        if count != 1:
            raise ValueError(f"unsupported primitive library: LUT{n} definition absent")
    return original


def make_tb(source: str) -> str:
    required = ("MEMORY_CLK_d", "LCD_CLK_d", r"\u_core/memory_rst_n",
                r"\u_core/pixel_rst_n", r"\u_core/vsync_Z", r"\u_core/ada")
    for net in required:
        probe(net, source)
    ports = [instance_ports(source, i) for i in range(0, 16, 2)]
    clocks = {p["CLKA"] for p in ports}
    enables = {p["CEA"] for p in ports}
    if len(clocks) != 1 or len(enables) != 1:
        raise ValueError("unsupported netlist: SDPB write clocks/enables differ")
    bits = []
    for bit, p in enumerate(ports):
        di = p["DI"]
        tokens = [item.strip() for item in must(r"^\{(.*)\}$", di, f"SDPB {2*bit}.DI").group(1).split(",")]
        if len(tokens) != 32:
            raise ValueError(f"unsupported netlist: SDPB {2*bit} DI width")
        bits.append(probe(tokens[-1], source))
    data = ", ".join(reversed(bits))
    write_clk = probe(next(iter(clocks)), source)
    write_en = probe(next(iter(enables)), source)
    addr = probe(r"\u_core/ada", source)
    return f'''`timescale 1ns/1ps
module tb_simple5_netlist;
  GSR GSR(.GSRI(1'b1));
  logic clk=0, rst_n=0, vsync=0;
  always #18.518519 clk=~clk;
  always #1851.8519 vsync=~vsync;
  top dut(.ResetButton(rst_n),.XTAL_IN(clk));
  initial begin
    force {probe('MEMORY_CLK_d', source)} = clk;
    force {probe('LCD_CLK_d', source)} = clk;
    force {probe(r'\u_core/memory_rst_n', source)} = rst_n;
    force {probe(r'\u_core/pixel_rst_n', source)} = rst_n;
    force {probe(r'\u_core/vsync_Z', source)} = vsync;
    #200; rst_n=1;
    #50000000; $fatal(1,"simple5 netlist timeout");
  end
  wire [7:0] data = {{{data}}};
  integer samples=0;
  logic [7:0] expected=8'h20;
  always @(posedge {write_clk}) if(rst_n && {write_en} && {addr}==15'h0001) begin
    $display("sample %0d A stored=%02x expected=%02x",samples,data,expected);
    if(data !== expected) $fatal(1,"simple5 netlist mismatch");
    samples=samples+1;
    expected=expected==8'h7e ? 8'h20 : expected+1;
    if(samples==100) begin $display("PASS simple5 post-PNR full sweep and wrap"); $finish; end
  end
endmodule
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--netlist", type=Path, default=ROOT / "impl/pnr/day99_9k.vo")
    parser.add_argument("--primitives", type=Path, default=PRIM_DEFAULT)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "build/debug-simple5/netlist")
    parser.add_argument("--verilator", default="verilator")
    args = parser.parse_args()
    netlist_path = args.netlist.resolve()
    primitives_path = args.primitives.resolve()
    netlist_bytes = netlist_path.read_bytes()
    primitive_bytes = primitives_path.read_bytes()
    netlist = netlist_bytes.decode()
    primitive = primitive_bytes.decode()
    out = args.output_dir.resolve()
    out.mkdir(parents=True, exist_ok=True)
    design_copy = out / "design.vo"
    design_copy.write_bytes(netlist_bytes)
    (out / "receipt.json").write_text(json.dumps({
        "netlist_path": str(netlist_path),
        "netlist_sha256": hashlib.sha256(netlist_bytes).hexdigest(),
        "primitives_path": str(primitives_path),
        "primitives_sha256": hashlib.sha256(primitive_bytes).hexdigest(),
    }, indent=2) + "\n")
    (out / "tb_simple5_netlist.sv").write_text(make_tb(netlist))
    (out / "prim_direct_lut.v").write_text(make_prim_copy(primitive))
    binary = out / "obj_dir" / "Vtb_simple5_netlist"
    compile_cmd = [args.verilator, "--binary", "--top-module", "tb_simple5_netlist",
                   "-O0", "-j", "4", "--timing", "--assert", "-Wno-fatal",
                   "-Wno-BLKANDNBLK", "--Mdir", str(out / "obj_dir"),
                   str(out / "tb_simple5_netlist.sv"), str(design_copy),
                   str(out / "prim_direct_lut.v")]
    with (out / "compile.log").open("w") as log:
        result = subprocess.run(compile_cmd, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print(f"compile failed: {out / 'compile.log'}", file=sys.stderr)
        return result.returncode
    with (out / "run.log").open("w") as log:
        result = subprocess.run([str(binary)], cwd=ROOT, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print(f"simulation failed: {out / 'run.log'}", file=sys.stderr)
        return result.returncode
    if "PASS simple5 post-PNR full sweep and wrap" not in (out / "run.log").read_text():
        print(f"simulation ended without PASS: {out / 'run.log'}", file=sys.stderr)
        return 1
    print(f"PASS simple5 post-PNR full sweep and wrap ({out / 'run.log'})")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError) as exc:
        print(exc, file=sys.stderr)
        sys.exit(2)
