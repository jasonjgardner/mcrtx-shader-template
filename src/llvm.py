from bitstream import new_bit_stream, BitStream
from enum import Enum, auto
import json
from resources import (
    Sampler,
    Register,
    RegisterType,
    BufferSRV,
    BufferUAV,
    BufferCBV,
    ShaderStruct,
    ShaderStructElement,
)
from collections.abc import Callable
from typing import Any


class RecordFieldType(Enum):
    CONSTANT = auto()
    FIXED = auto()
    VBR = auto()
    ARRAY = auto()
    CHAR6 = auto()
    BLOB = auto()


class RecordValue:
    abbrev: int
    value: int | list | str | bytes


class DataType(Enum):
    VOID = 2
    HALF = 10
    BFLOAT = 23
    FLOAT = 3
    DOUBLE = 4
    LABEL = 5
    OPAQUE = 6
    INT = 7
    POINTER = 8
    FUNCTION_OLD = 9
    ARRAY = 11
    VECTOR = 12
    X86_FP80 = 13
    FP128 = 14
    PPC_FP128 = 15
    METADATA = 16
    X86_MMX = 17
    STRUCT_ANON = 18
    STRUCT_NAMED = 20
    FUNCTION = 21
    X86_AMX = 24
    TARGET_TYPE = 26


class MetadataValueType:
    name: str
    type: DataType
    data: list[int]

    def __init__(
        self, type: DataType = DataType.FLOAT, data: list[int] = None, name: str = ""
    ) -> None:
        self.type = type
        self.data = [] if data is None else data
        self.name = name

    def __str__(self) -> str:
        if self.name:
            return f"{self.type.name} {self.name} {self.data}"
        else:
            return f"{self.type.name} {self.data}"

    def hlsl_type(self):
        if self.type is DataType.FLOAT:
            return "float"
        elif self.type is DataType.STRUCT_NAMED:
            return self.name
        else:
            raise Exception(f"HLSL string is not implemented for {self.type.name}")


class NodeValue:
    value: int | str | None = None
    type: MetadataValueType

    def __init__(self, type: MetadataValueType, value: int | str | None = None) -> None:
        self.type = type
        self.value = value

    def serialize(self):
        return self.value


class LLVMBitcode:
    _stream: BitStream = None
    _abbrev_table: dict[int, list[list["LLVMBitcode.RecordField"]]]
    _debug_print: bool = False

    class RecordField:
        width: int
        type: RecordFieldType
        array_el: "LLVMBitcode.RecordField"
        value: int

        _llvm_bitcode_instance: "LLVMBitcode"

        @classmethod
        def create_definition(cls):
            stream = cls._llvm_bitcode_instance._stream
            obj = cls()
            is_constant = stream.read(1) == 1

            if is_constant:
                obj.type = RecordFieldType.CONSTANT
                obj.value = stream.read_vbr(8)
            else:
                encoding = stream.read(3)
                if encoding == 1:
                    obj.type = RecordFieldType.FIXED
                    obj.width = stream.read_vbr(5)
                elif encoding == 2:
                    obj.type = RecordFieldType.VBR
                    obj.width = stream.read_vbr(5)
                elif encoding == 3:
                    obj.type = RecordFieldType.ARRAY
                elif encoding == 4:
                    obj.type = RecordFieldType.CHAR6
                elif encoding == 5:
                    obj.type = RecordFieldType.BLOB
                else:
                    raise Exception(f"Invalid custom record field encoding {encoding}")

            return obj

        def read(self):
            stream = self._llvm_bitcode_instance._stream

            if self.type == RecordFieldType.CONSTANT:
                return self.value
            elif self.type == RecordFieldType.FIXED:
                return stream.read(self.width)
            elif self.type == RecordFieldType.VBR:
                return stream.read_vbr(self.width)
            elif self.type == RecordFieldType.ARRAY:
                data = [self.array_el.read() for _ in range(stream.read_vbr(6))]
                if self.array_el.type == RecordFieldType.CHAR6:
                    data = "".join(data)
                return data
            elif self.type == RecordFieldType.CHAR6:
                return stream.read_char6()
            elif self.type == RecordFieldType.BLOB:
                count = stream.read_vbr(6)
                stream.align()
                data = bytes(stream.read(8) for _ in range(count))
                stream.align()
                return data

    class SubBlock:
        id: int
        abbrev_length: int
        length: int
        items: list

        _llvm_bitcode_instance: "LLVMBitcode"

        @classmethod
        def read(cls):
            llvm = cls._llvm_bitcode_instance
            stream = llvm._stream

            obj = cls()
            obj.id = stream.read_vbr(8)
            obj.abbrev_length = stream.read_vbr(4)
            stream.align()
            obj.length = stream.read(32)
            llvm.debug_print(
                f"Sub-Block: id={obj.id}, abbrev_len={obj.abbrev_length}, len={obj.length}"
            )
            obj.items = llvm.read_block_items(obj.abbrev_length, obj.id)
            return obj

    class UnabbreviatedRecord:
        code: int
        values: list[int]

        _llvm_bitcode_instance: "LLVMBitcode"

        @classmethod
        def read(cls):
            stream = cls._llvm_bitcode_instance._stream
            obj = cls()
            obj.code = stream.read_vbr(6)
            obj.values = [stream.read_vbr(6) for _ in range(stream.read_vbr(6))]
            return obj

    def __init__(self) -> None:
        self.RecordField._llvm_bitcode_instance = self
        self.SubBlock._llvm_bitcode_instance = self
        self.UnabbreviatedRecord._llvm_bitcode_instance = self
        self._abbrev_table = {}

    def read(self, bitcode: bytes):
        self._abbrev_table = {}
        with new_bit_stream(bitcode) as f:
            self._stream = f
            magic = f.read(8 * 4)
            return self.read_block_items()

    def create_abbreviation(self):
        record_fields = [
            self.RecordField.create_definition()
            for _ in range(self._stream.read_vbr(5))
        ]

        # Handle special case of arrays
        new_record_fields: list[LLVMBitcode.RecordField] = []
        for i, field in enumerate(record_fields):
            if i > 0 and record_fields[i - 1].type == RecordFieldType.ARRAY:
                continue
            if field.type == RecordFieldType.ARRAY:
                field.array_el = record_fields[i + 1]
            new_record_fields.append(field)

        return new_record_fields

    def read_end_block(self):
        self._stream.align()

    def read_block_items(self, abbrev_width: int = 2, block_id: int = None):
        items: list[
            LLVMBitcode.SubBlock | RecordValue | LLVMBitcode.UnabbreviatedRecord
        ] = []
        edited_block_id = block_id
        while True:
            if self._stream.tell() == self._stream.get_bit_count():
                break

            abbrev = self._stream.read(abbrev_width)
            if abbrev == 0:  # END_BLOCK
                self.debug_print("END_BLOCK")
                self.read_end_block()
                break

            elif abbrev == 1:  # ENTER_SUBBLOCK
                items.append(self.SubBlock.read())

            elif abbrev == 2:  # DEFINE_ABBREV
                custom_abbrev = self.create_abbreviation()
                if block_id == 0:  # BLOCKINFO
                    self.debug_print(
                        f"DEFINE_ABBREV (BLOCKINFO) {[x.type for x in custom_abbrev]}"
                    )
                    if edited_block_id not in self._abbrev_table:
                        self._abbrev_table[edited_block_id] = []

                    self._abbrev_table[edited_block_id].append(custom_abbrev)
                else:
                    self.debug_print(f"DEFINE_ABBREV {[x.type for x in custom_abbrev]}")
                    if block_id not in self._abbrev_table:
                        self._abbrev_table[block_id] = []

                    self._abbrev_table[block_id].append(custom_abbrev)

            elif abbrev == 3:  # UNABBREV_RECORD
                item = self.UnabbreviatedRecord.read()
                if block_id == 0:  # BLOCKINFO
                    if item.code == 1:  # SETBID
                        self.debug_print(
                            f"SETBID code={item.code}, id={item.values[0]}"
                        )
                        edited_block_id = item.values[0]
                    else:
                        raise Exception(f"Unsupported BLOCKINFO operation {item.code}")
                else:
                    self.debug_print(
                        f"UNABBREV_RECORD code={item.code}, values={item.values}"
                    )

                items.append(item)

            # Custom record
            elif block_id in self._abbrev_table and abbrev - 4 < len(
                self._abbrev_table[block_id]
            ):
                abbrev -= 4
                obj = RecordValue()
                obj.abbrev = abbrev
                obj.value = [x.read() for x in self._abbrev_table[block_id][abbrev]]
                self.debug_print(f"Custom Record: abbrev={abbrev}, values={obj.value}")
                items.append(obj)

            else:
                raise Exception(f"Unrecognized abbreviation {abbrev}")

        return items

    def debug_print(self, message):
        if self._debug_print:
            print(message)


def find_blocks_by_id(block_list: list[LLVMBitcode.SubBlock], id: int):
    matching_items: list[LLVMBitcode.SubBlock] = []
    for b in block_list:
        if isinstance(b, LLVMBitcode.SubBlock):
            if b.id == id:
                matching_items.append(b)
            matching_items += find_blocks_by_id(b.items, id)
    return matching_items


def get_metadata_value(item: LLVMBitcode.UnabbreviatedRecord | RecordValue):
    if isinstance(item, RecordValue) and len(item.value) > 0:
        op_type = item.value[0]
        data = item.value[1:]
    elif isinstance(item, LLVMBitcode.UnabbreviatedRecord):
        op_type = item.code
        data = item.values
    return op_type, data


def traverse_node_tree(
    items: list[LLVMBitcode.UnabbreviatedRecord | RecordValue],
    nodes: list[int],
    types: list,
    constants: list[tuple[int, int]],
):
    values = []
    for node in nodes:
        if node == 0:
            values.append(None)
            continue
        item = items[node - 1]
        op_type, data = get_metadata_value(item)
        if op_type == 3:  # node
            values.append(traverse_node_tree(items, data, types, constants))
        elif op_type in (1, 4):  # name
            values.append("".join(chr(x) for x in data[0]))
        elif op_type == 2:  # value
            c_type, c_val = constants[data[1]]
            expected_type = data[0]
            if len(data) > 2:
                print("Too many values!")
            if c_type != -1 and c_type != expected_type:
                print(
                    f"Constant type mismatch, {expected_type} expected but got {c_type}"
                )
            values.append(NodeValue(types[expected_type], c_val))
        # elif op_type == 10:  # named node
        #     # print(node, node - 1, data)
        #     values.append({node: traverse_node_tree(items, data, types)})
        else:  # ???
            print("???", op_type, data)

    return values


def apply_names_recursive(obj, mapping: dict[int, str]):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(key, int):
                obj.pop(key)
                mapping[key]
                obj[mapping[key]] = value
            apply_names_recursive(value, mapping)
    elif isinstance(obj, list):
        for value in obj:
            apply_names_recursive(value, mapping)


def buid_type_table(type_blocks: list[LLVMBitcode.SubBlock]):
    struct_name = ""
    types: list[MetadataValueType] = []
    for b in type_blocks:
        for item in b.items:
            op_type, data = get_metadata_value(item)
            if op_type == 1:
                # Skip NUMENTRY field
                continue

            if op_type == 19:  # STRUCT_NAME
                if isinstance(item, LLVMBitcode.UnabbreviatedRecord):
                    data = ["".join(chr(x) for x in item.values)]
                struct_name = data[0]

            elif op_type in DataType:
                type = MetadataValueType(DataType(op_type), data)
                if op_type in map(
                    lambda x: x.value,
                    (DataType.OPAQUE, DataType.STRUCT_NAMED, DataType.TARGET_TYPE),
                ):
                    type.name = struct_name

                types.append(type)

    return types


def unpack_value(value: int | list, type: int, types: list[MetadataValueType]):
    type: MetadataValueType = types[type]

    if type.type is DataType.FLOAT:
        return BitStream.unpack_float(value)
    elif type.type is DataType.INT:
        return BitStream.unpack_vbr_signed(value)
    elif type.type is DataType.ARRAY:
        return [unpack_value(x, type.data[1], types) for x in value]
    else:
        raise Exception(f"Unrecognised value type {type}")


def build_constants_table(
    module_blocks: list[LLVMBitcode.SubBlock],
    constant_blocks: list[LLVMBitcode.SubBlock],
    types: list[MetadataValueType],
):
    const_counter = 0
    constants: list[tuple[int, int | str | None]] = []

    # Parse functions and global variables
    for b in module_blocks:
        for item in b.items:
            if not isinstance(item, (LLVMBitcode.UnabbreviatedRecord, RecordValue)):
                continue
            op_type, _ = get_metadata_value(item)
            if op_type == 8:  # FUNCTION
                constants.append((-1, f"Func_{const_counter}"))
                const_counter += 1
            elif op_type == 7:  # GLOBALVAR
                constants.append((-1, f"GlobalVar_{const_counter}"))
                const_counter += 1

    # Extract constants
    const_type: int = None
    for b in constant_blocks:
        for item in b.items:
            op_type, data = get_metadata_value(item)
            if op_type == 1:  # SETTYPE
                const_type = data[0]
            elif op_type == 2 and len(data) == 0:  # NULL
                constants.append((const_type, 0))
                const_counter += 1
            elif op_type == 4:  # INTEGER
                constants.append((const_type, unpack_value(data[0], const_type, types)))
                const_counter += 1
            elif op_type == 3:  # UNDEF
                constants.append((const_type, "undefined"))
                const_counter += 1
            elif op_type == 22:  # DATA (for array)
                constants.append((const_type, unpack_value(data, const_type, types)))
            else:
                raise Exception(f"Unrecognised operation type {op_type}")

    return constants


def extract_named_metadata(
    metadata_blocks: list[LLVMBitcode.SubBlock],
    types: list[MetadataValueType],
    constants: list[tuple[int, int | str | None]],
):
    """
    Extracts metadata
    """
    # Extract metadata
    metadata_obj = {}
    metadata_name_mapping: dict[int, str] = {}
    node_name = ""

    for b in metadata_blocks:
        for i, item in enumerate(b.items):
            op_type, data = get_metadata_value(item)
            if op_type == 6:
                # Skip second metadata block
                continue

            if op_type in (1, 4):  # NAME
                node_name = "".join(chr(x) for x in data[0])
                metadata_name_mapping[i + 2] = node_name

            # if op_type == 2:  # value
            #     print(types[data[0]], data[1])

            if op_type == 10:  # NAMED_NODE
                metadata_obj[node_name] = traverse_node_tree(
                    b.items, [x + 1 for x in data], types, constants
                )

    return metadata_obj


def serialize_metadata(obj, node_value_processor: Callable[[NodeValue], Any]):
    if isinstance(obj, list):
        return [serialize_metadata(i, node_value_processor) for i in obj]
    elif isinstance(obj, dict):
        return {
            serialize_metadata(k, node_value_processor): serialize_metadata(
                v, node_value_processor
            )
            for k, v in obj.items()
        }
    elif isinstance(obj, NodeValue):
        return node_value_processor(obj)
    else:
        return obj


def metadata_to_object(metadata):
    return serialize_metadata(metadata, lambda x: x.serialize())


def metadata_to_typed_object(metadata):
    return serialize_metadata(metadata, lambda x: {str(x.type): x.value})


def resolve_array_type(
    types: list[MetadataValueType], type_id: int
) -> tuple[tuple[int], int]:
    type = types[type_id]
    if type.type is DataType.ARRAY:
        size, value = resolve_array_type(types, type.data[1])
        size = (type.data[0],) + size
        return size, value
    else:
        return tuple(), type_id


def get_type_prefix(type_param: int):
    type_mapping = {
        1: "bool",
        2: "int16_t",
        3: "uint16_t",
        4: "int",
        5: "uint",
        6: "int64_t",
        7: "uint64",
        8: "half",
        9: "float",
        10: "double",
        # 11 ??
        # 12 ??
        13: "snorm float",
        14: "unorm float",
    }

    if type_param in type_mapping:
        return type_mapping[type_param]

    raise Exception(f"Unrecognised type {type_param}")


def add_unique_resource(key: str, resource, resource_registry: dict):
    old_resource = resource_registry.get(key, None)
    if key in resource_registry and resource != old_resource:
        print(
            f"Warning! New resource definition {resource} desn't match previous one {old_resource}"
        )
    elif key not in resource_registry:
        resource_registry[key] = resource


def parse_type_annotations(
    metadata: dict,
    types: list[MetadataValueType],
    resources: dict[str, Sampler | BufferSRV],
    cbv_structs: dict[str, ShaderStruct],
):
    """
    Extracts structs from metadata
    """
    if metadata["dx.typeAnnotations"][0] is None:
        return

    struct_definitions: list = metadata["dx.typeAnnotations"][0]
    for i, el in enumerate(struct_definitions):
        # Skip enumeration
        if not isinstance(el, list):
            continue

        # Previous field before the list of elements defines struct type.
        type: MetadataValueType = struct_definitions[i - 1].type
        if (
            type.type is not DataType.STRUCT_NAMED
            or not type.name.startswith("struct.")
            and "." in type.name
        ):
            # Named structs have a `struct.` previx while CBVs don't have anything
            continue

        struct = ShaderStruct(type.name.removeprefix("struct."))

        for field_id, field in enumerate(el):
            if not isinstance(field, list):
                continue
            if field[0].value != 6:
                raise Exception(f"Unknown field header {field[0].value} for {type}")

            field_type_id: int = type.data[1][field_id - 1]
            array_size, field_type_id = resolve_array_type(types, field_type_id)
            field_type = types[field_type_id]
            name = field[1]
            struct_field = ShaderStructElement(name)
            if array_size:
                struct_field.array_size = array_size
                struct_field.is_array = True
            parsing_type = field[2].value
            if parsing_type == 2:  # Matrix
                if field[3][2].value not in (1, 2):
                    raise Exception(f"Unrecognised matrix order {field[3][2].value}")
                is_row_major = field[3][2].value == 1
                struct_field.type_prefix = f"{get_type_prefix(field[7].value)}{field[3][0].value}x{field[3][1].value}"
                if is_row_major:
                    struct_field.type_prefix = "row_major " + struct_field.type_prefix
                offset = field[5].value
            elif parsing_type == 3:  # Normal value
                offset = field[3].value
                if field_type.type is DataType.STRUCT_NAMED:
                    struct_field.type_prefix = field_type.name.removeprefix("struct.")
                else:
                    struct_field.type_prefix = get_type_prefix(field[5].value)
                    if field_type.type is DataType.VECTOR:
                        struct_field.type_prefix += str(field_type.data[0])
            else:
                raise Exception(f"Unrecognised field parsing type {parsing_type}")

            struct_field.offset = offset
            struct.elements.append(struct_field)

        add_unique_resource(
            struct.name, struct, resources if "." in type.name else cbv_structs
        )


def parse_resources(
    metadata: dict,
    types: list[MetadataValueType],
    resources: dict[str, Sampler | BufferSRV],
    cbv_structs: dict[str, ShaderStruct],
):
    """
    Extracts buffers, textures and samplers from metadata.
    """
    srv_data = metadata["dx.resources"][0][0] or []
    uav_data = metadata["dx.resources"][0][1] or []
    cbv_data = metadata["dx.resources"][0][2] or []
    sampler_data = metadata["dx.resources"][0][3] or []

    # Extract SRVs
    for el in srv_data:
        type: MetadataValueType = types[el[1].type.data[0]]
        name: str = el[2]

        # is_array = type.type is DataType.ARRAY
        if type.type is DataType.ARRAY:
            type_name = (
                types[type.data[1]].name.removeprefix("struct.").removeprefix("class.")
            )
            buffer = BufferSRV(
                name,
                (el[4].value, el[3].value),
                type_name,
                type.data[0],
            )
        else:
            type_name = type.name.removeprefix("struct.").removeprefix("class.")
            buffer = BufferSRV(name, (el[4].value, el[3].value), type_name)

        buffer.simplify_prefix()
        add_unique_resource(name, buffer, resources)

    # Extract UAVs
    for el in uav_data:
        type: MetadataValueType = types[el[1].type.data[0]]
        name: str = el[2]

        # is_array = type.type is DataType.ARRAY
        if type.type is DataType.ARRAY:
            type_name = (
                types[type.data[1]].name.removeprefix("struct.").removeprefix("class.")
            )
            buffer = BufferUAV(
                name,
                (el[4].value, el[3].value),
                type_name,
                type.data[0],
            )
        else:
            type_name = type.name.removeprefix("struct.").removeprefix("class.")
            buffer = BufferUAV(
                name,
                Register(el[4].value, RegisterType.UAV, el[3].value),
                type_name,
            )

        buffer.simplify_prefix()
        add_unique_resource(name, buffer, resources)

    # Extract CBVs
    for el in cbv_data:
        type: MetadataValueType = types[el[1].type.data[0]]
        name: str = el[2]
        struct = cbv_structs[name]
        buffer = BufferCBV(name, (el[4].value, el[3].value), struct.elements)

        add_unique_resource(name, buffer, resources)

    # Extract samplers
    for el in sampler_data:
        sampler_name = el[2]
        sampler = Sampler(
            sampler_name, Register(el[4].value, RegisterType("s"), el[3].value)
        )
        add_unique_resource(sampler_name, sampler, resources)


def parse_llvm(
    binary: bytes,
    resources: dict[str, Sampler | BufferSRV | BufferUAV | BufferCBV | ShaderStruct],
):
    """
    Parses reflection LLVM bitcode and extracts discovered resources (buffers, structs, samplers).
    """

    llvm_bc = LLVMBitcode()
    llvm_data = llvm_bc.read(binary)

    type_blocks = find_blocks_by_id(llvm_data, 17)
    metadata_blocks = find_blocks_by_id(llvm_data, 15)
    module_blocks = find_blocks_by_id(llvm_data, 8)
    constant_blocks = find_blocks_by_id(llvm_data, 11)

    # Extract types
    types = buid_type_table(type_blocks)
    constants = build_constants_table(module_blocks, constant_blocks, types)
    metadata = extract_named_metadata(metadata_blocks, types, constants)

    cbv_structs: dict[str, ShaderStruct] = {}

    # print(json.dumps(metadata_to_typed_object(metadata)))
    # for i, t in enumerate(types):
    #     print(i, t.name, t.type.name, t.data)

    if "dx.typeAnnotations" in metadata:
        parse_type_annotations(metadata, types, resources, cbv_structs)

    if "dx.resources" in metadata:
        parse_resources(metadata, types, resources, cbv_structs)
