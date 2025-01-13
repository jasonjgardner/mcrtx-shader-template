from enum import Enum
import re


class RegisterType(Enum):
    SRV = "t"  # ShaderResourceView
    Sampler = "s"  # SamplerState
    UAV = "u"  # UnorderedAccessView
    CBV = "b"  # ConstantBufferView

    @classmethod
    def from_resource_position(cls, pos: int):
        return RegisterType("tubs"[pos])


class Register:
    register: int
    space: int
    type: RegisterType = RegisterType.SRV

    def __init__(
        self,
        register: int = 0,
        type: RegisterType = RegisterType.SRV,
        space: int = 0,
    ) -> None:
        self.register = register
        self.type = type
        self.space = space

    def __str__(self) -> str:
        if self.space != 0:
            return f"register({self.type.value}{self.register}, space{self.space})"
        else:
            return f"register({self.type.value}{self.register})"

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, Register):
            return False
        return vars(self) == vars(value)


class Sampler:
    name: str
    register: Register

    def __init__(self, name: str, register: Register | tuple[int, int]) -> None:
        self.name = name
        self.register = (
            Register(register[0], RegisterType.Sampler, register[1])
            if isinstance(register, tuple)
            else register
        )

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, Sampler):
            return False
        return vars(self) == vars(value)

    def __str__(self) -> str:
        return f"SamplerState {self.name} : {self.register};"


class BufferSRV:
    name: str
    register: Register
    type_prefix: str
    is_array: bool
    el_count: int

    def __init__(
        self,
        name: str,
        register: Register | tuple[int, int],
        type_prefix: str,
        el_count: int = None,
    ) -> None:
        self.name = name
        self.register = (
            Register(register[0], RegisterType.SRV, register[1])
            if isinstance(register, tuple)
            else register
        )
        self.type_prefix = type_prefix
        self.is_array = el_count is not None
        self.el_count = el_count if el_count is not None else 1

    def __str__(self) -> str:
        if self.is_array:
            return f"{self.type_prefix} {self.name}[{self.el_count}] : {self.register};"
        else:
            return f"{self.type_prefix} {self.name} : {self.register};"

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, BufferSRV):
            return False
        return vars(self) == vars(value)

    def simplify_prefix(self):
        self.type_prefix = re.sub(r"unsigned\s*(\w+)", r"u\1", self.type_prefix)
        self.type_prefix = re.sub(
            r"\s*vector<(\w+),\s*(\d+)>\s*", r"\1\2", self.type_prefix
        )
        self.type_prefix = re.sub(
            r"\s*matrix<(\w+),\s*(\d+),\s*(\d+)>\s*", r"\1\2x\3", self.type_prefix
        )


class BufferUAV:
    name: str
    register: Register
    type_prefix: str
    is_array: bool
    el_count: int

    def __init__(
        self,
        name: str,
        register: Register | tuple[int, int],
        type_prefix: str,
        el_count: int = None,
    ) -> None:
        self.name = name
        self.register = (
            Register(register[0], RegisterType.UAV, register[1])
            if isinstance(register, tuple)
            else register
        )
        self.type_prefix = type_prefix
        self.is_array = el_count is not None
        self.el_count = el_count if el_count is not None else 1

    def __str__(self) -> str:
        if self.is_array:
            return f"{self.type_prefix} {self.name}[{self.el_count}] : {self.register};"
        else:
            return f"{self.type_prefix} {self.name} : {self.register};"

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, BufferUAV):
            return False
        return vars(self) == vars(value)

    def simplify_prefix(self):
        self.type_prefix = re.sub(r"unsigned\s*(\w+)", r"u\1", self.type_prefix)
        self.type_prefix = re.sub(
            r"\s*vector<(\w+),\s*(\d+)>\s*", r"\1\2", self.type_prefix
        )
        self.type_prefix = re.sub(
            r"\s*matrix<(\w+),\s*(\d+),\s*(\d+)>\s*", r"\1\2x\3", self.type_prefix
        )


class ShaderStructElement:
    name: str
    type_prefix: str
    offset: int
    is_array: bool
    array_size: int | tuple[int]

    def __init__(
        self,
        name: str = "",
        type_prefix: str = "",
        offset: int = 0,
        array_size: int | tuple[int] = None,
    ) -> None:
        self.name = name
        self.type_prefix = type_prefix
        self.offset = offset
        self.is_array = array_size is not None
        self.array_size = 1 if array_size is None else array_size

    def __str__(self) -> str:
        if self.is_array:
            return (
                f"{self.type_prefix} {self.name}"
                + ("".join(f"[{x}]" for x in self.array_size))
                + f"; // {self.offset}"
            )
        else:
            return f"{self.type_prefix} {self.name}; // {self.offset}"

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, ShaderStructElement):
            return False
        return vars(self) == vars(value)


class ShaderStruct:
    name: str
    elements: list[ShaderStructElement]

    def __init__(
        self, name: str = "", elements: list[ShaderStructElement] = None
    ) -> None:
        self.name = name
        self.elements = [] if elements is None else elements

    def __str__(self) -> str:
        return (
            f"struct {self.name} {{\n"
            + "".join(f"    {str(x)}\n" for x in self.elements)
            + "};"
        )

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, ShaderStruct):
            return False
        return vars(self) == vars(value)


class BufferCBV:
    name: str
    elements: list[ShaderStructElement]
    register: Register

    def __init__(
        self,
        name: str = "",
        register: Register | tuple[int, int] = None,
        elements: list[ShaderStructElement] = None,
    ) -> None:
        self.name = name
        self.elements = [] if elements is None else elements
        if register is not None:
            self.register = (
                Register(register[0], RegisterType.CBV, register[1])
                if isinstance(register, tuple)
                else register
            )

    def __eq__(self, value: object) -> bool:
        if not isinstance(value, BufferCBV):
            return False
        return vars(self) == vars(value)

    def __str__(self) -> str:
        return (
            f"cbuffer {self.name} : {self.register} {{\n"
            + "".join(f"    {str(x)}\n" for x in self.elements)
            + "};"
        )
