from enum import Enum, auto


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

def analyze_types()