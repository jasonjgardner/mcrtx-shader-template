import os
import sys
import shutil
import re

from lazurite.material import Material
from lazurite.material.platform import ShaderPlatform
from lazurite.material.stage import ShaderStage
from lazurite.util import generate_pass_name_macro

from dxbc import parse_dxbc
from llvm import parse_llvm
from resources import BufferCBV, BufferSRV, BufferUAV, Sampler, ShaderStruct

RTX_STUB = "RTXStub.material.bin"
POSTFX_MATERIALS = [
    "RTXPostFX.Bloom.material.bin",
    "RTXPostFX.Tonemapping.material.bin",
]

ROOT_FOLDER = os.path.join(os.path.dirname(sys.argv[0]), "../")

BIN_PATH = os.path.join(ROOT_FOLDER, "vanilla/")
TEMPLATE_FOLDER = os.path.join(ROOT_FOLDER, "template/")
OUTPUT_FOLDER = os.path.join(ROOT_FOLDER, "project/")


# TODO: handle disabled reflection data
# TODO: handle anon structs


def process_text_file(text: str, token_mapping: dict[str, str]):
    """
    Replaces all template tokens with their respective data.
    """
    new_text = ""
    last_pos = 0
    for match in re.finditer(r"{\s*{\s*([\w.]+)\s*}\s*}", text):
        token_key = match.group(1)
        if token_key not in token_mapping:
            continue

        new_text += text[last_pos : match.start()]
        new_text += token_mapping[token_key]
        last_pos = match.end()

    new_text += text[last_pos:]
    return new_text


def analyze_rtxstub(mat: Material, template_token_mapping: dict[str, str]):
    """
    Extracts useful data from RTXStub and populates `template_token_mapping` based on gathered data.
    """
    print(f"Analyzing {mat.name}...")

    resources: dict = {}
    group_size_mapping: dict[str, tuple[int, int, int]] = {}

    for shader_pass in mat.passes:
        print(shader_pass.name)
        for variant in shader_pass.variants:
            for shader in variant.shaders:
                if not (
                    shader.platform is ShaderPlatform.Direct3D_SM65
                    and shader.stage is ShaderStage.Compute
                ):
                    continue

                group_size, llvm = parse_dxbc(shader.bgfx_shader.shader_bytes)
                parse_llvm(llvm, resources)
                group_size_mapping[shader_pass.name] = group_size

    # Convert RTXStub resources and group size to string mappings

    samplers: list[Sampler] = []
    structs: list[ShaderStruct] = []
    cbv_buffers: list[BufferCBV] = []
    uav_buffers: list[BufferUAV] = []
    srv_buffers: list[BufferSRV] = []

    for value in resources.values():
        if isinstance(value, Sampler):
            samplers.append(value)
        elif isinstance(value, ShaderStruct):
            structs.append(value)
        elif isinstance(value, BufferCBV):
            cbv_buffers.append(value)
        elif isinstance(value, BufferUAV):
            uav_buffers.append(value)
        elif isinstance(value, BufferSRV):
            srv_buffers.append(value)
        else:
            print("???")

    for resource_list in (samplers, structs, cbv_buffers, uav_buffers, srv_buffers):
        resource_list.sort(key=lambda x: x.name)

    for resource_list, token_name in (
        (samplers, "samplers"),
        (structs, "structs"),
        (cbv_buffers, "CBV"),
        (uav_buffers, "UAV"),
        (srv_buffers, "SRV"),
    ):
        template_token_mapping[f"{mat.name}.{token_name}"] = "\n".join(
            str(x) for x in resource_list
        )

    for buffer_list, register_prefix in (
        (samplers, "s"),
        (cbv_buffers, "b"),
        (uav_buffers, "u"),
        (srv_buffers, "t"),
    ):
        for buffer in buffer_list:
            key = f"{mat.name}.buffers.{register_prefix}{buffer.register.register}_space{buffer.register.space}"
            val = template_token_mapping.get(key, "")
            val += str(buffer)
            template_token_mapping[key] = val

    for shader_pass, (x, y, z) in group_size_mapping.items():
        template_token_mapping[f"{mat.name}.passes.{shader_pass}.group_size"] = (
            f"{x}, {y}, {z}"
        )

    template_token_mapping[f"{mat.name}.passes_and_group_size"] = "\n".join(
        f"{name} {size}" for name, size in sorted(group_size_mapping.items())
    )


def analyze_postfx_materials(
    mats: list[Material], template_token_mapping: dict[str, str]
):
    """
    Extracts useful data from PostFX materials and populates `template_token_mapping` based on gathered data.
    """
    for mat in mats:
        name = mat.name

        uniforms = sorted(mat.uniforms, key=lambda u: u.name)
        template_token_mapping[f"{name}.uniforms"] = "\n".join(
            f"uniform {u.type.name} {u.name}{f'[{u.count}]' if u.count > 1 else ''};"
            for u in uniforms
        )

        buffers = sorted(mat.buffers, key=lambda b: b.name)

        # TODO: add support for different buffer types, other than Texture2D
        template_token_mapping[f"{name}.buffers"] = "\n".join(
            f"SAMPLER2D_AUTOREG(s_{b.name});" for b in buffers
        )

        template_token_mapping[f"{name}.passes"] = "\n".join(
            sorted(generate_pass_name_macro(p.name) for p in mat.passes)
        )


def main():
    template_token_mapping: dict[str, str] = {}

    rtx_stub = Material.load_bin_file(os.path.join(BIN_PATH, RTX_STUB))
    analyze_rtxstub(rtx_stub, template_token_mapping)

    postfx_materials = [
        Material.load_bin_file(os.path.join(BIN_PATH, m)) for m in POSTFX_MATERIALS
    ]
    analyze_postfx_materials(postfx_materials, template_token_mapping)

    template_token_mapping["metadata.keys"] = "\n".join(
        sorted(template_token_mapping.keys())
    )

    # Generate project from template.
    for root, _, files in os.walk(TEMPLATE_FOLDER):
        folder_path = os.path.relpath(
            root,
            TEMPLATE_FOLDER,
        )
        input_path = os.path.normpath(os.path.join(TEMPLATE_FOLDER, folder_path))
        output_path = os.path.normpath(os.path.join(OUTPUT_FOLDER, folder_path))

        os.makedirs(output_path, exist_ok=True)

        for file in files:
            file_path = os.path.join(input_path, file)
            try:
                with open(file_path, "rt") as f:
                    text = f.read()
            except UnicodeDecodeError:
                # Just copy file directly, if it's not a text file.
                shutil.copy(file_path, output_path)
            else:
                with open(os.path.join(output_path, file), "w") as f:
                    text = process_text_file(text, template_token_mapping)
                    f.write(text)


if __name__ == "__main__":
    main()
