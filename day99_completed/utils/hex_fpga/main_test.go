package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// rec builds one data record line for the given absolute address.
func rec(t *testing.T, addr uint16, data ...byte) string {
	t.Helper()
	sum := byte(len(data)) + byte(addr>>8) + byte(addr) + byte(0x00)
	for _, b := range data {
		sum += b
	}
	var sb strings.Builder
	sb.WriteString(":")
	sb.WriteString(hex2(len(data)))
	sb.WriteString(hex2(int(addr>>8)) + hex2(int(addr&0xFF)))
	sb.WriteString("00")
	for _, b := range data {
		sb.WriteString(hex2(int(b)))
	}
	sb.WriteString(hex2(int(-sum)))
	return sb.String()
}

func hex2(v int) string {
	const digits = "0123456789ABCDEF"
	return string([]byte{digits[(v>>4)&0xF], digits[v&0xF]})
}

const eofRecord = ":00000001FF"
const elaZero = ":020000040000FA" // srec_cat emits this before data records

func parse(t *testing.T, hexText string) ([]byte, error) {
	t.Helper()
	return parseIntelHex(strings.NewReader(hexText))
}

// --- placement ---

func TestTwoRecordPlacement(t *testing.T) {
	hexText := strings.Join([]string{
		elaZero,
		rec(t, 0x0200, 0xA9, 0x20),
		rec(t, 0x0202, 0xCF),
		eofRecord,
	}, "\n")
	image, err := parse(t, hexText)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	want := []byte{0xA9, 0x20, 0xCF}
	if len(image) != len(want) {
		t.Fatalf("image length = %d, want %d", len(image), len(want))
	}
	for i, b := range want {
		if image[i] != b {
			t.Errorf("image[%d] = 0x%02X, want 0x%02X", i, image[i], b)
		}
	}
}

func TestTwoRecordPlacementMultipleBytesPerRecord(t *testing.T) {
	data1 := make([]byte, 16)
	data2 := make([]byte, 4)
	for i := range data1 {
		data1[i] = byte(i)
	}
	for i := range data2 {
		data2[i] = byte(0xF0 + i)
	}
	hexText := strings.Join([]string{
		rec(t, 0x0200, data1...),
		rec(t, 0x0210, data2...),
		eofRecord,
	}, "\n")
	image, err := parse(t, hexText)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(image) != 20 {
		t.Fatalf("image length = %d, want 20", len(image))
	}
	for i, b := range data1 {
		if image[i] != b {
			t.Errorf("image[%d] = 0x%02X, want 0x%02X", i, image[i], b)
		}
	}
	for i, b := range data2 {
		if image[16+i] != b {
			t.Errorf("image[%d] = 0x%02X, want 0x%02X", 16+i, image[16+i], b)
		}
	}
}

func TestFirstRecordMustStartAt0200(t *testing.T) {
	for _, addr := range []uint16{0x0000, 0x01FF, 0x0201, 0x8000, 0xE000} {
		_, err := parse(t, rec(t, addr, 0xEA)+"\n"+eofRecord)
		if err == nil {
			t.Fatalf("address 0x%04X accepted, want rejection", addr)
		}
		if !strings.Contains(err.Error(), "start at 0x0200") {
			t.Errorf("address 0x%04X: error lacks start-address hint: %v", addr, err)
		}
	}
}

func TestOverlapRejected(t *testing.T) {
	hexText := strings.Join([]string{
		rec(t, 0x0200, 0x01, 0x02, 0x03),
		rec(t, 0x0202, 0x04), // overlaps byte 2 of the first record
		eofRecord,
	}, "\n")
	_, err := parse(t, hexText)
	if err == nil {
		t.Fatal("overlap accepted, want rejection")
	}
	if !strings.Contains(err.Error(), "overlap") {
		t.Errorf("error lacks overlap explanation: %v", err)
	}
}

func TestGapRejected(t *testing.T) {
	hexText := strings.Join([]string{
		rec(t, 0x0200, 0x01, 0x02, 0x03),
		rec(t, 0x0205, 0x04), // skips 0x0203-0x0204
		eofRecord,
	}, "\n")
	_, err := parse(t, hexText)
	if err == nil {
		t.Fatal("gap accepted, want rejection")
	}
	if !strings.Contains(err.Error(), "gap") {
		t.Errorf("error lacks gap explanation: %v", err)
	}
}

// --- record syntax ---

func TestRecordSyntaxRejected(t *testing.T) {
	cases := []struct {
		name string
		line string
		want string
	}{
		{"missing colon", "19020000A9204C0202F1", "must start with ':'"},
		{"odd digits", ":19020000A9204C0202F", "odd number of hex digits"},
		{"invalid hex digit", ":1902000GA920", "invalid hex digit"},
		{"short record", ":04020000A9", "does not match record"},
		{"long record", ":02020000A9204CA0", "does not match record"},
		{"truncated header", ":0204", "too short"},
		{"lowercase hex accepted", ":02020000a9b0a3", ""}, // valid, checked below
	}
	for _, tc := range cases {
		_, err := parseHexLine(tc.line)
		if tc.want == "" {
			if err != nil {
				t.Errorf("%s: unexpected error: %v", tc.name, err)
			}
			continue
		}
		if err == nil {
			t.Errorf("%s: accepted, want rejection", tc.name)
			continue
		}
		if !strings.Contains(err.Error(), tc.want) {
			t.Errorf("%s: error %q lacks %q", tc.name, err, tc.want)
		}
	}
}

func TestChecksumRejected(t *testing.T) {
	good := rec(t, 0x0200, 0xA9)
	bad := good[:len(good)-2] + "00" // break the checksum byte
	if good == bad {
		t.Fatal("test setup broken: bad record equals good record")
	}
	_, err := parse(t, bad+"\n"+eofRecord)
	if err == nil {
		t.Fatal("bad checksum accepted, want rejection")
	}
	if !strings.Contains(err.Error(), "checksum mismatch") {
		t.Errorf("error lacks checksum explanation: %v", err)
	}
	if !strings.Contains(err.Error(), "line 1") {
		t.Errorf("error lacks line number: %v", err)
	}
}

// --- EOF ordering ---

func TestEOFOrdering(t *testing.T) {
	data := rec(t, 0x0200, 0xEA)

	if _, err := parse(t, data); err == nil || !strings.Contains(err.Error(), "missing EOF") {
		t.Errorf("missing EOF: err = %v, want missing EOF rejection", err)
	}
	if _, err := parse(t, strings.Join([]string{data, eofRecord, data}, "\n")); err == nil ||
		!strings.Contains(err.Error(), "after EOF") {
		t.Errorf("record after EOF: err = %v, want after-EOF rejection", err)
	}
	if _, err := parse(t, strings.Join([]string{data, eofRecord, ""}, "\n")); err != nil {
		t.Errorf("trailing blank line rejected: %v", err)
	}
	// EOF with payload / non-zero address: forge raw lines with fixed checksums.
	if _, err := parse(t, ":0100010155A8\n"); err == nil ||
		!strings.Contains(err.Error(), "EOF record must not carry data") {
		t.Errorf("EOF with data: err = %v, want rejection", err)
	}
	if _, err := parse(t, ":00000101FE\n"); err == nil ||
		!strings.Contains(err.Error(), "EOF record address") {
		t.Errorf("EOF with address: err = %v, want rejection", err)
	}
}

func TestEmptyDataRejected(t *testing.T) {
	_, err := parse(t, eofRecord)
	if err == nil {
		t.Fatal("EOF-only file accepted, want rejection")
	}
	if !strings.Contains(err.Error(), "no data bytes") {
		t.Errorf("error lacks empty-program explanation: %v", err)
	}
	// A zero-length data record does not count as data either.
	_, err = parse(t, ":00020000FE\n"+eofRecord)
	if err == nil || !strings.Contains(err.Error(), "no data bytes") {
		t.Errorf("zero-length data record: err = %v, want no-data rejection", err)
	}
}

// --- record types ---

func TestUnsupportedRecordTypes(t *testing.T) {
	cases := []struct {
		name string
		line string
	}{
		{"extended segment address", ":020000020000FC"},
		{"start segment address", ":0400000312345678E5"},
		{"start linear address", ":040000050123456727"},
		{"unknown type", ":00000006FA"},
	}
	for _, tc := range cases {
		_, err := parse(t, rec(t, 0x0200, 0xEA)+"\n"+tc.line+"\n"+eofRecord)
		if err == nil {
			t.Errorf("%s: accepted, want rejection", tc.name)
			continue
		}
		if !strings.Contains(err.Error(), "unsupported record type") {
			t.Errorf("%s: error %q lacks unsupported-record-type explanation", tc.name, err)
		}
	}
}

func TestExtendedLinearAddress(t *testing.T) {
	// upper 16 bits = 0 is accepted (srec_cat emits it), anything else rejected
	if _, err := parse(t, elaZero+"\n"+rec(t, 0x0200, 0xEA)+"\n"+eofRecord); err != nil {
		t.Errorf("ELA 0x0000 rejected: %v", err)
	}
	_, err := parse(t, ":020000040001F9\n"+rec(t, 0x0200, 0xEA)+"\n"+eofRecord)
	if err == nil || !strings.Contains(err.Error(), "outside the 16-bit") {
		t.Errorf("ELA 0x0001: err = %v, want out-of-range rejection", err)
	}
	_, err = parse(t, ":03000004000000F9\n") // wrong payload length
	if err == nil || !strings.Contains(err.Error(), "must carry 2 data bytes") {
		t.Errorf("ELA wrong length: err = %v, want rejection", err)
	}
	// checksum-valid ELA record with a non-zero address field must be rejected
	// (address bits must be 0x0000; only the payload carries meaning)
	sum := byte(0x02) + byte(0x12>>8) + byte(0x12) + byte(0x04) + byte(0x00) + byte(0x00)
	elaBadAddr := ":020012" + "04" + "0000" + hex2(int(-sum))
	_, err = parse(t, elaBadAddr+"\n"+rec(t, 0x0200, 0xEA)+"\n"+eofRecord)
	if err == nil || !strings.Contains(err.Error(), "address must be 0x0000") {
		t.Errorf("ELA with address field: err = %v, want address rejection", err)
	}
}

// --- capacity ---

func TestCapacity(t *testing.T) {
	chunk := make([]byte, 255)
	for i := range chunk {
		chunk[i] = byte(i)
	}

	// exactly 7680 bytes must fit (0x0200-0x1FFF)
	var lines []string
	addr := uint16(0x0200)
	remaining := 7680
	for remaining > 0 {
		n := 255
		if remaining < n {
			n = remaining
		}
		lines = append(lines, rec(t, addr, chunk[:n]...))
		addr += uint16(n)
		remaining -= n
	}
	lines = append(lines, eofRecord)
	if _, err := parse(t, strings.Join(lines, "\n")); err != nil {
		t.Fatalf("7680-byte program rejected: %v", err)
	}

	// exactly one byte beyond capacity (7681) must be rejected
	lines2 := []string{}
	addr = 0x0200
	remaining = bootCapacity + 1
	for remaining > 0 {
		n := 255
		if remaining < n {
			n = remaining
		}
		lines2 = append(lines2, rec(t, addr, chunk[:n]...))
		addr += uint16(n)
		remaining -= n
	}
	lines2 = append(lines2, eofRecord)
	_, err := parse(t, strings.Join(lines2, "\n"))
	if err == nil || !strings.Contains(err.Error(), "exceeds capacity") {
		t.Errorf("7681-byte program: err = %v, want capacity rejection", err)
	}
}

// --- output layout and atomic writes ---

func TestRenderSVLayout(t *testing.T) {
	got := renderSV([]byte{0xEA}, "")
	want := "// auto generated file\n" +
		"// this file has been generated by make in examples directory\n" +
		"localparam logic [15:0] boot_program_length = 1;\n" +
		"\n" +
		"function automatic logic [7:0] boot_program_byte(input logic [14:0] addr);\n" +
		"    case (addr)\n" +
		"    15'd0: boot_program_byte = 8'hEA;\n" +
		"    default: boot_program_byte = 8'hEA;\n" +
		"    endcase\n" +
		"endfunction\n"
	if got != want {
		t.Errorf("renderSV layout changed:\ngot:\n%s\nwant:\n%s", got, want)
	}
}

func TestRenderSVSourceName(t *testing.T) {
	got := renderSV([]byte{0xEA}, "simple5.s")
	want := "// auto generated file\n" +
		"// this file has been generated by make in examples directory\n" +
		"// source: simple5.s\n"
	if !strings.HasPrefix(got, want) {
		t.Errorf("renderSV source header missing:\ngot:\n%s\nwant prefix:\n%s", got, want)
	}
}

func TestConvertWritesFile(t *testing.T) {
	dir := t.TempDir()
	hexPath := filepath.Join(dir, "in.hex")
	svPath := filepath.Join(dir, "boot.sv")
	hexText := strings.Join([]string{
		elaZero,
		rec(t, 0x0200, 0xA9, 0x20),
		rec(t, 0x0202, 0xCF),
		eofRecord,
	}, "\n")
	if err := os.WriteFile(hexPath, []byte(hexText), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := convert(hexPath, svPath, ""); err != nil {
		t.Fatalf("convert: %v", err)
	}
	out, err := os.ReadFile(svPath)
	if err != nil {
		t.Fatal(err)
	}
	s := string(out)
	for _, want := range []string{
		"localparam logic [15:0] boot_program_length = 3;",
		"15'd0: boot_program_byte = 8'hA9;",
		"15'd1: boot_program_byte = 8'h20;",
		"15'd2: boot_program_byte = 8'hCF;",
		"default: boot_program_byte = 8'hEA;",
		"endfunction",
	} {
		if !strings.Contains(s, want) {
			t.Errorf("output lacks %q", want)
		}
	}
	if fi, err := os.Stat(svPath); err != nil {
		t.Fatal(err)
	} else if fi.Mode().Perm() != 0o644 {
		t.Errorf("output mode = %v, want 0644", fi.Mode().Perm())
	}
	// no temp files left behind
	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 2 { // in.hex + boot.sv
		t.Errorf("leftover files: %v", entries)
	}
}

func TestConvertPreservesDestinationOnInvalidInput(t *testing.T) {
	dir := t.TempDir()
	hexPath := filepath.Join(dir, "in.hex")
	svPath := filepath.Join(dir, "boot.sv")
	old := "previous generated content\n"
	if err := os.WriteFile(svPath, []byte(old), 0o644); err != nil {
		t.Fatal(err)
	}
	// checksum-corrupted record
	good := rec(t, 0x0200, 0xA9)
	bad := good[:len(good)-2] + "00" // replace the full checksum byte
	if err := os.WriteFile(hexPath, []byte(bad+"\n"+eofRecord+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	err := convert(hexPath, svPath, "")
	if err == nil {
		t.Fatal("convert with corrupted hex succeeded, want failure")
	}
	if !strings.Contains(err.Error(), "checksum mismatch") {
		t.Errorf("error lacks checksum explanation: %v", err)
	}
	got, err := os.ReadFile(svPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != old {
		t.Errorf("destination modified on failure:\ngot:  %q\nwant: %q", got, old)
	}
	entries, _ := os.ReadDir(dir)
	if len(entries) != 2 { // in.hex + boot.sv, no temp leftovers
		t.Errorf("leftover files after failure: %v", entries)
	}
}

func TestConvertPreservesDestinationOnWriteFailure(t *testing.T) {
	dir := t.TempDir()
	hexPath := filepath.Join(dir, "in.hex")
	svPath := filepath.Join(dir, "boot.sv")
	old := "previous generated content\n"
	if err := os.WriteFile(svPath, []byte(old), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(hexPath, []byte(rec(t, 0x0200, 0xEA)+"\n"+eofRecord+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	// make the destination directory unwritable so temp creation fails
	if err := os.Chmod(dir, 0o500); err != nil {
		t.Fatal(err)
	}
	defer os.Chmod(dir, 0o700) //nolint:errcheck
	if err := convert(hexPath, svPath, ""); err == nil {
		t.Fatal("convert into unwritable directory succeeded, want failure")
	}
	got, err := os.ReadFile(svPath)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != old {
		t.Errorf("destination modified on write failure:\ngot:  %q\nwant: %q", got, old)
	}
}

func TestConvertOverwriteKeepsMode(t *testing.T) {
	dir := t.TempDir()
	hexPath := filepath.Join(dir, "in.hex")
	svPath := filepath.Join(dir, "boot.sv")
	if err := os.WriteFile(svPath, []byte("old\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(hexPath, []byte(rec(t, 0x0200, 0xEA)+"\n"+eofRecord+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := convert(hexPath, svPath, ""); err != nil {
		t.Fatalf("convert: %v", err)
	}
	fi, err := os.Stat(svPath)
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode().Perm() != 0o600 {
		t.Errorf("overwritten file mode = %v, want preserved 0600", fi.Mode().Perm())
	}
}
