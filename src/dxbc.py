import struct
from io import BytesIO


def llvm_from_stat(chunk: bytes):
    """
    Extracts LLVM bitcode from STAT chunk.
    """
    with BytesIO(chunk) as f:
        # ProgramHeader
        version = struct.unpack("B", f.read(1))[0]
        unused = struct.unpack("B", f.read(1))[0]
        shader_kind = struct.unpack("H", f.read(2))[0]
        size = struct.unpack("L", f.read(4))[0]

        # BitcodeHeader
        magic = f.read(4).decode()  # DXIL
        version_minor_major = struct.unpack("BB", f.read(2))
        unused = struct.unpack("H", f.read(2))[0]
        llvm_offset = struct.unpack("L", f.read(4))[0]
        llvm_size = struct.unpack("L", f.read(4))[0]
        llvm = f.read()

        return llvm


def group_size_from_psv0(chunk: bytes):
    """
    Extracts compute group size from PSV0 chunk.
    """
    with BytesIO(chunk) as f:
        runtime_info_size = struct.unpack("L", f.read(4))[0]
        irrelevant_data = f.read(36)
        group_size: tuple[int, int, int] = struct.unpack("LLL", f.read(4 * 3))

        return group_size


def parse_dxbc(shader: bytes):
    """
    Extracts compute group size and STAT LLVM from DXBC shader binary.
    """
    stat_contents: bytes = b""
    psv0_contents: bytes = b""

    with BytesIO(shader) as f:
        dxbc_string = f.read(4).decode()
        digest = f.read(16)
        version_major_minor = struct.unpack("HH", f.read(4))
        file_size = struct.unpack("L", f.read(4))[0]
        part_count = struct.unpack("L", f.read(4))[0]

        for _ in range(part_count):
            offset = struct.unpack("L", f.read(4))[0]

        for _ in range(part_count):
            name = f.read(4).decode()
            size = struct.unpack("L", f.read(4))[0]

            contents = f.read(size)
            if name == "STAT":
                stat_contents = contents
            elif name == "PSV0":
                psv0_contents = contents

    return group_size_from_psv0(psv0_contents), llvm_from_stat(stat_contents)
