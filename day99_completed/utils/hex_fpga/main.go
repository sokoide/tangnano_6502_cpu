// hex_fpga converts an Intel HEX file produced by the examples build
// (srec_cat <bin> -binary -offset 0x0200 -o <hex> -Intel) into the
// SystemVerilog boot_program localparam include consumed by src/cpu.sv.
//
// Validation policy (docs/REVIEW_IMPROVEMENT_PLAN_ja.md R12):
//   - every record starts with ':' and carries exactly its declared payload
//   - hex digits and checksums are verified for every record
//   - supported record types: 00 (data), 01 (EOF, must be the last record),
//     04 (extended linear address, upper 16 bits must be 0x0000 because the
//     6502 address space is 16-bit); all other types are rejected
//   - data must start at 0x0200 and be byte-contiguous: gaps, overlaps, and
//     addresses outside 0x0200-0x1FFF are rejected
//   - at most 7680 bytes (BOOT_CAPACITY); a hex file without any data
//     byte is rejected because the boot loader has no defined empty program
//   - the output is written to a temp file in the destination directory and
//     renamed into place only after a fully successful conversion, so any
//     failure leaves the previous output file untouched
package main

import (
	"bufio"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// Boot program placement contract: linker script examples/baremetal.cfg
// places CODE/DATA at 0x0200 with size 0x1E00, and src/cpu.sv reads the
// boot ROM through boot_program_byte() over 15-bit indices. The two must
// stay in sync.
const (
	bootBaseAddr = 0x0200
	bootCapacity = 7680
)

// hexRecord is one decoded Intel HEX record. data holds only the payload
// bytes (address/checksum fields are validated away).
type hexRecord struct {
	addr       uint16
	recordType int
	data       []byte
}

func hexVal(c byte) (byte, bool) {
	switch {
	case c >= '0' && c <= '9':
		return c - '0', true
	case c >= 'A' && c <= 'F':
		return c - 'A' + 10, true
	case c >= 'a' && c <= 'f':
		return c - 'a' + 10, true
	default:
		return 0, false
	}
}

// decodeHexBytes decodes an even-length ASCII hex string into bytes.
func decodeHexBytes(s string) ([]byte, error) {
	if len(s)%2 != 0 {
		return nil, fmt.Errorf("odd number of hex digits (%d)", len(s))
	}
	out := make([]byte, len(s)/2)
	for i := 0; i < len(s); i += 2 {
		hi, okHi := hexVal(s[i])
		lo, okLo := hexVal(s[i+1])
		if !okHi || !okLo {
			return nil, fmt.Errorf("invalid hex digit %q at offset %d", s[i:i+2], i)
		}
		out[i/2] = hi<<4 | lo
	}
	return out, nil
}

// parseHexLine validates and decodes one Intel HEX record line.
func parseHexLine(line string) (*hexRecord, error) {
	if line == "" || line[0] != ':' {
		return nil, errors.New("record must start with ':'")
	}
	raw, err := decodeHexBytes(line[1:])
	if err != nil {
		return nil, err
	}
	if len(raw) < 5 { // length + addr(2) + type + checksum
		return nil, fmt.Errorf("record too short: %d data bytes present, need at least 1", len(raw)-4)
	}
	length := int(raw[0])
	if len(raw) != 5+length {
		return nil, fmt.Errorf("declared length 0x%02X does not match record: %d data bytes present",
			length, len(raw)-5)
	}
	sum := byte(0)
	for _, b := range raw[:4+length] {
		sum += b
	}
	computed := -sum // two's complement checksum
	given := raw[4+length]
	if computed != given {
		return nil, fmt.Errorf("checksum mismatch: record says 0x%02X, computed 0x%02X", given, computed)
	}
	return &hexRecord{
		addr:       uint16(raw[1])<<8 | uint16(raw[2]),
		recordType: int(raw[3]),
		data:       raw[4 : 4+length],
	}, nil
}

// parseIntelHex reads a whole Intel HEX stream and returns the boot program
// image. It enforces the placement contract described in the file comment.
func parseIntelHex(r io.Reader) ([]byte, error) {
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	var image []byte
	nextAddr := uint32(bootBaseAddr)
	upperAddr := uint32(0) // from type 04 records; must stay 0x0000
	sawFirstData := false
	sawEOF := false
	lineNo := 0

	for sc.Scan() {
		lineNo++
		line := strings.TrimRight(sc.Text(), "\r")
		if line == "" {
			continue
		}
		if sawEOF {
			return nil, fmt.Errorf("line %d: record after EOF record", lineNo)
		}
		rec, err := parseHexLine(line)
		if err != nil {
			return nil, fmt.Errorf("line %d: %w", lineNo, err)
		}
		switch rec.recordType {
		case 0x00: // data
			addr := upperAddr<<16 | uint32(rec.addr)
			if !sawFirstData {
				if addr != bootBaseAddr {
					return nil, fmt.Errorf("line %d: first data record is at 0x%04X, boot program must start at 0x%04X",
						lineNo, addr, bootBaseAddr)
				}
				sawFirstData = true
			} else if addr < nextAddr {
				return nil, fmt.Errorf("line %d: data at 0x%04X overlaps already placed bytes, expected next address 0x%04X",
					lineNo, addr, nextAddr)
			} else if addr > nextAddr {
				return nil, fmt.Errorf("line %d: data at 0x%04X leaves a gap, expected next address 0x%04X",
					lineNo, addr, nextAddr)
			}
			image = append(image, rec.data...)
			nextAddr += uint32(len(rec.data))
			if nextAddr > bootBaseAddr+bootCapacity || len(image) > bootCapacity {
				return nil, fmt.Errorf("line %d: boot program exceeds capacity of %d bytes (0x%04X-0x%04X)",
					lineNo, bootCapacity, bootBaseAddr, bootBaseAddr+bootCapacity-1)
			}
		case 0x01: // EOF
			if len(rec.data) != 0 {
				return nil, fmt.Errorf("line %d: EOF record must not carry data", lineNo)
			}
			if rec.addr != 0 {
				return nil, fmt.Errorf("line %d: EOF record address must be 0x0000, got 0x%04X", lineNo, rec.addr)
			}
			sawEOF = true
		case 0x04: // extended linear address
			if len(rec.data) != 2 {
				return nil, fmt.Errorf("line %d: extended linear address record must carry 2 data bytes, got %d",
					lineNo, len(rec.data))
			}
			if rec.addr != 0 {
				return nil, fmt.Errorf("line %d: extended linear address record address must be 0x0000, got 0x%04X",
					lineNo, rec.addr)
			}
			val := uint32(rec.data[0])<<8 | uint32(rec.data[1])
			if val != 0 {
				return nil, fmt.Errorf("line %d: extended linear address 0x%04X is outside the 16-bit 6502 address space",
					lineNo, val)
			}
			upperAddr = val
		default:
			return nil, fmt.Errorf("line %d: unsupported record type 0x%02X (supported: 00 data, 01 EOF, 04 extended linear address)",
				lineNo, rec.recordType)
		}
	}
	if err := sc.Err(); err != nil {
		return nil, fmt.Errorf("read hex file: %w", err)
	}
	if !sawEOF {
		return nil, errors.New("missing EOF record (:00000001FF)")
	}
	if len(image) == 0 {
		return nil, errors.New("hex file contains no data bytes: empty boot program is not supported")
	}
	return image, nil
}

// renderSV produces the SystemVerilog include: a boot_program_length
// localparam plus a case-based boot_program_byte() function ROM. Each ROM
// bit is then a small logic function of the index, which is safe for Gowin
// synthesis (the previous unpacked-array localparam read with a dynamic
// index lost bit7 of bytes past index 15 on real hardware).
// srcName, when set, is recorded in the header so the day99 build can tell
// which example program is currently embedded.
func renderSV(image []byte, srcName string) string {
	var b strings.Builder
	b.WriteString("// auto generated file\n")
	b.WriteString("// this file has been generated by make in examples directory\n")
	if srcName != "" {
		fmt.Fprintf(&b, "// source: %s\n", srcName)
	}
	fmt.Fprintf(&b, "localparam logic [15:0] boot_program_length = %d;\n", len(image))
	b.WriteString("\n")
	b.WriteString("function automatic logic [7:0] boot_program_byte(input logic [14:0] addr);\n")
	b.WriteString("    case (addr)\n")
	for i, v := range image {
		fmt.Fprintf(&b, "    15'd%d: boot_program_byte = 8'h%02X;\n", i, v)
	}
	b.WriteString("    default: boot_program_byte = 8'hEA;\n")
	b.WriteString("    endcase\n")
	b.WriteString("endfunction\n")
	return b.String()
}

// writeSVFile writes the generated source atomically: a temp file in the
// destination directory is renamed over the destination only after every
// write succeeded, so a failure never destroys the previous output.
func writeSVFile(dest string, image []byte, srcName string) error {
	dir := filepath.Dir(dest)
	tmp, err := os.CreateTemp(dir, "."+filepath.Base(dest)+".tmp*")
	if err != nil {
		return fmt.Errorf("create temp file in %s: %w", dir, err)
	}
	tmpName := tmp.Name()
	renamed := false
	defer func() {
		if !renamed {
			tmp.Close()
			os.Remove(tmpName)
		}
	}()

	// Keep the previous file mode when overwriting; default to 0644.
	mode := os.FileMode(0o644)
	if st, err := os.Stat(dest); err == nil {
		mode = st.Mode().Perm()
	}
	if err := os.Chmod(tmpName, mode); err != nil {
		return fmt.Errorf("set mode on temp file: %w", err)
	}

	w := bufio.NewWriter(tmp)
	if _, err := w.WriteString(renderSV(image, srcName)); err != nil {
		return fmt.Errorf("write temp file: %w", err)
	}
	if err := w.Flush(); err != nil {
		return fmt.Errorf("flush temp file: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		return fmt.Errorf("sync temp file: %w", err)
	}
	if err := tmp.Close(); err != nil {
		return fmt.Errorf("close temp file: %w", err)
	}
	if err := os.Rename(tmpName, dest); err != nil {
		return fmt.Errorf("replace %s: %w", dest, err)
	}
	renamed = true
	return nil
}

// convert runs the full pipeline for one hex file.
func convert(hexPath, svPath, srcName string) error {
	f, err := os.Open(hexPath)
	if err != nil {
		return fmt.Errorf("open hex file: %w", err)
	}
	defer f.Close()
	image, err := parseIntelHex(f)
	if err != nil {
		return err
	}
	return writeSVFile(svPath, image, srcName)
}

func main() {
	hexFilePath := flag.String("hexfile", "", "input Intel HEX file path")
	svFilePath := flag.String("svfile", "", "output SystemVerilog file path")
	srcName := flag.String("srcname", "", "source file name recorded in the output header (optional)")
	flag.Parse()
	if *hexFilePath == "" || *svFilePath == "" {
		fmt.Fprintln(os.Stderr, "usage: hex_fpga -hexfile <input.hex> -svfile <output.sv> [-srcname <source.s>]")
		flag.PrintDefaults()
		os.Exit(2)
	}
	if err := convert(*hexFilePath, *svFilePath, *srcName); err != nil {
		fmt.Fprintf(os.Stderr, "hex_fpga: %s: %v\n", *hexFilePath, err)
		os.Exit(1)
	}
}
