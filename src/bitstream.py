from io import BytesIO
from math import ceil
import contextlib
import struct


class BitStream:
    _file: BytesIO = None
    _file_length = 0
    _next_bit = 0
    _curr_byte = 0

    CHAR_MAPPING = (
        list(chr(x) for x in range(ord("a"), ord("z") + 1))
        + list(chr(x) for x in range(ord("A"), ord("Z") + 1))
        + list(str(x) for x in range(10))
        + [".", "_"]
    )

    def __init__(self, file: BytesIO, length: int = 0) -> None:
        self._file = file
        self._file_length = length

    @staticmethod
    def unpack_vbr_signed(value: int):
        is_negative = value & 1 == 1
        value = value >> 1
        return -value if is_negative else value

    @staticmethod
    def unpack_float(value: int):
        return struct.unpack(">f", value.to_bytes(4))[0]

    def read(self, num_bits: int = 0):
        value = 0
        shift = 0

        for _ in range(num_bits):
            if self._next_bit == 0:
                if self._file.tell() == self._file_length:
                    raise Exception("Reached the end of the stream!")
                self._curr_byte = int.from_bytes(self._file.read(1))

            bit = (self._curr_byte >> self._next_bit) & 1

            self._next_bit = (self._next_bit + 1) % 8

            value |= bit << shift
            shift += 1

        return value

    def read_vbr(self, size: int = 0):
        value = 0
        offset = 0
        keeep_going = True
        while keeep_going:
            value |= self.read(size - 1) << offset * (size - 1)
            keeep_going = self.read(1) == 1
            offset += 1

        return value

    def read_char6(self, count: int = 1):
        text = ""
        for _ in range(count):
            text += self.CHAR_MAPPING[self.read(6)]
        return text

    def tell(self):
        next_byte = self._file.tell()
        next_bit = self._next_bit
        return next_byte * 8 if next_bit == 0 else (next_byte - 1) * 8 + next_bit

    def align(self, width: int = 32):
        next_bit = self.tell()

        self.read(ceil(next_bit / width) * width - next_bit)

    def get_bit_count(self):
        return self._file_length * 8


@contextlib.contextmanager
def new_bit_stream(data: bytes):
    byte_stream = BytesIO(data)
    stream = BitStream(byte_stream, len(data))
    try:
        yield stream
    finally:
        byte_stream.close()
