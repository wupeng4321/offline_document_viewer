"""Generates the legacy binary fixtures: a BIFF8 `.xls` and a PowerPoint 97 `.ppt`.

Neither format can be produced by anything on a stock macOS, and the package
must not ship documents it does not own. So both are written here from the
specifications, using a small OLE compound file writer.

Run from the package root:

    python3 tool/build_legacy_fixtures.py
"""
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SECTOR = 512
FREE = 0xFFFFFFFF
END_OF_CHAIN = 0xFFFFFFFE
FAT_SECTOR = 0xFFFFFFFD


# ── OLE compound file writer ───────────────────────────────────────────────

def build_cfb(streams: dict[str, bytes]) -> bytes:
    """Wraps named streams in a compound file.

    Streams are padded past the 4096-byte mini-stream cutoff so everything
    lives in the regular FAT; that removes the need for a mini-FAT entirely.

    The padded length is also what the directory reports as the stream size.
    Declaring the original, smaller length would put the stream back under the
    cutoff and every reader would look for it in a mini-FAT that does not
    exist — the stream is found but reads as empty. Trailing zeros are
    harmless: both BIFF and the PowerPoint record stream stop at their own
    terminator.
    """
    padded = {
        name: data + b"\x00" * max(0, 4096 - len(data))
        for name, data in streams.items()
    }

    # Sector 0 holds the FAT, sector 1 the directory, streams follow.
    layout: list[tuple[str, int, int]] = []  # name, first sector, sector count
    next_sector = 2
    for name, data in padded.items():
        count = (len(data) + SECTOR - 1) // SECTOR
        layout.append((name, next_sector, count))
        next_sector += count

    total_sectors = next_sector

    fat = [FREE] * (SECTOR // 4)
    fat[0] = FAT_SECTOR
    fat[1] = END_OF_CHAIN  # directory is a single sector
    for _, first, count in layout:
        for i in range(count):
            sector = first + i
            fat[sector] = END_OF_CHAIN if i == count - 1 else sector + 1

    def directory_entry(
        name: str, entry_type: int, start: int, size: int, child: int = FREE
    ) -> bytes:
        encoded = name.encode("utf-16-le") + b"\x00\x00"
        entry = bytearray(128)
        entry[0 : len(encoded)] = encoded
        struct.pack_into("<H", entry, 0x40, len(encoded))
        entry[0x42] = entry_type
        entry[0x43] = 1  # black
        struct.pack_into("<III", entry, 0x44, FREE, FREE, child)
        struct.pack_into("<I", entry, 0x74, start)
        struct.pack_into("<Q", entry, 0x78, size)
        return bytes(entry)

    directory = bytearray()
    # The root's child points at the first stream; siblings are left unset,
    # which readers tolerate for a handful of entries.
    directory += directory_entry("Root Entry", 5, END_OF_CHAIN, 0, child=1)
    for name, first, _ in layout:
        directory += directory_entry(name, 2, first, len(padded[name]))
    directory += b"\x00" * (SECTOR - len(directory) % SECTOR) if len(
        directory
    ) % SECTOR else b""

    header = bytearray(SECTOR)
    header[0:8] = bytes([0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1])
    struct.pack_into("<H", header, 0x18, 0x003E)  # minor version
    struct.pack_into("<H", header, 0x1A, 0x0003)  # major version 3
    struct.pack_into("<H", header, 0x1C, 0xFFFE)  # little endian
    struct.pack_into("<H", header, 0x1E, 9)       # 512-byte sectors
    struct.pack_into("<H", header, 0x20, 6)       # 64-byte mini sectors
    struct.pack_into("<I", header, 0x2C, 1)       # one FAT sector
    struct.pack_into("<I", header, 0x30, 1)       # directory sector
    struct.pack_into("<I", header, 0x38, 4096)    # mini stream cutoff
    struct.pack_into("<I", header, 0x3C, END_OF_CHAIN)  # no mini FAT
    struct.pack_into("<I", header, 0x40, 0)
    struct.pack_into("<I", header, 0x44, END_OF_CHAIN)  # no extra DIFAT
    struct.pack_into("<I", header, 0x48, 0)
    struct.pack_into("<I", header, 0x4C, 0)       # FAT lives in sector 0
    for i in range(1, 109):
        struct.pack_into("<I", header, 0x4C + i * 4, FREE)

    out = bytearray(header)
    out += struct.pack("<%dI" % len(fat), *fat)
    out += directory.ljust(SECTOR, b"\x00")
    for name, _, _ in layout:
        out += padded[name]

    # Every sector must be whole.
    if len(out) % SECTOR:
        out += b"\x00" * (SECTOR - len(out) % SECTOR)
    assert len(out) == SECTOR * (1 + total_sectors), (
        len(out),
        SECTOR * (1 + total_sectors),
    )
    return bytes(out)


# ── BIFF8 spreadsheet ──────────────────────────────────────────────────────

def record(code: int, payload: bytes) -> bytes:
    return struct.pack("<HH", code, len(payload)) + payload


def biff_string(text: str) -> bytes:
    """A BIFF8 unicode string: length, flags, then 8-bit or 16-bit characters."""
    if all(ord(c) < 256 for c in text):
        return struct.pack("<HB", len(text), 0x00) + text.encode("latin-1")
    return struct.pack("<HB", len(text), 0x01) + text.encode("utf-16-le")


def build_xls() -> bytes:
    rows = [
        ("Ürün", "Adet", "Birim Fiyat", "Toplam"),
        ("Kalem", 12, 45.0, 540.0),
        ("Defter", 3, 120.5, 361.5),
        ("Çanta", 7, 899.9, 6299.3),
        ("Silgi", 40, 7.25, 290.0),
    ]

    strings: list[str] = []

    def intern(value: str) -> int:
        if value not in strings:
            strings.append(value)
        return strings.index(value)

    # Build the sheet body first so the shared string table is complete.
    body = bytearray()
    body += record(0x0809, struct.pack("<HHHHHHHH", 0x0600, 0x0010, 0, 0, 0, 0, 0, 0))
    body += record(0x0200, struct.pack("<IIHHH", 0, len(rows), 0, 4, 0))  # DIMENSIONS
    for r, row in enumerate(rows):
        for c, value in enumerate(row):
            if isinstance(value, str):
                body += record(
                    0x00FD,  # LABELSST
                    struct.pack("<HHHI", r, c, 0, intern(value)),
                )
            else:
                body += record(
                    0x0203,  # NUMBER
                    struct.pack("<HHH", r, c, 0) + struct.pack("<d", float(value)),
                )
    body += record(0x000A, b"")  # EOF

    sst = bytearray(struct.pack("<II", len(strings), len(strings)))
    for text in strings:
        sst += biff_string(text)

    def globals_block(sheet_offset: int) -> bytes:
        out = bytearray()
        out += record(
            0x0809, struct.pack("<HHHHHHHH", 0x0600, 0x0005, 0, 0, 0, 0, 0, 0)
        )
        name = "Satislar"
        out += record(
            0x0085,  # BOUNDSHEET
            struct.pack("<IBB", sheet_offset, 0x00, 0x00)
            + struct.pack("<B", len(name))
            + b"\x00"
            + name.encode("latin-1"),
        )
        out += record(0x00FC, bytes(sst))  # SST
        out += record(0x000A, b"")
        return bytes(out)

    # BOUNDSHEET stores the absolute offset of the sheet's BOF, so the block is
    # built once to measure it and again with the real value.
    placeholder = globals_block(0)
    workbook = globals_block(len(placeholder)) + bytes(body)
    return build_cfb({"Workbook": workbook})


# ── PowerPoint 97 presentation ─────────────────────────────────────────────

def ppt_record(rec_type: int, payload: bytes, instance: int = 0, container: bool = False) -> bytes:
    version = 0x0F if container else 0x00
    version_instance = (instance << 4) | version
    return struct.pack("<HHI", version_instance, rec_type, len(payload)) + payload


def text_atom(text: str) -> bytes:
    # TextCharsAtom carries UTF-16, which is what non-Latin text needs.
    return ppt_record(0x0FA0, text.encode("utf-16-le"))


def build_ppt() -> bytes:
    slides = [
        ["Offline Document Viewer", "Legacy PowerPoint, shown as text"],
        [
            "Neden salt metin",
            "97-2003 icin acik kaynak yerlesim motoru yok",
            "Metin dogru, sayfa duzeni korunmuyor",
        ],
        ["Türkçe karakterler", "ğüşiöçİĞÜŞÖÇ"],
    ]

    body = bytearray()
    for lines in slides:
        slide_body = bytearray()
        for line in lines:
            slide_body += text_atom(line)
        body += ppt_record(0x03EE, bytes(slide_body), container=True)  # Slide

    # A master is included so the extractor's skip rule is exercised: its
    # placeholder text must not appear in the output.
    master = ppt_record(
        0x03F8,  # MainMaster
        text_atom("Click to edit Master title style"),
        container=True,
    )

    document = ppt_record(0x03E8, master + bytes(body), container=True)
    return build_cfb({"PowerPoint Document": document})


def main() -> None:
    targets = {
        "test/fixtures/sample.xls": build_xls(),
        "test/fixtures/sample.ppt": build_ppt(),
    }
    for relative, data in targets.items():
        path = ROOT / relative
        path.write_bytes(data)
        print(f"  {relative:32} {len(data):>8,} bytes")


if __name__ == "__main__":
    main()
